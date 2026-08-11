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

var skeleton: Skeleton3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

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


## Smoothly turns only the visual model (not the body/camera) to face target_angle.
func face_mesh_direction(target_angle: float, delta: float) -> void:
	# lerp_angle turns gradually towards the target angle, instead of snapping straight there.
	mesh_facing = lerp_angle(mesh_facing, target_angle, MESH_TURN_SPEED * delta)
	# The original model faces the wrong way, so we rotate it 180° (half turn) to fix it.
	base.rotation.y = deg_to_rad(180.0) + mesh_facing


## Plays an animation by its "library/animation" name (e.g. "general/Idle_A").
func play_animation(animation_name: StringName, loop: bool = false, blend: float = 0.2) -> void:
	if not animation_player.has_animation(animation_name):
		print("animation error")
		return

	var animation: Animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	animation_player.play(animation_name, blend)
