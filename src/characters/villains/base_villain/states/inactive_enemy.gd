class_name InactiveEnemy
extends State
## Inactive state: the enemy stands dormant until something wakes it up.
##
## Enemies start here so a room full of skeletons costs nothing until the player
## actually walks in. The wake-up animation is the beat that shows they noticed.


## Pose the skeleton holds while it is still dormant.
const INACTIVE_POSE: String = "special/Skeletons_Inactive_Standing_Pose"
## The skeleton pulling itself together once it notices the player.
const AWAKEN_ANIMATION: String = "special/Skeletons_Awaken_Standing"

var enemy: BaseEnemy = null
var _is_waking: bool = false
var _is_awake: bool = false


## Drops the skeleton into its dormant pose.
func enter() -> void:
	enemy = context
	_is_waking = false
	_is_awake = false

	enemy.play_animation(INACTIVE_POSE, true)


## Drops the connection when the wake-up is cut short, so the next one is free.
func exit() -> void:
	var finished: Signal = enemy.animation_player.animation_finished
	if finished.is_connected(_on_animation_finished):
		finished.disconnect(_on_animation_finished)


## Waits for the player to walk in, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	enemy.stand_still(delta)

	# Being shot from across the room also wakes it, since the flinch leads to the chase.
	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	if _is_awake:
		return enemy.chase_state

	# Already standing up, so nothing is watched for until that finishes.
	if _is_waking:
		return null

	var distance: float = enemy.get_distance_to_player()
	if enemy.can_see_player(distance):
		_start_waking()

	return null


## Plays the wake-up, the beat that shows the player they have been noticed.
func _start_waking() -> void:
	_is_waking = true

	# With no wake-up animation there is nothing to wait for, so it chases at once.
	if enemy.get_animation_length(AWAKEN_ANIMATION) <= 0.0:
		_is_awake = true
		return

	enemy.play_animation(AWAKEN_ANIMATION, false, 0.1)
	enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_awake = true
