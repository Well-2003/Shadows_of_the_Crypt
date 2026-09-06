class_name IdleEnemy
extends State
## Idle state: the enemy holds its ground and watches for the player.
##
## Where an enemy waits between patrol legs, and where it lands after losing
## sight of its target.


## How long the enemy stands still before walking the next patrol leg.
const IDLE_TIME: float = 2.5

var enemy: BaseEnemy = null
var _time_left: float = 0.0


## Plays the idle animation and starts the wait.
func enter() -> void:
	enemy = context
	_time_left = IDLE_TIME

	enemy.play_animation("special/Skeletons_Idle", true)


## Watches for the player, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	enemy.stand_still(delta)

	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	var distance: float = enemy.get_distance_to_player()
	if enemy.can_see_player(distance):
		return enemy.chase_state

	_time_left -= delta
	if _time_left <= 0.0:
		return enemy.patrol_state

	return null
