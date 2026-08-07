class_name CharacterSelect
extends Node
## Character selection screen.
##
## Generates a button for each entry in class_entry and, when one is
## chosen, hands the class to GameManager and starts the game.


@export var class_entry: Array[HeroClassData] = []

@onready var entries_grid: GridContainer = $MarginContainer/VBoxContainer/EntriesGrid


func _ready() -> void:
	for hero_data: HeroClassData in class_entry:
		var button: Button = Button.new()
		# Display name comes straight from the enum, no need for an extra field.
		button.text = HeroClassData.HeroId.keys()[hero_data.id].capitalize()
		button.custom_minimum_size = Vector2(160, 48)
		# bind() copies this iteration's hero_data into the Callable, so each button calls the handler with the right class.
		button.pressed.connect(_on_hero_selected.bind(hero_data))
		entries_grid.add_child(button)


func _on_hero_selected(hero_data: HeroClassData) -> void:
	# GameManager changes the scene, so the selection screen doesn't navigate anything itself.
	GameManager.select_hero(hero_data)
	GameManager.load_gameplay_scene()
