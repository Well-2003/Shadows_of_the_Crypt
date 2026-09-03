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

## Bone attachments this script spawned, so it never frees the model's own ones.
var equipment_slots: Array[BoneAttachment3D] = []

@onready var base: Node3D = $RigMedium
@onready var animation_player: AnimationPlayer = $RigMedium/AnimationPlayer

#region States shared by every enemy class
@onready var state_machine: StateMachine = $StateMachine
@onready var inactive_state: State = $StateMachine/InactiveState
@onready var idle_state: State = $StateMachine/IdleState
@onready var patrol_state: State = $StateMachine/PatrolState
@onready var chase_state: State = $StateMachine/ChaseState
@onready var hurt_state: State = $StateMachine/HurtState
@onready var death_state: State = $StateMachine/DeathState
#endregion


## Runs once on entering the scene, loads the class's mesh and sets up the states.
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

	# Remove the old one before the new one, if both coexist, Godot renames one and the animation stops finding the bones.
	if skeleton:
		base.remove_child(skeleton)
		skeleton.queue_free()

	mesh.name = "Skeleton3D"
	base.add_child(mesh)
	skeleton = mesh

	_equip_weapons()


## Spawns the class's gear on the skeleton's hand bones.
func _equip_weapons() -> void:
	# Drops only what this script spawned, otherwise re-equipping stacks copies.
	for slot: BoneAttachment3D in equipment_slots:
		if is_instance_valid(slot):
			slot.free()

	equipment_slots.clear()

	_attach_model(villain_data.main_hand_model, MAIN_HAND_BONE,
		villain_data.main_hand_position, villain_data.main_hand_rotation)
	# The second slot picks its own bone, so a quiver can ride the chest instead of swinging around on the hand.
	_attach_model(villain_data.off_hand_model, villain_data.off_hand_bone,
		villain_data.off_hand_position, villain_data.off_hand_rotation)


## Hangs one model off the given bone, lined up by the class's grip values.
func _attach_model(model_scene: PackedScene, bone_name: String,
		grip_position: Vector3, grip_rotation: Vector3) -> void:
	if not model_scene: return

	var slot: BoneAttachment3D = BoneAttachment3D.new()
	skeleton.add_child(slot)
	# bone_name only resolves after add_child, when the node can already see the skeleton.
	slot.bone_name = bone_name

	var model: Node3D = model_scene.instantiate()
	slot.add_child(model)
	model.position = grip_position
	model.rotation_degrees = grip_rotation

	equipment_slots.append(slot)


## The attack this class uses, answered by MeleeEnemy and RangedEnemy.
func get_attack_state() -> State:
	return null


## Where to go when the player gets too close, only ranged classes answer.
func get_retreat_state() -> State:
	return null


## True while the player is close enough to be attacked from here.
func is_player_in_attack_range(distance: float) -> bool:
	return distance <= villain_data.attack_range


## True while the player is too close, always false for melee.
func is_player_too_close(distance: float) -> bool:
	return distance < villain_data.retreat_range


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
