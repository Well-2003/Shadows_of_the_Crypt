class_name EscapeEnemy
extends State
## Escape state: backs away when the player gets too close.
##
## What keeps a ranged enemy at its ideal range instead of being cornered, and
## sends it back to shooting once the gap is open again.


## Longest the enemy keeps backing away before it turns and fights anyway.
const MAX_ESCAPE_TIME: float = 2.5

var enemy: RangedEnemy = null
var _time_left: float = 0.0


## Turns the enemy away and starts retreating.
func enter() -> void:
	enemy = context
	_time_left = MAX_ESCAPE_TIME

	enemy.play_animation("movement_advanced/Walking_Backwards", true)


## Backs off until the player is far enough again, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	var player: Hero = enemy.get_player()
	if not player:
		return enemy.idle_state

	var distance: float = enemy.get_distance_to_player()
	if not enemy.is_player_too_close(distance):
		return enemy.chase_state

	enemy.move_away_from(player.global_position, enemy.villain_data.escape_speed, delta)
	# Keeps facing the player, so it can shoot the moment the gap is open.
	enemy.face_position(player.global_position, delta)

	# Cornered it would retreat forever, so it gives up on time and takes a cooldown.
	_time_left -= delta
	if _time_left <= 0.0:
		enemy.start_retreat_cooldown()
		return enemy.chase_state

	return null
