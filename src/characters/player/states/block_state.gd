class_name PlayerBlockState
extends State
## Block state: held with the right mouse button by classes carrying a shield.
##
## The hero plants their feet behind the shield and faces the camera, so the
## shield always covers whatever is in front of them.


var hero: Hero = null


## Raises the shield and marks the hero as blocking.
func enter() -> void:
	hero = context
	var shield: ShieldData = hero.off_hand_item

	hero.is_blocking = true
	hero.play_animation(shield.idle_animation, true)


## Clears the flag, so a hit landing after this frame is not reduced.
func exit() -> void:
	hero.is_blocking = false


## Holds the guard while the button is held.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	if not Input.is_action_pressed("aim"):
		return hero.idle_state

	hero.stand_still(delta)
	# The shield only covers a cone in front, so the hero always faces the camera.
	hero.face_mesh_direction(hero.camera_yaw, delta)

	return null
