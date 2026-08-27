@tool
class_name Hero
extends CharacterBody3D
## Playable character.
##
## Swaps mesh/animations based on hero_data, delegates movement and
## animation to StateMachine, and exposes camera_yaw so the camera can
## orbit without depending on the body's own rotation.


## How fast the model turns to a new direction.
const MESH_TURN_SPEED: float = 12.0

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
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var equipped_weapon: WeaponData = null
var off_hand_item: WeaponData = null
var is_blocking: bool = false

var mesh_facing: float = 0.0
var camera_yaw: float = 0.0

@onready var base: Node3D = $Rig_Medium
@onready var animation_player: AnimationPlayer = $Rig_Medium/AnimationPlayer
@onready var camera_pivot: PlayerCamera = $PlayerCamera
@onready var hud: HUD = $Hud

#region States
@onready var state_machine: StateMachine = $StateMachine
@onready var idle_state: State = $StateMachine/IdleState
@onready var walk_state: State = $StateMachine/WalkState
@onready var attack_state: State = $StateMachine/AttackState
@onready var aim_state: State = $StateMachine/AimState
@onready var block_state: State = $StateMachine/BlockState
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


func _on_health_changed(_old_value: int, new_value: int, _increased: bool) -> void:
	hud.set_health(new_value, health_pool.get_max_value())


## Runs every physics frame: lets the StateMachine decide the movement.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return

	state_machine.physics_update()


## Reads the mouse: Esc releases/recaptures it, and its movement turns the camera.
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return

	# Esc releases the mouse (handy for debugging); clicking the window recaptures it.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw stays only on the camera (doesn't rotate the Hero), so it orbits the stationary character.
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.y = camera_yaw
		camera_pivot.apply_pitch(-event.relative.y * mouse_sensitivity)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: health_pool.increase(10)
			KEY_2: health_pool.decrease(10)


## called when a mesh is added, it removes the old one and puts in the new one matching the selected class
func _set_hero_data(value: HeroClassData) -> void:
	hero_data = value

	if not is_node_ready(): return

	health_pool.set_max_value(int(value.max_health))
	health_pool.increase(int(value.max_health))  

	var mesh_scene: PackedScene = load(MESHES[hero_data.id])
	var mesh: Skeleton3D = mesh_scene.instantiate()

	# Remove the old one before the new one: if both coexist, Godot renames one and the animation stops finding the bones.
	if skeleton:
		base.remove_child(skeleton)
		skeleton.queue_free()

	mesh.name = "Skeleton3D"
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

	if hero_data.starting_weapons.is_empty(): return

	var primary: WeaponData = hero_data.starting_weapons[0]
	equipped_weapon = primary
	_attach_weapon(primary)

	# A two-handed weapon fills both slots, so the secondary item stays stowed.
	if primary and primary.handedness == WeaponData.Handedness.TWO_HANDED: return

	if hero_data.starting_weapons.size() < 2: return

	# Only an off-hand item is worn next to the primary weapon. Anything else in
	# slot 2 is a second weapon the player swaps to, so it waits in the hotbar
	# instead of being held, since there is no animation for wielding both.
	var secondary: WeaponData = hero_data.starting_weapons[1]
	if not secondary or secondary.handedness != WeaponData.Handedness.OFF_HAND: return

	off_hand_item = secondary
	_attach_weapon(secondary)


## Attaches one weapon model to the hand bone the weapon asks for.
func _attach_weapon(weapon: WeaponData) -> void:
	if not weapon or not weapon.world_model: return

	var slot: BoneAttachment3D = BoneAttachment3D.new()
	skeleton.add_child(slot)
	# bone_name only resolves after add_child, when the node can already see the skeleton.
	slot.bone_name = OFF_HAND_BONE if weapon.hand == WeaponData.Hand.OFF else MAIN_HAND_BONE

	# The grip values line the model up with the hand; each weapon is modelled
	# around a different pivot, so they live on the weapon instead of here.
	var model: Node3D = weapon.world_model.instantiate()
	slot.add_child(model)
	model.position = weapon.grip_position
	model.rotation_degrees = weapon.grip_rotation
	model.scale = Vector3.ONE * weapon.grip_scale


## True when the main hand holds something that can be aimed down sights.
func can_aim() -> bool:
	if not equipped_weapon: return false

	return equipped_weapon.weapon_type == WeaponData.WeaponType.BOW \
		or equipped_weapon.weapon_type == WeaponData.WeaponType.CROSSBOW


## True when a shield is worn, which is what makes blocking possible.
func can_block() -> bool:
	return off_hand_item is ShieldData


## Holds the hero in place, still letting gravity pull them down.
func stand_still(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


## Moves along the ground in the direction pressed, read relative to the camera.
func move_relative_to_camera(input_dir: Vector2, speed_scale: float, delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

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


## Plays an animation by its "library/animation" name (e.g. "general/Idle_A").
func play_animation(animation_name: StringName, loop: bool = false, blend: float = 0.2, speed: float = 1.0) -> void:
	if not animation_player.has_animation(animation_name):
		print("animation error")
		return

	var animation: Animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	animation_player.play(animation_name, blend, speed)
