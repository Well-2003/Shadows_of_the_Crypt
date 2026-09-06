class_name PlayerIdleState
extends State
## Idle state: keeps the idle animation playing and zeroes horizontal velocity.
##
## Does not touch the direction the model faces, that is only touched by
## PlayerWalkState, so the character keeps looking where it last walked.


var hero: Hero = null


func enter() -> void:
	hero = context
	hero.play_animation("general/Idle_A", true)


func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	hero.stand_still(delta)

	var interrupt: State = hero.consume_interrupt_state()
	if interrupt:
		return interrupt

	if Input.is_action_just_pressed("jump") and hero.is_on_floor():
		return hero.jump_state

	if Input.is_action_just_pressed("attack"):
		return hero.attack_state

	if Input.is_action_pressed("aim"):
		if hero.can_aim(): return hero.aim_state
		if hero.can_block(): return hero.block_state

	# face_mesh_direction is skipped on purpose, to keep the last facing.
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input_dir != Vector2.ZERO:
		return hero.walk_state

	return null
