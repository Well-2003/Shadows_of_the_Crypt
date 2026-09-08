@tool
class_name BaseEnemy
extends CharacterBody3D
## Base enemy, shared by every skeleton class.
##
## Swaps mesh and gear from villain_data and hands movement over to a
## StateMachine, the same way Hero does for the player. Also holds the vocabulary
## the states use: moving, turning, counting cooldowns and taking damage.


## Skeleton bone the main hand weapon is attached to.
const MAIN_HAND_BONE: String = "handslot.r"
## Skeleton bone the off hand weapon or shield is attached to.
const OFF_HAND_BONE: String = "handslot.l"

## How fast the model turns to a new direction.
const MESH_TURN_SPEED: float = 8.0

## Share of the damage a raised shield stops.
const BLOCK_REDUCTION: float = 0.5
## Share of the max health one hit has to pass to stagger a heavy enemy.
const HEAVY_HIT_THRESHOLD: float = 0.15
## How long a cornered enemy fights on before it tries to back away again.
const RETREAT_COOLDOWN: float = 4.0
## Height a shot is aimed at on the target, so it flies level instead of at the feet.
const AIM_HEIGHT: float = 1.2
## Where a shot leaves from when the enemy has nothing in its hand.
const DEFAULT_MUZZLE_HEIGHT: float = 1.4

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
## How far from its starting spot the enemy wanders while patrolling.
@export var patrol_radius: float = 6.0

@export_group("Corpse")
## How long the body lies there after the death animation, before it starts to go.
@export var corpse_linger_time: float = 8.0
## How long the body takes to fade from solid to gone.
@export var corpse_fade_time: float = 4.0

var skeleton: Skeleton3D = null

var main_hand_slot: BoneAttachment3D = null
var home_position: Vector3 = Vector3.ZERO
var attack_cooldown_left: float = 0.0
var retreat_cooldown_left: float = 0.0
var is_blocking: bool = false
var equipment_slots: Array[BoneAttachment3D] = []
var mesh_facing: float = 0.0
var _is_stagger_pending: bool = false

@onready var base: Node3D = $Rig_Medium
@onready var animation_player: AnimationPlayer = $Rig_Medium/AnimationPlayer
@onready var damage_flash: DamageFlash = $DamageFlash

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
	# A fresh pool per instance, or every skeleton would share one health bar.
	health_pool = health_pool.duplicate()

	skeleton = base.get_node_or_null("Skeleton3D")
	_set_villain_data(villain_data)

	if Engine.is_editor_hint(): return

	add_to_group("Enemy")
	home_position = global_position

	health_pool.value_changed.connect(_on_health_changed)
	state_machine.init(self, initial_state)


## Runs every physics frame: lets the StateMachine decide the movement.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return

	# Counted here and not in a state, so the waits run whatever the enemy is doing.
	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	if retreat_cooldown_left > 0.0:
		retreat_cooldown_left -= delta

	state_machine.physics_update()


## Called when the class changes, swapping the mesh and the gear it carries.
func _set_villain_data(value: VillainClassData) -> void:
	villain_data = value

	if not is_node_ready() or not villain_data: return

	health_pool.set_max_value(int(value.max_health))
	health_pool.increase(int(value.max_health))

	var mesh_scene: PackedScene = load(MESHES[villain_data.id])
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

	_equip_weapons()


## Spawns the class's gear on the skeleton's hand bones.
func _equip_weapons() -> void:
	# Drops only what this script spawned, otherwise re-equipping stacks copies.
	for slot: BoneAttachment3D in equipment_slots:
		if is_instance_valid(slot):
			slot.free()

	equipment_slots.clear()

	# The main hand is kept apart, since it is also where a shot leaves from.
	main_hand_slot = _attach_model(villain_data.main_hand_model, MAIN_HAND_BONE,
		villain_data.main_hand_position, villain_data.main_hand_rotation)
	# The second slot picks its own bone, so a quiver can ride the chest.
	_attach_model(villain_data.off_hand_model, villain_data.off_hand_bone,
		villain_data.off_hand_position, villain_data.off_hand_rotation)


