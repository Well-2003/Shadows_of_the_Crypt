class_name HUD
extends CanvasLayer
## The scene responsible for displaying information to the player


@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %ExperienceBar


## Function called by the Player to insert the data
func set_health(current: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = current
