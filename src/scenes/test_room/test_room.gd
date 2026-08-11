extends Node3D
## Test level. Registers itself with GameManager and starts the game.


func _ready() -> void:
	GameManager.current_scene = self
	GameManager.start_game()
