class_name DeathEnemy
extends State
## Death state: plays the death animation and clears the enemy away.
##
## Terminal, nothing transitions out of it. The enemy is only freed after the
## animation has played, so the kill reads on screen.


## Stops the enemy and starts the death animation.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Waits for the animation to finish before the enemy is freed.
func physics_update() -> State:
	return null
