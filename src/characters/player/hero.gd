@tool
class_name Hero
extends CharacterBody3D
## Playable character.
##
## Swaps mesh and animations from hero_data, delegates movement to a
## StateMachine, and exposes camera_yaw so the camera can orbit without
## depending on the rotation of the body itself.


## How fast the model turns to a new direction.
const MESH_TURN_SPEED: float = 12.0

## Where a shot leaves from when the hero has nothing in their hand.
const DEFAULT_MUZZLE_HEIGHT: float = 1.4

## Skeleton bone the main hand weapon is attached to.
const MAIN_HAND_BONE: String = "handslot.r"
## Skeleton bone the off hand weapon or shield is attached to.
const OFF_HAND_BONE: String = "handslot.l"

## meshes for each playable class, in the same order as hero_id
const MESHES: Array[String] = [
	"res://characters/heroes/barbarian/mesh.tscn",
	"res://characters/heroes/knight/mesh.tscn",
	"res://characters/heroes/mage/mesh.tscn",
	"res://characters/heroes/ranger/mesh.tscn",
	"res://characters/heroes/rogue_hooded/mesh.tscn"
]

## Reference to the active Hero, so any script can reach it via Hero.player.
static var player: Hero = null

## Class resource with this hero's attributes, changing it swaps the mesh.
@export var hero_data: HeroClassData = null: set = _set_hero_data
## State the StateMachine starts on, usually IdleState.
@export var initial_state: State = null
## Current and max health, filled from hero_data's max_health.
@export var health_pool: StatPool = StatPool.new()
## How fast the camera turns with mouse movement.
@export var mouse_sensitivity: float = 0.003
## Editor helper: tick this to re-attach the weapons after editing their grip values.
@export var refresh_equipment: bool = false: set = _refresh_equipment

var skeleton: Skeleton3D = null

var equipped_weapon: WeaponData = null
var off_hand_item: WeaponData = null
var is_blocking: bool = false

var main_hand_slot: BoneAttachment3D = null

var mesh_facing: float = 0.0
var camera_yaw: float = 0.0

var _is_stagger_pending: bool = false

@onready var base: Node3D = $Rig_Medium
@onready var animation_player: AnimationPlayer = $Rig_Medium/AnimationPlayer
@onready var camera_pivot: PlayerCamera = $PlayerCamera
@onready var damage_flash: DamageFlash = $DamageFlash
@onready var hud: HUD = $Hud

#region States
@onready var state_machine: StateMachine = $StateMachine
@onready var idle_state: State = $StateMachine/IdleState
@onready var walk_state: State = $StateMachine/WalkState
@onready var attack_state: State = $StateMachine/AttackState
@onready var aim_state: State = $StateMachine/AimState
@onready var block_state: State = $StateMachine/BlockState
@onready var jump_state: State = $StateMachine/JumpState
@onready var hurt_state: State = $StateMachine/HurtState
@onready var death_state: State = $StateMachine/DeathState
#endregion


## Runs once on entering the scene: loads the class's mesh and sets up the states.
func _ready() -> void:
	skeleton = base.get_node_or_null("Skeleton3D")
	_set_hero_data(hero_data)

	if Engine.is_editor_hint(): return

	player = self

	state_machine.init(self, initial_state)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	health_pool.value_changed.connect(_on_health_changed)
	hud.set_health(health_pool.get_value(), health_pool.get_max_value())


func _on_health_changed(_old_value: int, new_value: int, increased: bool) -> void:
	hud.set_health(new_value, health_pool.get_max_value())

	# Blinks even on a blocked hit: the guard removes the stagger, not the damage.
	if not increased:
		damage_flash.flash()


## Clears the shared reference on the way out, so nothing holds a freed hero.
func _exit_tree() -> void:
	if player == self:
		player = null


## Runs every physics frame: lets the StateMachine decide the movement.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return

	state_machine.physics_update()


## Reads the mouse: Esc releases/recaptures it, and its movement turns the camera.
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return

	# A dead hero reads nothing, or a click would recapture the mouse mid transition.
	if is_dead(): return

	# Esc releases the mouse (handy for debugging); clicking the window recaptures it.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	# Checked before the click below, so the wheel zooms instead of recapturing.
	if event.is_action_pressed("camera_zoom_in"):
		camera_pivot.apply_zoom(1.0)
		return

	if event.is_action_pressed("camera_zoom_out"):
		camera_pivot.apply_zoom(-1.0)
		return

	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw stays on the camera, so it orbits without rotating the hero.
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.y = camera_yaw
		camera_pivot.apply_pitch(-event.relative.y * mouse_sensitivity)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: health_pool.increase(10)
			KEY_2: take_damage(10.0, global_position + get_facing_direction() * 2.0)


