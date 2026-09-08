class_name BlockMeleeEnemy
extends State
## Block state: the enemy raises its shield and waits behind it.
##
## Only enemies carrying a shield use this, as a breather between swings.


## How long the guard is held before the enemy goes back to the fight.
const BLOCK_TIME: float = 1.2

var enemy: MeleeEnemy = null
var _time_left: float = 0.0


## Raises the shield and marks the enemy as guarding.
func enter() -> void:
	enemy = context
	_time_left = BLOCK_TIME

	enemy.is_blocking = true
	enemy.play_animation("combat_melee/Melee_Blocking", true)


## Clears the flag, so a hit landing after this frame is not reduced.
func exit() -> void:
	enemy.is_blocking = false


## Holds the guard, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	enemy.stand_still(delta)

	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	# The shield only covers what the enemy faces, so it keeps turning to the player.
	var player: Hero = enemy.get_player()
	if player:
		enemy.face_position(player.global_position, delta)

	_time_left -= delta
	if _time_left <= 0.0:
		return enemy.chase_state

	return null
