class_name PlayerBlockState
extends State
## Block state: held with the right mouse button by classes carrying a shield.
##
## The hero plants their feet behind the shield and faces the camera, so the
## shield always covers whatever is in front of them.


## Animation played when the shield catches a hit.
const BLOCK_HIT_ANIMATION: String = "combat_melee/Melee_Block_Hit"

var hero: Hero = null
var _is_taking_hit: bool = false


## Raises the shield and marks the hero as blocking.
func enter() -> void:
	hero = context
	_is_taking_hit = false

	var shield: ShieldData = hero.off_hand_item

	hero.is_blocking = true
	hero.play_animation(shield.idle_animation, true)


## Clears the flag, so a hit landing after this frame is not reduced.
func exit() -> void:
	hero.is_blocking = false

	var finished: Signal = hero.animation_player.animation_finished
	if finished.is_connected(_on_hit_finished):
		finished.disconnect(_on_hit_finished)


## Holds the guard while the button is held.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	# Only a hit the shield missed gets here, a blocked one raises no stagger.
	var interrupt: State = hero.consume_interrupt_state()
	if interrupt:
		return interrupt

	if not Input.is_action_pressed("aim"):
		return hero.idle_state

	# A hit the shield caught raises no stagger, so the shove is shown here instead.
	if hero.consume_block_hit():
		_play_block_hit()

	hero.stand_still(delta)
	# The shield covers a cone in front, so the hero always faces the camera.
	hero.face_mesh_direction(hero.camera_yaw, delta)

	return null


## Plays the shield taking the blow, once per hit.
func _play_block_hit() -> void:
	if _is_taking_hit: return

	_is_taking_hit = true
	hero.play_animation(BLOCK_HIT_ANIMATION, false, 0.05)

	# CONNECT_ONE_SHOT drops itself, so an old shove never ends a later one.
	hero.animation_player.animation_finished.connect(_on_hit_finished, CONNECT_ONE_SHOT)


func _on_hit_finished(_animation_name: StringName) -> void:
	_is_taking_hit = false
	hero.play_animation(hero.off_hand_item.idle_animation, true)
