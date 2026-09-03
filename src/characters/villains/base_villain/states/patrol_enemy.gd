class_name PatrolEnemy
extends State
## Patrol state: walks the enemy along its route while nothing is in sight.
##
## Hands over to a chase the moment the player is spotted, which is what turns
## a quiet room into a fight.


## Starts walking towards the next point on the route.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Follows the route and watches for the player, every physics frame.
func physics_update() -> State:
	return null
