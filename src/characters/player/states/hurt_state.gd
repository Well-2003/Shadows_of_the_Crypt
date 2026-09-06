class_name PlayerHurtState
extends State
## Hurt state: the short stagger after the hero takes a hit.
##
## Holds the hero still for the length of the flinch, which is what makes a hit
## cost the player something beyond the health bar.


## Flinch animations, one is picked per hit.
const HURT_ANIMATIONS: Array[String] = [
	"general/Hit_A",
	"general/Hit_B"
]

var hero: Hero = null
var _is_finished: bool = false


## Plays the flinch.
func enter() -> void:
	hero = context
	_is_finished = false

	hero.play_animation(HURT_ANIMATIONS.pick_random(), false, 0.1)

	# CONNECT_ONE_SHOT drops itself, so an old flinch never ends a later one.
	hero.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Drops the connection when the flinch is cut short, so the next one is free.
func exit() -> void:
	var finished: Signal = hero.animation_player.animation_finished
	if finished.is_connected(_on_animation_finished):
		finished.disconnect(_on_animation_finished)


## Holds the hero in place until the flinch is over, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	hero.stand_still(delta)

	if hero.is_dead():
		return hero.death_state

	# Idle sends the hero back to walking on its own if a direction is held.
	if _is_finished:
		return hero.idle_state

	return null


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
