class_name PlayerAimState
extends State
## Aim state: held with the right mouse button by the classes that fire a shot.
##
## The hero plants their feet and faces the camera, so the shot stays lined up
## with the crosshair. The view zooms in for as long as the button is held.


var hero: Hero = null

var _is_aiming_up: bool = false


## Zooms the view in, shows the crosshair and draws the weapon.
func enter() -> void:
	hero = context
	_is_aiming_up = hero.camera_pivot.is_looking_up()

	_play_aim_pose()
	hero.camera_pivot.set_aiming(true)
	hero.hud.set_crosshair_visible(true)


## Puts the view and the crosshair back the way they were.
func exit() -> void:
	hero.camera_pivot.set_aiming(false)
	hero.hud.set_crosshair_visible(false)


## Keeps the hero planted while the button is held, and lets them shoot.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	var interrupt: State = hero.consume_interrupt_state()
	if interrupt:
		return interrupt

	if not Input.is_action_pressed("aim"):
		return hero.idle_state

	if Input.is_action_just_pressed("attack"):
		return hero.attack_state

	_update_aim_pose()

	hero.stand_still(delta)
	# Faces the camera so the weapon points wherever the crosshair does.
	hero.face_mesh_direction(hero.camera_yaw, delta)

	return null


## Swaps the pose the moment the aim crosses the steep angle, and back down again.
func _update_aim_pose() -> void:
	var looking_up: bool = hero.camera_pivot.is_looking_up()
	if looking_up == _is_aiming_up: return

	_is_aiming_up = looking_up
	_play_aim_pose()


## Draws the weapon in whichever pose matches where the hero is pointing.
func _play_aim_pose() -> void:
	# Played once, so it stops on the last frame and holds the drawn pose.
	hero.play_animation(hero.equipped_weapon.get_idle_animation(_is_aiming_up), false)
