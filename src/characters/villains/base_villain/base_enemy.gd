@tool
class_name BaseEnemy
extends CharacterBody3D
## Base enemy, shared by every skeleton class.
##
## Swaps mesh and weapons based on villain_data and hands movement over to a
## StateMachine, the same way Hero does for the player.


## Skeleton bone the main hand weapon is attached to.
const MAIN_HAND_BONE: String = "handslot.r"
## Skeleton bone the off hand weapon or shield is attached to.
const OFF_HAND_BONE: String = "handslot.l"

## meshes for each enemy class, in the same order as VillainId
const MESHES: Array[String] = [
	"res://characters/villains/skel_mage/mesh_mage.tscn",
	"res://characters/villains/skel_minion/mesh_minion.tscn",
	"res://characters/villains/skel_rogue/mesh_rogue.tscn",
	"res://characters/villains/skel_warrior/mesh_warrior.tscn"
]

## Class resource with this enemy's attributes, changing it swaps the mesh.
@export var villain_data: VillainClassData = null: set = _set_villain_data
## State the StateMachine starts on, usually InactiveEnemy.
@export var initial_state: State = null
## Current and max health, filled from villain_data's max_health.
@export var health_pool: StatPool = StatPool.new()

var skeleton: Skeleton3D = null

@onready var base: Node3D = $RigMedium
@onready var animation_player: AnimationPlayer = $RigMedium/AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine


## Runs once on entering the scene: loads the class's mesh and sets up the states.
func _ready() -> void:
	skeleton = base.get_node_or_null("Skeleton3D")
	_set_villain_data(villain_data)

	if Engine.is_editor_hint(): return

	add_to_group("Enemy")
	state_machine.init(self, initial_state)


## Runs every physics frame: lets the StateMachine decide the movement.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return

	state_machine.physics_update()


## Called when the class changes, swapping the mesh and the gear it carries.
func _set_villain_data(value: VillainClassData) -> void:
	villain_data = value

	if not is_node_ready() or not villain_data: return

	health_pool.set_max_value(int(value.max_health))
	health_pool.increase(int(value.max_health))

	var mesh_scene: PackedScene = load(MESHES[villain_data.id])
	var mesh: Skeleton3D = mesh_scene.instantiate()

	# Remove the old one before the new one: if both coexist, Godot renames one
	# and the animation stops finding the bones.
	if skeleton:
		base.remove_child(skeleton)
		skeleton.queue_free()

	mesh.name = "Skeleton3D"
	base.add_child(mesh)
	skeleton = mesh

	_equip_weapons()


## Spawns the class's gear on the skeleton's hand bones.
func _equip_weapons() -> void:
	# Drops the old models first, otherwise re-equipping stacks copies.
	for child: Node in skeleton.get_children():
		if child is BoneAttachment3D:
			child.free()

	for weapon: WeaponData in villain_data.weapons:
		_attach_weapon(weapon)


## Attaches one weapon model to the hand bone the weapon asks for.
func _attach_weapon(weapon: WeaponData) -> void:
	if not weapon or not weapon.world_model: return

	var slot: BoneAttachment3D = BoneAttachment3D.new()
	skeleton.add_child(slot)
	# bone_name only resolves after add_child, when the node can already see the skeleton.
	slot.bone_name = OFF_HAND_BONE if weapon.hand == WeaponData.Hand.OFF else MAIN_HAND_BONE

	var model: Node3D = weapon.world_model.instantiate()
	slot.add_child(model)
	model.position = weapon.grip_position
	model.rotation_degrees = weapon.grip_rotation
	model.scale = Vector3.ONE * weapon.grip_scale


## Holds the enemy in place, still letting gravity pull them down.
func stand_still(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


## Plays an animation by its "library/animation" name (e.g. "general/Idle_A").
func play_animation(animation_name: StringName, loop: bool = false, blend: float = 0.2, speed: float = 1.0) -> void:
	if not animation_player.has_animation(animation_name): return

	var animation: Animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	animation_player.play(animation_name, blend, speed)
