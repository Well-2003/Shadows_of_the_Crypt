extends Node
## Autoload that stores the chosen class and drives the scene changes of a run.
##
## Kept separate from the selection screen so it survives the change, since
## autoloads are not destroyed by SceneTree.change_scene_to_file.


## Scene loaded by load_gameplay_scene; fixed because there's only one game room for now.
const GAMEPLAY_SCENE: String = "res://scenes/test_room/test_room.tscn"
## Screen the run starts on, and the one it goes back to when the hero dies.
const CHARACTER_SELECT_SCENE: String = "res://ui/character_select/character_select.tscn"

var selected_hero: HeroClassData = null
var current_scene: Node = null


## Just stores the choice; the scene change itself happens in load_gameplay_scene.
func select_hero(hero_data: HeroClassData) -> void:
	selected_hero = hero_data


## Switches to the gameplay scene, which then calls start_game once it's ready.
func load_gameplay_scene() -> void:
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)


## Applies the chosen class. Called by the level scene, so the Hero already exists.
func start_game() -> void:
	if not selected_hero: return

	Hero.player.hero_data = selected_hero


## Ends the run and goes back to the class selection.
func return_to_character_select() -> void:
	# The choice goes with the run, so the next game starts at the selection.
	selected_hero = null
	current_scene = null

	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
