class_name EscapeEnemy
extends State
## Escape state: backs away when the player gets too close.
##
## What keeps a ranged enemy at its ideal range instead of being cornered,
## and sends it back to shooting once the gap is open again.


## Turns the enemy away and starts retreating.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Backs off until the player is far enough again, every physics frame.
func physics_update() -> State:
	return null
