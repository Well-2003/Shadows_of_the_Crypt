class_name HUD
extends CanvasLayer
## The scene responsible for displaying information to the player


@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %ExperienceBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
