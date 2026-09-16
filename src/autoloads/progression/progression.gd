extends Node
## Autoload that tracks the hero's level, experience and coins through a run.
##
## The curve is read from a JSON file so the numbers can be balanced without
## touching code. Kept out of Hero because the hero is destroyed on every scene
## change, and a run has to outlive that.


## The curve file, one entry per level with the experience it takes to leave it.
const LEVELS_PATH: String = "res://data/levels.json"

## Emitted whenever the experience or the level moves, for the HUD.
signal xp_changed(current_xp: int, xp_to_next: int, level: int)
## Emitted once per level gained, for the sound and the flash.
signal leveled_up(new_level: int)
## Emitted when a kill pays out, for the coin counter.
signal coins_changed(total_coins: int)

var level: int = 1
var xp: int = 0
var coins: int = 0

var _curve: Array[int] = []


## Reads the curve once and starts listening for the kills that pay for it.
func _ready() -> void:
	_load_curve()

	Signals.enemy_died.connect(_on_enemy_died)


## Highest level the curve describes, which is where the experience stops counting.
func get_max_level() -> int:
	return _curve.size()


## True once there is nothing left to level into.
func is_max_level() -> bool:
	return level >= get_max_level()


## Experience needed to leave the current level, 0 at the top of the curve.
func get_xp_to_next() -> int:
	if is_max_level(): return 0

	# The curve is a list, so level 1 lives at index 0.
	return _curve[level - 1]


## Adds experience and spends it on however many levels it covers.
func add_xp(amount: int) -> void:
	if amount <= 0: return
	if is_max_level(): return

	xp += amount

	# A loop and not a single check, since one big kill can cover two levels.
	while not is_max_level() and xp >= get_xp_to_next():
		xp -= get_xp_to_next()
		level += 1
		leveled_up.emit(level)

	# Nothing left to spend it on, so the bar sits full instead of half filled.
	if is_max_level():
		xp = 0

	xp_changed.emit(xp, get_xp_to_next(), level)


## Wipes the progress, called when a new run starts.
func reset() -> void:
	level = 1
	xp = 0
	coins = 0

	xp_changed.emit(xp, get_xp_to_next(), level)
	coins_changed.emit(coins)


## Fills the curve from the JSON file, leaving it empty when the file is unusable.
func _load_curve() -> void:
	_curve.clear()

	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Progression: level curve not found at " + LEVELS_PATH)
		return

	var text: String = FileAccess.get_file_as_string(LEVELS_PATH)
	var parsed: Variant = JSON.parse_string(text)

	# parse_string answers null on bad JSON instead of raising, so it is checked here.
	if not parsed is Dictionary or not parsed.has("levels"):
		push_error("Progression: level curve is not a JSON object with a levels list")
		return

	for entry: Dictionary in parsed["levels"]:
		_curve.append(int(entry["xp_to_next"]))


## Pays out the experience and the coins one dead enemy is worth.
func _on_enemy_died(villain_data: VillainClassData) -> void:
	if not villain_data: return

	coins += villain_data.roll_coin_drop()
	coins_changed.emit(coins)

	add_xp(villain_data.xp_reward)
