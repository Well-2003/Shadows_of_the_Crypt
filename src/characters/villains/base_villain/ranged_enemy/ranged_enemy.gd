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


## Stops chasing at the ideal range, so the enemy settles into its shooting band.
func is_player_in_attack_range(distance: float) -> bool:
	return distance <= villain_data.ideal_range


## Sends this class's projectile flying at the player.
func fire_shot() -> void:
	if not villain_data.projectile: return

	var origin: Vector3 = get_muzzle_position()
	var direction: Vector3 = get_aim_direction(origin)

	# No direction means there is nobody left to shoot at.
	if direction == Vector3.ZERO: return

	Projectile.spawn(villain_data.projectile, villain_data.attack_damage, self, origin, direction)
