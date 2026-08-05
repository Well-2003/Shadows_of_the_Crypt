extends Node
## Autoload that stores the chosen class and takes the player into gameplay.
##
## Kept separate from the selection screen so it survives the scene change
## (autoloads aren't destroyed by SceneTree.change_scene_to_file).


## Scene loaded by start_game; fixed because there's only one game room for now.
const GAMEPLAY_SCENE: String = "res://scenes/test_room/test_room.tscn"

var selected_hero: HeroClassData = null


## Just stores the choice; the scene change itself happens in start_game.
func select_hero(hero_data: HeroClassData) -> void:
	selected_hero = hero_data


## Switches to the gameplay scene and applies selected_hero once the Hero exists.
func start_game() -> void:
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)

	# change_scene_to_file() is deferred, so wait for the Hero to join the "Player" group.
	var player: Hero = null
	var attempts: int = 0
	while not player and attempts < 30:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("Player")
		attempts += 1

	if player:
		player.hero_data = selected_hero
