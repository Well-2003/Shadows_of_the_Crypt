class_name PlayerIdleState
extends State
## Idle state: keeps the idle animation playing and zeroes horizontal velocity.
##
## Doesn't touch the direction the model faces — that's only touched by
## PlayerWalkState, so the character keeps looking at the last direction it walked.


func enter() -> void:
	context.play_animation("general/Idle_A", true)


func physics_update() -> State:
	var hero : Hero = context
	var delta: float = get_physics_process_delta_time()

	hero.stand_still(delta)

	if Input.is_action_just_pressed("attack"):
		return hero.attack_state

	if Input.is_action_pressed("aim"):
		if hero.can_aim(): return hero.aim_state
		if hero.can_block(): return hero.block_state

	# Doesn't call face_mesh_direction here on purpose: keeps the last direction faced.
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input_dir != Vector2.ZERO:
		return hero.walk_state

	return null
