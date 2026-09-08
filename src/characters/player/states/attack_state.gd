class_name PlayerAttackState
extends State
## Attack state: swings or fires the equipped weapon, then hands control back.
##
## The hero stands still through the swing so the animation is not cut short by
## movement. Which animation plays and how fast comes from the equipped weapon.


var hero: Hero = null

var _time_until_impact: float = 0.0
var _has_landed: bool = false
var _is_finished: bool = false


## Picks one of the weapon attack animations and starts the swing.
func enter() -> void:
	hero = context
	_has_landed = false
	_is_finished = false

	var weapon: WeaponData = hero.equipped_weapon
	# Picked here and not mid swing, so the hero commits to the pose they aimed with.
	var animation_name: String = ""
	if weapon:
		animation_name = weapon.get_attack_animation(hero.camera_pivot.is_looking_up())

	# Nothing to play means nothing to wait for, so the state ends next frame.
	if animation_name.is_empty():
		_is_finished = true
		return

	hero.play_animation(animation_name, false, 0.1, weapon.attack_speed)

	_time_until_impact = _impact_time(animation_name, weapon)

	# CONNECT_ONE_SHOT drops itself, so an old swing never ends a later one.
	hero.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Drops the connection when the swing is cut short, so the next one is free.
func exit() -> void:
	var finished: Signal = hero.animation_player.animation_finished
	if finished.is_connected(_on_animation_finished):
		finished.disconnect(_on_animation_finished)


## Holds the hero in place until the swing ends.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	hero.stand_still(delta)
	# Turns to the camera, so the blow lands where the player is looking.
	hero.face_mesh_direction(hero.camera_yaw, delta)

	# A hit mid swing cuts the attack short, so trading blows is never free.
	var interrupt: State = hero.consume_interrupt_state()
	if interrupt:
		return interrupt

	_advance_swing(delta)

	# Idle sends the hero back to walking on its own if a direction is held.
	if _is_finished:
		return hero.idle_state

	return null


## How long into the swing the blow should land, in seconds.
func _impact_time(animation_name: String, weapon: WeaponData) -> float:
	var length: float = 0.0
	if hero.animation_player.has_animation(animation_name):
		length = hero.animation_player.get_animation(animation_name).length

	# Divided by the speed, since a faster animation reaches the frame sooner.
	return (length * weapon.impact_ratio) / weapon.attack_speed


## Counts the swing down and resolves the attack at the end of it.
func _advance_swing(delta: float) -> void:
	if _has_landed: return

	_time_until_impact -= delta
	if _time_until_impact > 0.0: return

	_has_landed = true
	_resolve_attack()


## Fires the shot for a ranged weapon, or reaches whatever a melee one covers.
func _resolve_attack() -> void:
	if hero.equipped_weapon.projectile:
		hero.fire_shot()
		return

	hero.hit_enemies_in_swing()


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
