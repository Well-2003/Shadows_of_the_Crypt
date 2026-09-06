class_name ChaseEnemy
extends State
## Chase state: closes the distance until the player is within reach.
##
## Also the state every fight passes back through, so it is the one that decides
## whether the enemy attacks, backs away or waits out its cooldown.


var enemy: BaseEnemy = null

var _current_animation: String = ""


## Picks the enemy back up wherever the last state left it.
func enter() -> void:
	enemy = context
	# No animation here: passes that end next frame would flash one frame of running.
	_current_animation = ""


## Follows the player and stops once in range, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	var player: Hero = enemy.get_player()
	if not player:
		return enemy.idle_state

	var distance: float = enemy.get_distance_to_player()
	if not enemy.can_see_player(distance):
		return enemy.idle_state

	# A ranged class backs off first, otherwise it fires point blank.
	if enemy.is_player_too_close(distance) and enemy.can_retreat():
		var retreat: State = enemy.get_retreat_state()
		if retreat:
			return retreat

	if enemy.is_player_in_attack_range(distance):
		return _decide_in_range(player, delta)

	_play_looping("movement_basic/Running_A")
	enemy.move_towards(player.global_position, enemy.villain_data.chase_speed, delta)
	enemy.face_position(player.global_position, delta)

	return null


## Picks what to do with the player already in range: swing, guard or wait.
func _decide_in_range(player: Hero, delta: float) -> State:
	var attack: State = enemy.get_attack_state()

	if attack and enemy.is_attack_ready():
		return attack

	var waiting: State = enemy.get_waiting_state()
	if waiting:
		return waiting

	# Nothing to guard with, so it holds its ground until the attack is ready.
	_play_looping("special/Skeletons_Idle")
	enemy.stand_still(delta)
	enemy.face_position(player.global_position, delta)

	return null


## Starts a looping animation, unless it is already the one playing.
func _play_looping(animation_name: String) -> void:
	if _current_animation == animation_name: return

	_current_animation = animation_name
	enemy.play_animation(animation_name, true)
