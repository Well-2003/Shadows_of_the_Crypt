class_name AttackMeleeEnemy
extends State
## Melee attack state: swings at the player from close range.
##
## The swing is telegraphed before it lands, so the player has a window to
## read it and step away.


## Starts the telegraph and then the swing.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Holds the enemy in place through the swing, every physics frame.
func physics_update() -> State:
	return null
