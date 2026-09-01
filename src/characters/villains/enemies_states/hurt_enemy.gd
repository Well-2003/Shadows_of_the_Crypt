class_name HurtEnemy
extends State
## Hurt state: the brief stagger after the enemy takes a hit.
##
## Heavy enemies are meant to shrug this off, so whether it is entered at all
## depends on the enemy taking the damage.


## Plays the flinch and the damage feedback.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Holds the enemy still until the flinch is over, every physics frame.
func physics_update() -> State:
	return null
