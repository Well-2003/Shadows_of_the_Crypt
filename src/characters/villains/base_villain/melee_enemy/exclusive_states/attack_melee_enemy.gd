class_name AttackMeleeEnemy
extends State
## Melee attack state: swings at the player from close range.
##
## The swing is telegraphed before it lands, so the player has a window to read
## it and step away.


## How far into the swing the blow lands, 0.6 being a little past the middle.
const IMPACT_RATIO: float = 0.6
## Share of the wind-up that passes before the weapon becomes dangerous.
##
## Not the whole of it, because the animations do not agree on when the weapon
## sweeps past the target: a chop reaches it near the end, a horizontal slice
## about a fifth of the way in. Going live early covers both, and the enemy is
## still visibly winding up for the first part of it.
const LIVE_AFTER_RATIO: float = 0.25

var enemy: MeleeEnemy = null

var _elapsed: float = 0.0
var _is_live: bool = false
var _is_committed: bool = false
var _is_finished: bool = false


## Starts the telegraph and then the swing.
func enter() -> void:
	enemy = context
	_elapsed = 0.0
	_is_live = false
	_is_committed = false
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
	# A swing cut short would otherwise leave the weapon live for the rest of the fight.
	enemy.close_swing()

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
	_advance_swing(delta)

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
	# Once the blow is committed it stops tracking, or it would follow mid swing.
	if _is_committed: return

	var player: Hero = enemy.get_player()
	if not player: return

	enemy.face_position(player.global_position, delta)


## Runs the swing's clock: the weapon goes live, the aim commits, the weapon shuts.
func _advance_swing(delta: float) -> void:
	_elapsed += delta

	var telegraph: float = enemy.villain_data.telegraph_time

	if not _is_live and _elapsed >= telegraph * LIVE_AFTER_RATIO:
		_is_live = true
		enemy.open_swing()

	# The aim still commits at the end of the wind-up, whatever the weapon is doing.
	if not _is_committed and _elapsed >= telegraph:
		_is_committed = true

	if _is_live and _elapsed >= telegraph + enemy.villain_data.hitbox_window:
		_is_live = false
		enemy.close_swing()


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
