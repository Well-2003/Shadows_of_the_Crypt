class_name PatrolEnemy
extends State
## Patrol state: walks the enemy along its route while nothing is in sight.
##
## Hands over to a chase the moment the player is spotted, which is what turns a
## quiet room into a fight.


## How close the enemy has to get before the point counts as reached.
const ARRIVAL_DISTANCE: float = 0.5
## Longest one leg may take before the enemy gives up and picks another point.
const MAX_LEG_TIME: float = 8.0

var enemy: BaseEnemy = null
var _destination: Vector3 = Vector3.ZERO
var _time_left: float = 0.0


## Starts walking towards the next point on the route.
func enter() -> void:
	enemy = context
	_destination = enemy.pick_patrol_point()
	_time_left = MAX_LEG_TIME

	enemy.play_animation("special/Skeletons_Walking", true)


## Follows the route and watches for the player, every physics frame.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	var interrupt: State = enemy.consume_interrupt_state()
	if interrupt:
		return interrupt

	var distance: float = enemy.get_distance_to_player()
	if enemy.can_see_player(distance):
		return enemy.chase_state

	enemy.move_towards(_destination, enemy.villain_data.move_speed, delta)
	enemy.face_position(_destination, delta)

	# Given up on time too, otherwise a wall in the way is pushed into forever.
	_time_left -= delta
	if _time_left <= 0.0:
		return enemy.idle_state

	if _has_arrived():
		return enemy.idle_state

	return null


## True once the enemy is standing on the point it was walking to.
func _has_arrived() -> bool:
	var offset: Vector3 = _destination - enemy.global_position
	# Height dropped, so a ramp can never keep the leg from finishing.
	offset.y = 0.0

	return offset.length() <= ARRIVAL_DISTANCE
