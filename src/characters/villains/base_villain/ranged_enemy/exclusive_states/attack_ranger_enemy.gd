class_name AttackRangerEnemy
extends State
## Ranged attack state: fires at the player from a distance.
##
## The enemy plants its feet to shoot, which is the window the player has to
## close the gap.


## How far into the animation the shot leaves, 0.6 being a little past the middle.
const IMPACT_RATIO: float = 0.6

var enemy: RangedEnemy = null

var _time_until_shot: float = 0.0
var _has_shot: bool = false
var _is_finished: bool = false


## Aims at the player and starts the shot.
func enter() -> void:
	enemy = context
	_time_until_shot = enemy.villain_data.telegraph_time
	_has_shot = false
	_is_finished = false

	# Started here, so the wait between attacks counts from when this one began.
	enemy.start_attack_cooldown()

	var animations: Array[String] = enemy.villain_data.attack_animations
	# Nothing to play means nothing to wait for, so the state ends next frame.
	if animations.is_empty():
		_is_finished = true
		return

	_play_shot(animations.pick_random())


## Drops the connection when the shot is cut short, so the next one is free.
func exit() -> void:
	var finished: Signal = enemy.animation_player.animation_finished
	if finished.is_connected(_on_animation_finished):
		finished.disconnect(_on_animation_finished)


## Keeps the enemy still while it fires, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	enemy.stand_still(delta)

	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	# The aim tracks all the way through: what the player dodges is distance, not angle.
	var player: Hero = enemy.get_player()
	if player:
		enemy.face_position(player.global_position, delta)

	_advance_aim(delta)

	if _is_finished:
		return _state_after_shot()

	return null


## Plays the shot stretched so it leaves right at the end of the aim.
func _play_shot(animation_name: String) -> void:
	var length: float = enemy.get_animation_length(animation_name)
	var telegraph: float = enemy.villain_data.telegraph_time
	var speed: float = 1.0

	# Without this a long aim outlasts its own animation and never fires.
	if length > 0.0 and telegraph > 0.0:
		speed = (length * IMPACT_RATIO) / telegraph

	enemy.play_animation(animation_name, false, 0.1, speed)

	# CONNECT_ONE_SHOT drops itself, so an old shot never ends a later one.
	enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Counts the aim down and fires at the end of it.
func _advance_aim(delta: float) -> void:
	if _has_shot: return

	_time_until_shot -= delta
	if _time_until_shot > 0.0: return

	_has_shot = true
	# A projectile from here on, so landing is up to the player dodging it.
	enemy.fire_shot()


## Backs away if the player closed in during the shot, otherwise back to chasing.
func _state_after_shot() -> State:
	var distance: float = enemy.get_distance_to_player()

	if enemy.is_player_too_close(distance) and enemy.can_retreat():
		return enemy.escape_state

	return enemy.chase_state


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
