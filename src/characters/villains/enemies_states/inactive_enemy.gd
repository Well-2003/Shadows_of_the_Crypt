class_name InactiveEnemy
extends State
## Inactive state: the enemy stands dormant until something wakes it up.
##
## Enemies start here so a room full of skeletons costs nothing until the
## player actually walks in.


## Puts the enemy to sleep, with no animation playing.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Waits for the wake-up call, every physics frame.
func physics_update() -> State:
	return null
