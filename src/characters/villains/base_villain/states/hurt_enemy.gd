class_name HurtEnemy
extends State
## Hurt state: the brief stagger after the enemy takes a hit.
##
## Heavy classes shrug this off, so whether it is entered at all depends on the
## enemy taking the damage. The blink is separate, and happens on every hit.


## Flinch animations, one is picked per hit.
const HURT_ANIMATIONS: Array[String] = [
	"general/Hit_A",
	"general/Hit_B"
]

var enemy: BaseEnemy = null
var _is_finished: bool = false


## Plays the flinch.
func enter() -> void:
	enemy = context
	_is_finished = false

	enemy.play_animation(HURT_ANIMATIONS.pick_random(), false, 0.1)

	# CONNECT_ONE_SHOT drops itself, so an old flinch never ends a later one.
	enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Drops the connection when the flinch is cut short, so the next one is free.
func exit() -> void:
	var finished: Signal = enemy.animation_player.animation_finished
	if finished.is_connected(_on_animation_finished):
		finished.disconnect(_on_animation_finished)


## Holds the enemy still until the flinch is over, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	enemy.stand_still(delta)

	if enemy.health_pool.is_depleted():
		return enemy.death_state

	# Whatever hit the enemy is worth chasing, so the flinch feeds the fight.
	if _is_finished:
		return enemy.chase_state

	return null


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