## Hangs one model on a bone and answers with its slot, or null when there is no model.
func _attach_model(model_scene: PackedScene, bone_name: String,
		grip_position: Vector3, grip_rotation: Vector3) -> BoneAttachment3D:
	if not model_scene: return null

	var slot: BoneAttachment3D = BoneAttachment3D.new()
	skeleton.add_child(slot)
	# bone_name only resolves after add_child, once the node can see the skeleton.
	slot.bone_name = bone_name

	var model: Node3D = model_scene.instantiate()
	slot.add_child(model)
	model.position = grip_position
	model.rotation_degrees = grip_rotation

	equipment_slots.append(slot)

	return slot


## The attack this class uses, answered by MeleeEnemy and RangedEnemy.
func get_attack_state() -> State:
	return null


## Where to go when the player gets too close, only ranged classes answer.
func get_retreat_state() -> State:
	return null


## Where the enemy waits out its attack cooldown, only shield carriers answer.
func get_waiting_state() -> State:
	return null


## True while the player is close enough to be attacked from here.
func is_player_in_attack_range(distance: float) -> bool:
	return distance <= villain_data.attack_range


## True while the player is too close, always false for melee.
func is_player_too_close(distance: float) -> bool:
	return distance < villain_data.retreat_range


## The player, or null while there is no hero in the scene.
func get_player() -> Hero:
	# Validated, so an enemy outliving the hero by a frame reads no freed node.
	if not is_instance_valid(Hero.player): return null

	return Hero.player


## Distance to the player, or a huge number while there is no hero to measure.
func get_distance_to_player() -> float:
	var player: Hero = get_player()
	if not player: return INF

	return global_position.distance_to(player.global_position)


## True when the player is close enough to be noticed.
func can_see_player(distance: float) -> bool:
	# Distance only for now, a RayCast3D goes here to make walls count as cover.
	return distance <= villain_data.detection_range


## True when this class carries a shield, which is what makes blocking possible.
func has_shield() -> bool:
	if not villain_data.off_hand_model: return false

	# Anything on another bone is a quiver or a trinket, not a guard.
	return villain_data.off_hand_bone == OFF_HAND_BONE


## True when the wait between one attack and the next is over.
func is_attack_ready() -> bool:
	return attack_cooldown_left <= 0.0


## Starts the wait that keeps the enemy from attacking again right away.
func start_attack_cooldown() -> void:
	attack_cooldown_left = villain_data.attack_cooldown


## True when the enemy is willing to give ground again.
func can_retreat() -> bool:
	return retreat_cooldown_left <= 0.0


## Starts the pause after a useless retreat, so a cornered enemy fights instead.
func start_retreat_cooldown() -> void:
	retreat_cooldown_left = RETREAT_COOLDOWN


## Lands one hit on the player, if they are still within reach.
func hit_player() -> void:
	var player: Hero = get_player()
	if not player: return

	# Measured again on impact, so stepping out of the swing is what saves the player.
	if get_distance_to_player() > villain_data.attack_range: return

	# The enemy position tells the hero which way the blow came from, for the shield.
	player.take_damage(villain_data.attack_damage, global_position)


## Where a shot leaves the enemy: the hand holding the weapon.
func get_muzzle_position() -> Vector3:
	if not is_instance_valid(main_hand_slot):
		# Nothing in hand to fire from, so the shot leaves around chest height.
		return global_position + Vector3.UP * DEFAULT_MUZZLE_HEIGHT

	return main_hand_slot.global_position


