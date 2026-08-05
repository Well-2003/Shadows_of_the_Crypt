class_name PlayerIdleState
extends State
## Idle state: keeps the idle animation playing and zeroes horizontal velocity.
##
## Doesn't touch the direction the model faces — that's only touched by
## PlayerWalkState, so the character keeps looking at the last direction it walked.


func enter() -> void:
	var hero := context as Hero
	hero.play_animation("general/Idle_A", true)


func physics_update() -> State:
	var hero := context as Hero
	var delta: float = get_physics_process_delta_time()

	if not hero.is_on_floor():
		hero.velocity.y -= hero.gravity * delta

	hero.velocity.x = 0.0
	hero.velocity.z = 0.0
	hero.move_and_slide()

	# Doesn't call face_mesh_direction here on purpose: keeps the last direction faced.
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input_dir != Vector2.ZERO:
		return hero.walk_state

	return null
