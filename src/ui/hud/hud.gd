class_name HUD
extends CanvasLayer
## The scene responsible for displaying information to the player


@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %ExperienceBar
@onready var crosshair: Control = %Crosshair


## Function called by the Player to insert the data
func set_health(current: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


## Shows the crosshair while aiming and hides it the rest of the time.
func set_crosshair_visible(should_show: bool) -> void:
	crosshair.visible = should_show
