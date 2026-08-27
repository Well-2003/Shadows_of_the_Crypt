class_name PlayerAttackState
extends State
## Attack state: swings the equipped weapon, then hands control back to idle.
##
## The hero stands still through the swing so the animation is not cut short by
## movement. Which animation plays and how fast comes from the equipped weapon.


var _is_finished: bool = false


## Picks one of the weapons attack animations and starts the swing.
func enter() -> void:
	var hero: Hero = context
	_is_finished = false

	var weapon: WeaponData = hero.equipped_weapon
	# With no weapon, or a weapon with no swing, there is nothing to play,
	# the state ends on the next frame instead of locking the hero in place.
	if not weapon or weapon.attack_animations.is_empty():
		_is_finished = true
		return

	hero.play_animation(weapon.attack_animations.pick_random(), false, 0.1, weapon.attack_speed)

	# CONNECT_ONE_SHOT drops the connection by itself, so an old swing can never
	# end a later one.
	hero.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Holds the hero in place until the swing ends.
func physics_update() -> State:
	var hero: Hero = context
	hero.stand_still(get_physics_process_delta_time())

	# Idle sends the hero straight back to walking if a direction is held, so
	# there is no need to remember which state the swing interrupted.
	if _is_finished:
		return hero.idle_state

	return null


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
