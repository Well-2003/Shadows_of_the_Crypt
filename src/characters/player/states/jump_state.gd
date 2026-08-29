class_name PlayerJumpState
extends State
## Jump state, entered with the jump button, lasts until the hero lands again.
##
## Runs a single jump animation, but freezes it halfway while the hero is still
## rising and lets it finish on the way down, so the pose follows the arc
## instead of racing ahead of it.


## Upward speed given the moment the hero leaves the ground.
const JUMP_VELOCITY: float = 5.0
## Share of the normal move speed kept for steering in the air.
const AIR_CONTROL: float = 0.8
## How far into the animation the hero holds while rising, 0.5 being halfway.
const APEX_POSE_RATIO: float = 0.5

var hero: Hero = null
var _is_falling: bool = false
var _is_holding_apex: bool = false


## Pushes the hero off the ground and starts the jump animation.
func enter() -> void:
	hero = context
	_is_falling = false
	_is_holding_apex = false

	hero.velocity.y = JUMP_VELOCITY
	hero.play_animation("movement_basic/Jump_Full_Long")


## Makes sure the animation is never left frozen for the next state to inherit.
func exit() -> void:
	_resume_animation()


## Steers through the air, drives the animation and ends the state on landing.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	hero.move_relative_to_camera(input_dir, AIR_CONTROL, delta)

	# Mid-air the hero turns with the mouse instead of standing still while the camera swings around them.
	hero.face_mesh_direction(hero.camera_yaw, delta)

	if hero.velocity.y < 0.0:
		_is_falling = true

	if not _is_falling:
		_hold_apex_pose()
		return null

	_resume_animation()

	if hero.is_on_floor():
		return hero.idle_state

	return null


## Freezes the animation once it reaches the apex pose, and keeps it there.
func _hold_apex_pose() -> void:
	if _is_holding_apex: return

	var animation_player: AnimationPlayer = hero.animation_player
	var apex_time: float = animation_player.current_animation_length * APEX_POSE_RATIO

	if animation_player.current_animation_position < apex_time: return

	animation_player.pause()
	_is_holding_apex = true


## Lets the animation carry on from where it was frozen.
func _resume_animation() -> void:
	if not _is_holding_apex: return

	hero.animation_player.play()
	_is_holding_apex = false
