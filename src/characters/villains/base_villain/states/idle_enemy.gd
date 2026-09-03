class_name IdleEnemy
extends State
## Idle state: the enemy holds its ground and watches for the player.
##
## Where an enemy waits between patrol legs, and where it lands after losing
## sight of its target.


## Plays the idle animation.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Watches for the player, every physics frame.
func physics_update() -> State:
	return null
