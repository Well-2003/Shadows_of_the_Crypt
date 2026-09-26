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

## Share of the move speed left when a stamina class has run out of stamina.
const EXHAUSTED_SPEED_SCALE: float = 0.55

## How long after a flinch the hero cannot be staggered again, in seconds.
const STAGGER_COOLDOWN: float = 1.2

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
## Stamina, mana or ammo, filled from hero_data's resource_max.
@export var resource_pool: StatPool = StatPool.new()
## How fast the camera turns with mouse movement.
@export var mouse_sensitivity: float = 0.003
## Editor helper: tick this to re-attach the weapons after editing their grip values.
@export var refresh_equipment: bool = false: set = _refresh_equipment

@export_group("Combat Layers")
## Layer this character's shots and swings sit on.
@export_flags_3d_physics var attack_layer: int = 0
## Layers this character's shots and swings are able to hit.
@export_flags_3d_physics var attack_mask: int = 0

var skeleton: Skeleton3D = null

var equipped_weapon: WeaponData = null
var off_hand_item: WeaponData = null
var is_blocking: bool = false

var main_hand_slot: BoneAttachment3D = null
var main_hand_hitbox: WeaponHitbox = null

var mesh_facing: float = 0.0
var camera_yaw: float = 0.0

var _is_stagger_pending: bool = false
var _is_block_hit_pending: bool = false
var _stagger_cooldown_left: float = 0.0
var _regen_delay_left: float = 0.0
var _regen_carry: float = 0.0
var _regen_boost: float = 1.0
var _regen_boost_left: float = 0.0

@onready var base: Node3D = $Rig_Medium
@onready var animation_player: AnimationPlayer = $Rig_Medium/AnimationPlayer
@onready var camera_pivot: PlayerCamera = $PlayerCamera
@onready var damage_flash: DamageFlash = $DamageFlash
@onready var hotbar: Hotbar = $Hotbar
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
	# Connected before the data is applied, or the first fill would reach nobody.
	hotbar.changed.connect(_on_hotbar_changed)
	_set_hero_data(hero_data)

	if Engine.is_editor_hint(): return

	player = self

	state_machine.init(self, initial_state)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	health_pool.value_changed.connect(_on_health_changed)
	resource_pool.value_changed.connect(_on_resource_changed)

	_sync_hud()


func _on_health_changed(_old_value: int, new_value: int, increased: bool) -> void:
	hud.set_health(new_value, health_pool.get_max_value())

	# Blinks even on a blocked hit: the guard removes the stagger, not the damage.
	if not increased:
		damage_flash.flash()


func _on_resource_changed(_old_value: int, new_value: int, _increased: bool) -> void:
	hud.set_resource(new_value, resource_pool.get_max_value())


## Writes the class's numbers into the HUD, bar or counter picked to match it.
func _sync_hud() -> void:
	# The HUD script does not run in the editor, so its nodes are not there to touch.
	if Engine.is_editor_hint(): return

	hud.set_health(health_pool.get_value(), health_pool.get_max_value())
	hud.setup_resource(hero_data)
	hud.set_resource(resource_pool.get_value(), resource_pool.get_max_value())


## Re-hangs the models whenever the selected slot changes.
func _on_hotbar_changed(_all_slots: Array[WeaponData], _selected: int) -> void:
	_apply_hotbar()

	# The HUD script does not run in the editor, so its nodes are not there to touch.
	if Engine.is_editor_hint(): return

	hud.set_hotbar(hotbar.slots, hotbar.selected_index)


## Clears the shared reference on the way out, so nothing holds a freed hero.
func _exit_tree() -> void:
	if player == self:
		player = null


## Runs every physics frame: lets the StateMachine decide the movement.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return

	# Counted here and not in a state, so both run whatever the hero is doing.
	if _stagger_cooldown_left > 0.0:
		_stagger_cooldown_left -= delta

	_advance_regen_boost(delta)
	_regenerate_resource(delta)

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

	if _handle_hotbar_input(event): return

	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw stays on the camera, so it orbits without rotating the hero.
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.y = camera_yaw
		camera_pivot.apply_pitch(-event.relative.y * mouse_sensitivity)


