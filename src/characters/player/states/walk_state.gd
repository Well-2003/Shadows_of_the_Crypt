class_name PlayerWalkState
extends State
## Movement state: walks relative to the camera's turn and rotates the model
## to face the pressed direction (diagonals included).


# Angles the model faces, in degrees, where 0° is wherever the camera is pointing.
# Negative turns right and positive turns left, following how Godot rotates on the Y axis.
## W, runs away from the camera, showing the character's back.
const ANGLE_FORWARD: float = 0.0
## W and D, runs diagonally ahead, to the right.
const ANGLE_FORWARD_RIGHT: float = -45.0
## W and A, runs diagonally ahead, to the left.
const ANGLE_FORWARD_LEFT: float = 45.0
## D, runs to the right, seen from the side.
const ANGLE_RIGHT: float = -90.0
## A, runs to the left, seen from the side.
const ANGLE_LEFT: float = 90.0
## S and D, runs diagonally back, to the right.
const ANGLE_BACKWARD_RIGHT: float = -135.0
## S and A, runs diagonally back, to the left.
const ANGLE_BACKWARD_LEFT: float = 135.0
## S, runs toward the camera, showing the character's face.
const ANGLE_BACKWARD: float = 180.0


## Plays the running animation on entering this state.
func enter() -> void:
	context.play_animation("movement_basic/Running_B", true)


## Moves the Hero and turns the model to face the pressed direction, every physics frame.
func physics_update() -> State:
	var hero: Hero = context
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")

	if Input.is_action_just_pressed("attack"):
		return hero.attack_state

	if Input.is_action_pressed("aim"):
		if hero.can_aim(): return hero.aim_state
		if hero.can_block(): return hero.block_state

	if input_dir == Vector2.ZERO:
		return hero.idle_state

	var delta: float = get_physics_process_delta_time()
	hero.move_relative_to_camera(input_dir, 1.0, delta)

	var target_angle: float = hero.camera_yaw + deg_to_rad(_turn_angle_for(input_dir))
	hero.face_mesh_direction(target_angle, delta)

	return null


## Returns, in degrees, which way the character should turn based on the keys held down.
func _turn_angle_for(input_dir: Vector2) -> float:
	var pressing_forward: bool = input_dir.y < 0.0
	var pressing_backward: bool = input_dir.y > 0.0
	var pressing_right: bool = input_dir.x > 0.0
	var pressing_left: bool = input_dir.x < 0.0

	if pressing_forward and pressing_right:
		return ANGLE_FORWARD_RIGHT
	if pressing_forward and pressing_left:
		return ANGLE_FORWARD_LEFT
	if pressing_backward and pressing_right:
		return ANGLE_BACKWARD_RIGHT
	if pressing_backward and pressing_left:
		return ANGLE_BACKWARD_LEFT
	if pressing_right:
		return ANGLE_RIGHT
	if pressing_left:
		return ANGLE_LEFT
	if pressing_backward:
		return ANGLE_BACKWARD

	# Just "forward" (or no forward/backward/sideways key at all).
	return ANGLE_FORWARD