## Called when the class changes, swapping the mesh and the gear it carries.
func _set_hero_data(value: HeroClassData) -> void:
	hero_data = value

	if not is_node_ready(): return

	health_pool.set_max_value(int(value.max_health))
	health_pool.increase(int(value.max_health))  

	var mesh_scene: PackedScene = load(MESHES[hero_data.id])
	var mesh: Skeleton3D = mesh_scene.instantiate()

	# Old one goes first, or Godot renames one and the animation loses the bones.
	if skeleton:
		base.remove_child(skeleton)
		skeleton.queue_free()

	mesh.name = "Skeleton3D"
	# Set up while the mesh is still detached: see the note on DamageFlash.setup.
	damage_flash.setup(mesh)

	base.add_child(mesh)
	skeleton = mesh

	_equip_starting_weapons()


## Re-attaches the weapons, so grip tweaks show up without running the game.
func _refresh_equipment(_value: bool) -> void:
	# Stays false so the checkbox works like a button instead of a setting.
	refresh_equipment = false

	if not is_node_ready() or not hero_data: return

	_equip_starting_weapons()


## Spawns the class's starting gear on the skeleton's hand bones.
func _equip_starting_weapons() -> void:
	# Drops the old models first, otherwise re-equipping stacks copies.
	for child: Node in skeleton.get_children():
		if child is BoneAttachment3D:
			child.free()

	equipped_weapon = null
	off_hand_item = null
	main_hand_slot = null

	if hero_data.starting_weapons.is_empty(): return

	var primary: WeaponData = hero_data.starting_weapons[0]
	equipped_weapon = primary
	# The main hand is kept apart, since it is also where a shot leaves from.
	main_hand_slot = _attach_weapon(primary)

	# A two-handed weapon fills both slots, so the secondary item stays stowed.
	if primary and primary.handedness == WeaponData.Handedness.TWO_HANDED: return

	if hero_data.starting_weapons.size() < 2: return

	# Only an off-hand item is worn alongside: a second weapon waits in the hotbar.
	var secondary: WeaponData = hero_data.starting_weapons[1]
	if not secondary or secondary.handedness != WeaponData.Handedness.OFF_HAND: return

	off_hand_item = secondary
	_attach_weapon(secondary)


## Hangs one weapon on its hand bone and answers with its slot, or null if none.
func _attach_weapon(weapon: WeaponData) -> BoneAttachment3D:
	if not weapon or not weapon.world_model: return null

	var slot: BoneAttachment3D = BoneAttachment3D.new()
	skeleton.add_child(slot)
	# bone_name only resolves after add_child, when the node can already see the skeleton.
	slot.bone_name = OFF_HAND_BONE if weapon.hand == WeaponData.Hand.OFF else MAIN_HAND_BONE

	# The grip values live on the weapon, since each model has its own pivot.
	var model: Node3D = weapon.world_model.instantiate()
	slot.add_child(model)
	model.position = weapon.grip_position
	model.rotation_degrees = weapon.grip_rotation
	model.scale = Vector3.ONE * weapon.grip_scale

	return slot


## True when the main hand holds something that can be aimed down sights.
func can_aim() -> bool:
	if not equipped_weapon: return false

	# Anything that fires a shot is aimed, which covers the wand and the staff too.
	return equipped_weapon.projectile != null


## True when a shield is worn, which is what makes blocking possible.
func can_block() -> bool:
	return off_hand_item is ShieldData


## Lands the swing on every enemy standing in front of the hero and in reach.
func hit_enemies_in_swing() -> void:
	if not equipped_weapon: return

	var damage: float = equipped_weapon.get_damage(0, 0, 0)
	var is_magic: bool = equipped_weapon.scaling == WeaponData.Scaling.MAGIC

	# One swing hits every enemy in the wedge, which is what a wide weapon buys.
	for enemy: BaseEnemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.health_pool.is_depleted(): continue

		if _is_inside_swing(enemy):
			enemy.take_damage(damage, is_magic)


## Sends the equipped weapon's shot flying at whatever the crosshair covers.
func fire_shot() -> void:
	if not equipped_weapon or not equipped_weapon.projectile: return

	var origin: Vector3 = get_muzzle_position()
	var direction: Vector3 = camera_pivot.get_aim_direction(origin)

	# No attribute system yet, so the hit is worth the weapon damage alone.
	var damage: float = equipped_weapon.get_damage(0, 0, 0)

	Projectile.spawn(equipped_weapon.projectile, damage, self, origin, direction)


