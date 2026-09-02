class_name AttackRangerEnemy
extends State
## Ranged attack state: fires at the player from a distance.
##
## The enemy plants its feet to shoot, which is the window the player has to
## close the gap.


## Aims at the player and starts the shot.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Keeps the enemy still while it fires, every physics frame.
func physics_update() -> State:
	return null
