@tool
class_name RangedEnemy
extends BaseEnemy
## An enemy that closes to its ideal range and shoots from there.
##
## It still chases, but stops much earlier than a melee enemy and backs away
## when the player gets inside retreat_range.


@onready var attack_state: State = $StateMachine/AttackState
@onready var escape_state: State = $StateMachine/EscapeState


## Fires from wherever the enemy is standing.
func get_attack_state() -> State:
	return attack_state


## Backs off to open the gap again instead of trading blows up close.
func get_retreat_state() -> State:
	return escape_state


## Stops chasing at the ideal range rather than at melee reach, so the enemy
## settles into the band it wants to shoot from.
func is_player_in_attack_range(distance: float) -> bool:
	return distance <= villain_data.ideal_range
