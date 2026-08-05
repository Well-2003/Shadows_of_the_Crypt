class_name PlayerWalkState
extends State
## Movement state: walks relative to the camera's turn and rotates the model
## to face the pressed direction (diagonals included).


## Plays the running animation on entering this state.
func enter() -> void:
	(context as Hero).play_animation("movement_basic/Running_B", true)


## Moves the Hero and turns the model to face the pressed direction, every physics frame.
func physics_update() -> State:
	var hero := context as Hero
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")

	if input_dir == Vector2.ZERO:
		return hero.idle_state

	var delta: float = get_physics_process_delta_time()

	if not hero.is_on_floor():
		hero.velocity.y -= hero.gravity * delta

	# Direction relative to the camera's turn, not the Hero (which no longer turns on its own).
	var yaw_basis: Basis = Basis(Vector3.UP, hero.camera_yaw)
	var direction: Vector3 = (yaw_basis.x * input_dir.x + yaw_basis.z * input_dir.y).normalized()

	hero.velocity.x = direction.x * hero.hero_data.move_speed
	hero.velocity.z = direction.z * hero.hero_data.move_speed
	hero.move_and_slide()

	var target_angle: float = hero.camera_yaw + deg_to_rad(_turn_angle_for(input_dir))
	hero.face_mesh_direction(target_angle, delta)

	return null


## Returns, in degrees, which way the character should turn based on the keys held down.
func _turn_angle_for(input_dir: Vector2) -> float:
	var pressing_forward: bool = input_dir.y < 0.0
	var pressing_backward: bool = input_dir.y > 0.0
	var pressing_right: bool = input_dir.x > 0.0
	var pressing_left: bool = input_dir.x < 0.0

	# 0° is the camera's forward direction. In Godot, turning right is a negative angle, and left is positive.
	if pressing_forward and pressing_right:
		return -45.0
	if pressing_forward and pressing_left:
		return 45.0
	if pressing_backward and pressing_right:
		return -135.0
	if pressing_backward and pressing_left:
		return 135.0
	if pressing_right:
		return -90.0
	if pressing_left:
		return 90.0
	if pressing_backward:
		return 180.0

	# Just "forward" (or no forward/backward/sideways key at all).
	return 0.0
