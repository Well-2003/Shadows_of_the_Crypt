@tool
class_name RNG
extends RefCounted
## Static class providing random number generation utilities.
## 
## This class will handle anything random-related in the game.


static var rng := RandomNumberGenerator.new()


## Randomizes the internal random number generator.
static func randomize() -> void:
	rng.randomize()


## Sets the seed for the internal random number generator.
static func set_seed(seed_value: int) -> void:
	rng.seed = seed_value


## Returns a random integer.
static func randi() -> int:
	return rng.randi()


## Returns a random float in the range: 0.0 - 1.0.
static func randf() -> float:
	return rng.randf()


## Returns a random integer in the range [param from] - [param to].
static func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)


## Returns a random float in the range [param from] - [param to].
static func randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)


## Picks a random element from the given [param array].
static func pick_random(array: Array):
	if array.is_empty(): return null
	
	return array[rng.randi_range(0, array.size() - 1)]


## Shuffles the given [param array].
static func shuffle(array: Array) -> void:
	for index: int in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, index)
		var temp: int = array[index]
		array[index] = array[j]
		array[j] = temp