## Where a shot should be pointed to reach the player, or zero when there is none.
func get_aim_direction(from_position: Vector3) -> Vector3:
	var player: Hero = get_player()
	if not player: return Vector3.ZERO

	# The chest and not the origin, which sits on the floor and would aim down.
	var target: Vector3 = player.global_position + Vector3.UP * AIM_HEIGHT

	return (target - from_position).normalized()


## Takes one hit, run through this class's resistances and shield first.
func take_damage(amount: float, is_magic: bool = false) -> void:
	var multiplier: float = villain_data.physical_damage_taken
	if is_magic:
		multiplier = villain_data.magic_damage_taken

	if is_blocking:
		multiplier = multiplier * (1.0 - BLOCK_REDUCTION)

	health_pool.decrease(int(amount * multiplier))


## The state the last hit forces on the enemy, cleared on read so it fires once.
func consume_interrupt_state() -> State:
	if health_pool.is_depleted():
		return death_state

	if not _is_stagger_pending:
		return null

	_is_stagger_pending = false
	return hurt_state


## A random point around the spot the enemy started at, for the next patrol leg.
func pick_patrol_point() -> Vector3:
	var angle: float = randf_range(0.0, TAU)
	# Never right next to the enemy, or short legs look like shuffling in place.
	var distance: float = randf_range(patrol_radius * 0.5, patrol_radius)
	var offset: Vector3 = Vector3(sin(angle), 0.0, cos(angle)) * distance

	return home_position + offset


## Holds the enemy in place, still letting gravity pull them down.
func stand_still(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


## Walks towards a point on the ground at the given speed.
func move_towards(destination: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = destination - global_position
	# Height dropped before normalising, or it would eat the horizontal speed.
	direction.y = 0.0

	_move_in_direction(direction.normalized(), speed, delta)


## Walks straight away from a point, which is how the gap to the player reopens.
func move_away_from(threat_position: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = global_position - threat_position
	direction.y = 0.0

	_move_in_direction(direction.normalized(), speed, delta)


## Smoothly turns the model to look at a point, without turning the body.
func face_position(target_position: Vector3, delta: float) -> void:
	var offset: Vector3 = target_position - global_position
	# Measured from the offset pointing back, since face_direction adds the 180°.
	var target_angle: float = atan2(-offset.x, -offset.z)

	face_direction(target_angle, delta)


## Smoothly turns only the visual model (not the body) to face target_angle.
func face_direction(target_angle: float, delta: float) -> void:
	# lerp_angle turns gradually instead of snapping straight to the target.
	mesh_facing = lerp_angle(mesh_facing, target_angle, MESH_TURN_SPEED * delta)
	# The model faces the wrong way out of the box, so it is turned 180°.
	base.rotation.y = deg_to_rad(180.0) + mesh_facing


## How long one animation runs at normal speed, or 0 when there is no such animation.
func get_animation_length(animation_name: StringName) -> float:
	if not animation_player.has_animation(animation_name): return 0.0

	return animation_player.get_animation(animation_name).length


## Plays an animation by its "library/animation" name (e.g. "general/Idle_A").
func play_animation(animation_name: StringName, loop: bool = false, blend: float = 0.2, speed: float = 1.0) -> void:
	if not animation_player.has_animation(animation_name): return

	var animation: Animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	animation_player.play(animation_name, blend, speed)


## Moves the body along one direction, letting gravity keep it on the floor.
func _move_in_direction(direction: Vector3, speed: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()


## Blinks on every hit, and raises a stagger when the class is not immune to it.
func _on_health_changed(old_value: int, new_value: int, increased: bool) -> void:
	if increased: return

	# Every hit blinks: the flinch means staggered, the blink means damaged.
	damage_flash.flash()

	# Heavy classes only flinch on a real chunk of health, or a group chain-stuns them.
	if villain_data.immune_to_light_stagger:
		var damage: int = old_value - new_value
		var heavy_hit: int = int(health_pool.get_max_value() * HEAVY_HIT_THRESHOLD)

		if damage < heavy_hit: return

	_is_stagger_pending = true