## Switches slots on the number keys, and answers whether the key was one of them.
func _handle_hotbar_input(event: InputEvent) -> bool:
	# Swapping weapons mid swing would leave the blade open with nothing holding it.
	if state_machine.current_state == attack_state: return false

	for index: int in Hotbar.SLOT_COUNT:
		# The actions are numbered from one, the slots from zero.
		if not event.is_action_pressed("hotbar_" + str(index + 1)): continue

		hotbar.select(index)
		return true

	return false


## Called when the class changes, swapping the mesh and the gear it carries.
func _set_hero_data(value: HeroClassData) -> void:
	hero_data = value

	if not is_node_ready(): return

	health_pool.set_max_value(int(value.max_health))
	health_pool.increase(int(value.max_health))

	resource_pool.set_max_value(int(value.resource_max))
	resource_pool.increase(int(value.resource_max))

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

	# Fills the bar, which then calls back and hangs the models on the new skeleton.
	hotbar.setup(hero_data)

	# The class is picked after _ready by GameManager, so the HUD is caught up here
	# and not only on the way in, or it would keep showing the scene's default class.
	_sync_hud()


## Re-attaches the weapons, so grip tweaks show up without running the game.
func _refresh_equipment(_value: bool) -> void:
	# Stays false so the checkbox works like a button instead of a setting.
	refresh_equipment = false

	if not is_node_ready() or not hero_data: return

	_apply_hotbar()


## Hangs the selected weapon and the worn off hand item on the skeleton's bones.
func _apply_hotbar() -> void:
	# Drops the old models first, otherwise re-equipping stacks copies.
	for child: Node in skeleton.get_children():
		if child is BoneAttachment3D:
			child.free()

	main_hand_slot = null
	main_hand_hitbox = null

	equipped_weapon = hotbar.get_selected()
	off_hand_item = hotbar.get_off_hand()

	# The main hand is kept apart, since it is also where a shot leaves from.
	main_hand_slot = _attach_weapon(equipped_weapon)
	_attach_weapon(off_hand_item)


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

	_attach_hitbox(weapon, model)

	return slot


## Hangs the swing volume on the weapon model, for the weapons that swing at all.
func _attach_hitbox(weapon: WeaponData, model: Node3D) -> void:
	if Engine.is_editor_hint(): return

	# A weapon that fires a shot lands its damage through the projectile instead.
	if weapon.projectile: return
	if weapon.hand == WeaponData.Hand.OFF: return

	var hitbox: WeaponHitbox = WeaponHitbox.create(self, weapon.hitbox_length,
		weapon.hitbox_radius, weapon.hitbox_offset, weapon.hitbox_rotation)

	# Hung on the model, so the grip rotation already lines it up with the blade.
	model.add_child(hitbox)
	main_hand_hitbox = hitbox


## True when the main hand holds something that can be aimed down sights.
func can_aim() -> bool:
	if not equipped_weapon: return false

	# Anything that fires a shot is aimed, which covers the wand and the staff too.
	return equipped_weapon.projectile != null


## True when a shield is worn, which is what makes blocking possible.
func can_block() -> bool:
	return off_hand_item is ShieldData


## Makes the blade able to hit, for the window the swing stays dangerous.
func open_swing() -> void:
	if not main_hand_hitbox: return

	var is_magic: bool = equipped_weapon.scaling == WeaponData.Scaling.MAGIC
	main_hand_hitbox.open(get_attack_damage(), is_magic)


## Shuts the blade again, which is what ends the swing's chance to land.
func close_swing() -> void:
	if not main_hand_hitbox: return

	main_hand_hitbox.close()


## Sends the equipped weapon's shot flying at whatever the crosshair covers.
func fire_shot() -> void:
	if not equipped_weapon or not equipped_weapon.projectile: return

	var origin: Vector3 = get_muzzle_position()
	var direction: Vector3 = camera_pivot.get_aim_direction(origin)

	Projectile.spawn(equipped_weapon.projectile, get_attack_damage(), self, origin, direction)


