@tool
class_name MeleeEnemy
extends BaseEnemy
## An enemy that closes the distance and fights in reach.
##
## Chases the player down and swings once in range. It has no reason to back
## away, so it never answers with a retreat state.


@onready var attack_state: State = $StateMachine/AttackState
@onready var block_state: State = $StateMachine/BlockState


## Swings whatever is in the enemy's hand.
func get_attack_state() -> State:
	return attack_state
