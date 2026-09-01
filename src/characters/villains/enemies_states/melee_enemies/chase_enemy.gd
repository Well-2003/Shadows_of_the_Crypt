class_name ChaseEnemy
extends State
## Chase state: closes the distance until the player is within reach.
##
## Runs on the navigation mesh, so the enemy walks around walls instead of
## pushing into them.


## Starts running and points the agent at the player.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Follows the player and stops once in range, every physics frame.
func physics_update() -> State:
	return null