## What one hit with the equipped weapon is worth, class attributes included.
func get_attack_damage() -> float:
	if not equipped_weapon: return 0.0

	# The class attributes line up with the weapon's Scaling: melee, ranged, magic.
	return equipped_weapon.get_damage(
		int(hero_data.physical_damage_melee),
		int(hero_data.physical_damage_ranged),
		int(hero_data.magic_damage))


## What one use of the equipped weapon costs this class.
func get_attack_cost() -> int:
	if not equipped_weapon: return 0

	# Ammo is spent by the weapon that fires it, so a backup blade never eats arrows.
	if hero_data.is_ammo() and not equipped_weapon.projectile: return 0

	return equipped_weapon.resource_cost


## True when the pool still covers what the equipped weapon costs to use.
func can_afford_attack() -> bool:
	if not equipped_weapon: return false

	return resource_pool.get_value() >= get_attack_cost()


## Pays for one attack and holds the refill back for a moment.
func spend_attack_cost() -> void:
	var cost: int = get_attack_cost()
	if cost <= 0: return

	resource_pool.decrease(cost)
	_regen_delay_left = hero_data.resource_regen_delay


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
	if reduction > 0.0:
		_is_block_hit_pending = true
		return

	# Still shaken from the last flinch, so this hit only costs health. Without this
	# a group lands hits faster than the flinch lasts and the hero never moves again.
	if _stagger_cooldown_left > 0.0: return

	_is_stagger_pending = true


## The state the last hit forces on the hero, cleared on read so it fires once.
func consume_interrupt_state() -> State:
	if is_dead():
		return death_state

	if not _is_stagger_pending:
		return null

	_is_stagger_pending = false
	# Counted from the flinch itself, not from the hit that caused it.
	_stagger_cooldown_left = STAGGER_COOLDOWN
	return hurt_state


## True once per hit the shield caught, cleared on read so it plays a single time.
func consume_block_hit() -> bool:
	if not _is_block_hit_pending: return false

	_is_block_hit_pending = false
	return true


## True while a stamina class has nothing left to spend, which slows it down.
func is_exhausted() -> bool:
	if not hero_data: return false
	if hero_data.resource_type != HeroClassData.ResourceType.STAMINA: return false

	return resource_pool.is_depleted()


## Puts resource back in the pool, for a quiver, a potion or a shop refill.
func restore_resource(amount: int) -> void:
	if amount <= 0: return

	resource_pool.increase(amount)


## Speeds the refill up for a while, for a potion that boosts recovery.
func start_regen_boost(multiplier: float, duration: float) -> void:
	_regen_boost = multiplier
	_regen_boost_left = duration


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

	var speed: float = hero_data.move_speed * speed_scale
	# Out of stamina the hero drags, which is what makes spending it a choice.
	if is_exhausted():
		speed *= EXHAUSTED_SPEED_SCALE

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()


## Smoothly turns only the visual model (not the body/camera) to face target_angle.
func face_mesh_direction(target_angle: float, delta: float) -> void:
	# lerp_angle turns gradually towards the target angle, instead of snapping straight there.
	mesh_facing = lerp_angle(mesh_facing, target_angle, MESH_TURN_SPEED * delta)
	# The original model faces the wrong way, so we rotate it 180° (half turn) to fix it.
	base.rotation.y = deg_to_rad(180.0) + mesh_facing


## Counts the boost down and puts the refill back to its normal speed.
func _advance_regen_boost(delta: float) -> void:
	if _regen_boost_left <= 0.0: return

	_regen_boost_left -= delta
	if _regen_boost_left > 0.0: return

	_regen_boost = 1.0


## Puts the spent resource back, once the hero has gone a moment without attacking.
func _regenerate_resource(delta: float) -> void:
	# Ammo never comes back on its own: a quiver, a potion or the shop refills it.
	if hero_data.is_ammo(): return

	if resource_pool.get_value() >= resource_pool.get_max_value(): return

	if _regen_delay_left > 0.0:
		_regen_delay_left -= delta
		return

	# The pool counts in whole points, so the fraction is carried until it makes one.
	_regen_carry += hero_data.resource_regen_per_second * _regen_boost * delta

	var whole_points: int = int(_regen_carry)
	if whole_points <= 0: return

	_regen_carry -= whole_points
	resource_pool.increase(whole_points)


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
