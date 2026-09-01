class_name PlayerDeathState
extends State
## Death state: plays the death animation and takes control away for good.
##
## Terminal, nothing transitions out of it. The hero stays where they fell
## until the Game Over screen takes over.


## Death animations, one is picked per run.
const DEATH_ANIMATIONS: Array[String] = [
	"general/Death_A",
	"general/Death_B"
]


## Drops the hero and starts the death animation.
func enter() -> void:
	pass


## Cleans up anything this state left running.
func exit() -> void:
	pass


## Keeps the body where it fell; no input is read from here on.
func physics_update() -> State:
	return null