## Where a shot leaves the hero: the hand holding the weapon.
func get_muzzle_position() -> Vector3:
	if not is_instance_valid(main_hand_slot):
		# Nothing in hand to fire from, so the shot leaves around chest height.
		return global_position + Vector3.UP * DEFAULT_MUZZLE_HEIGHT

	return main_hand_slot.global_position


## True once the hero has run out of health, the run is over from here.
func is_dead() -> bool:
	return health_pool.is_depleted()


## The direction the hero is looking, which is wherever the camera points.
func get_facing_direction() -> Vector3:
	return Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))


## Takes one hit coming from a point in the world, run through the shield first.
func take_damage(amount: float, from_position: Vector3, is_magic: bool = false) -> void:
	if is_dead(): return

	var reduction: float = _shield_reduction(from_position, is_magic)
	health_pool.decrease(int(amount * (1.0 - reduction)))

	# A caught hit does not break the guard, which is the point of holding it.
	if reduction <= 0.0:
		_is_stagger_pending = true


## The state the last hit forces on the hero, cleared on read so it fires once.
func consume_interrupt_state() -> State:
	if is_dead():
		return death_state

	if not _is_stagger_pending:
		return null

	_is_stagger_pending = false
	return hurt_state


## Holds the hero in place, still letting gravity pull them down.
func stand_still(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


## Moves along the ground in the direction pressed, read relative to the camera.
func move_relative_to_camera(input_dir: Vector2, speed_scale: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# The direction follows the camera turn, not the Hero, which no longer turns on its own.
	var yaw_basis: Basis = Basis(Vector3.UP, camera_yaw)
	var direction: Vector3 = (yaw_basis.x * input_dir.x + yaw_basis.z * input_dir.y).normalized()

	velocity.x = direction.x * hero_data.move_speed * speed_scale
	velocity.z = direction.z * hero_data.move_speed * speed_scale
	move_and_slide()


## Smoothly turns only the visual model (not the body/camera) to face target_angle.
func face_mesh_direction(target_angle: float, delta: float) -> void:
	# lerp_angle turns gradually towards the target angle, instead of snapping straight there.
	mesh_facing = lerp_angle(mesh_facing, target_angle, MESH_TURN_SPEED * delta)
	# The original model faces the wrong way, so we rotate it 180° (half turn) to fix it.
	base.rotation.y = deg_to_rad(180.0) + mesh_facing


## True when one enemy is close enough, and in front enough, for the swing to reach.
func _is_inside_swing(enemy: BaseEnemy) -> bool:
	var offset: Vector3 = enemy.global_position - global_position
	# Measured flat on the ground, so a taller enemy is not treated as further away.
	offset.y = 0.0

	var distance: float = offset.length()
	if distance > equipped_weapon.attack_range: return false

	# Standing right on top of the hero, with no direction left to compare.
	if distance < 0.01: return true

	var angle: float = get_facing_direction().angle_to(offset.normalized())

	# attack_arc_degrees is the whole wedge, so only half of it opens to each side.
	return angle <= deg_to_rad(equipped_weapon.attack_arc_degrees * 0.5)


## Share of the damage the raised shield takes off, 0 when it isn't covering the hit.
func _shield_reduction(from_position: Vector3, is_magic: bool) -> float:
	if not is_blocking: return 0.0

	var shield: ShieldData = off_hand_item as ShieldData
	if not shield: return 0.0

	if not _is_inside_block_cone(shield, from_position): return 0.0

	if is_magic:
		return shield.magic_reduction

	return shield.physical_reduction


## True when the hit came from inside the cone the shield actually covers.
func _is_inside_block_cone(shield: ShieldData, from_position: Vector3) -> bool:
	var to_attacker: Vector3 = from_position - global_position
	to_attacker.y = 0.0

	# Something on top of the hero has no direction, so no shield can face it.
	if to_attacker.length() < 0.01: return false

	var angle: float = get_facing_direction().angle_to(to_attacker.normalized())

	# block_angle_degrees is the whole cone, so only half of it opens to each side.
	return angle <= deg_to_rad(shield.block_angle_degrees * 0.5)


## Plays an animation by its "library/animation" name (e.g. "general/Idle_A").
func play_animation(
	animation_name: StringName, 
	loop: bool = false, 
	blend: float = 0.2, 
	speed: float = 1.0
	) -> void:
		
	if not animation_player.has_animation(animation_name):
		print("animation error")
		return

	var animation: Animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	animation_player.play(animation_name, blend, speed)
