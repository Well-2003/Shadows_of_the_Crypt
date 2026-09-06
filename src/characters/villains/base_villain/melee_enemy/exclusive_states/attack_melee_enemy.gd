class_name AttackMeleeEnemy
extends State
## Melee attack state: swings at the player from close range.
##
## The swing is telegraphed before it lands, so the player has a window to read
## it and step away.


## How far into the swing the blow lands, 0.6 being a little past the middle.
const IMPACT_RATIO: float = 0.6

var enemy: MeleeEnemy = null

var _time_until_hit: float = 0.0
var _has_hit: bool = false
var _is_finished: bool = false


## Starts the telegraph and then the swing.
func enter() -> void:
	enemy = context
	_time_until_hit = enemy.villain_data.telegraph_time
	_has_hit = false
	_is_finished = false

	# Started here, so the wait between attacks counts from when this one began.
	enemy.start_attack_cooldown()

	var animations: Array[String] = enemy.villain_data.attack_animations
	# Nothing to play means nothing to wait for, so the state ends next frame.
	if animations.is_empty():
		_is_finished = true
		return

	_play_swing(animations.pick_random())


## Drops the connection when the swing is cut short, so the next one is free.
func exit() -> void:
	var finished: Signal = enemy.animation_player.animation_finished
	if finished.is_connected(_on_animation_finished):
		finished.disconnect(_on_animation_finished)


## Holds the enemy in place through the swing, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	enemy.stand_still(delta)

	# A light class is knocked out of its own swing here, a heavy one is not.
	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	_aim_at_player(delta)
	_advance_telegraph(delta)

	if _is_finished:
		return enemy.chase_state

	return null


## Plays the swing stretched so the blow lands right at the end of the telegraph.
func _play_swing(animation_name: String) -> void:
	var length: float = enemy.get_animation_length(animation_name)
	var telegraph: float = enemy.villain_data.telegraph_time
	var speed: float = 1.0

	# Without this a long telegraph outlasts its own animation and never hits.
	if length > 0.0 and telegraph > 0.0:
		speed = (length * IMPACT_RATIO) / telegraph

	enemy.play_animation(animation_name, false, 0.1, speed)

	# CONNECT_ONE_SHOT drops itself, so an old swing never ends a later one.
	enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Turns the enemy towards the player, but only while the swing is still coming.
func _aim_at_player(delta: float) -> void:
	# Once the blow is out it is committed, or it would track the player mid swing.
	if _has_hit: return

	var player: Hero = enemy.get_player()
	if not player: return

	enemy.face_position(player.global_position, delta)


## Counts the wind-up down and lands the blow at the end of it.
func _advance_telegraph(delta: float) -> void:
	if _has_hit: return

	_time_until_hit -= delta
	if _time_until_hit > 0.0: return

	_has_hit = true
	enemy.hit_player()


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
