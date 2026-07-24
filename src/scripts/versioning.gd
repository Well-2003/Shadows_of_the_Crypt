@tool
class_name Versioning
extends Node
## Static class used for versioning information.
## 
## This class holds and manages the game's version information,
## which can be accessed globally.
## It should ALWAYS be updated every commit, or at the end of a PR.


## Game version information.
## Major is release. 1.00.000 means total release. Game is finished,
## but of course can be further updated.
##
## Minor is beta - when major is 0 - or just minor update when major is 1 or more.
## 0.01.000 means first beta.
##
## Build is the build number. 0.00.001 means first build.
## Each build is a pull request or separate commit.
static var game_version: Dictionary = {
	"major": "0",
	"minor": "0",
	"build": "001",
	"label": "alpha"
}
## Human readable game version string.
static var game_version_string: String = ""


## This reagion defines the game version, according to [member game_version],
## then applies it to the [member label_version].
static func init_game_version() -> void:
	# Sets game version
	for key: String in game_version.keys():
		if (key != "major") and (key != "label"):
			game_version_string += "."
		if key == "label":
			game_version_string += "-"
		game_version_string += game_version[key]
	
	ProjectSettings.set_setting("application/config/version", game_version_string)
