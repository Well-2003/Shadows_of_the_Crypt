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


## Plays the flinch.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Holds the hero in place until the flinch is over, every physics frame.
func physics_update() -> State:
	return null
