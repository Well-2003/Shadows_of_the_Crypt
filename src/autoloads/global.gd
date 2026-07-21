@tool
extends Node
## Global variables and functions shared through all scenes and nodes.
## 
## Autoload for global game settings and variables, and functions.


func _ready() -> void:
	Versioning.init_game_version()
