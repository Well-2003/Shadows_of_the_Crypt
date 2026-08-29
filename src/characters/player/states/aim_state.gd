class_name PlayerAimState
extends State
## Aim state: held with the right mouse button by bow and crossbow classes.
##
## The hero plants their feet and faces the camera, so the shot stays lined up
## with the crosshair. The view zooms in for as long as the button is held.


var hero: Hero = null


## Zooms the view in, shows the crosshair and draws the weapon.
func enter() -> void:
	hero = context

	# Plays once instead of looping, the draw runs to its last frame and holds
	# there, which is the pose of a bow already pulled back and ready.
	hero.play_animation(hero.equipped_weapon.idle_animation, false)
	hero.camera_pivot.set_aiming(true)
	hero.hud.set_crosshair_visible(true)


## Puts the view and the crosshair back the way they were.
func exit() -> void:

	hero.camera_pivot.set_aiming(false)
	hero.hud.set_crosshair_visible(false)


## Keeps the hero planted while the button is held, and lets them shoot.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	if not Input.is_action_pressed("aim"):
		return hero.idle_state

	if Input.is_action_just_pressed("attack"):
		return hero.attack_state

	hero.stand_still(delta)
	# Faces the camera so the weapon points wherever the crosshair does.
	hero.face_mesh_direction(hero.camera_yaw, delta)

	return null
