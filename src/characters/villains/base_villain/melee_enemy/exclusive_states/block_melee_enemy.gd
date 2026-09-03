class_name BlockMeleeEnemy
extends State
## Block state: the enemy raises its shield and waits behind it.
##
## Only enemies carrying a shield use this, as a breather between swings.


## Raises the shield and marks the enemy as guarding.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Holds the guard, every physics frame.
func physics_update() -> State:
	return null
