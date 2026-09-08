class_name PlayerDeathState
extends State
## Death state: plays the death animation and takes control away for good.
##
## Terminal, nothing transitions out of it. After a short delay the run ends and
## the class selection comes back.


## Death animations, one is picked per run.
const DEATH_ANIMATIONS: Array[String] = [
	"general/Death_A",
	"general/Death_B"
]

## How long the body stays on screen before the class selection takes over.
const RETURN_DELAY: float = 2.5

var hero: Hero = null
var _time_left: float = 0.0
var _has_returned: bool = false


## Drops the hero and starts the death animation.
func enter() -> void:
	hero = context
	_time_left = RETURN_DELAY
	_has_returned = false

	# The mouse is captured in gameplay, and the selection screen needs it back.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hero.hud.set_crosshair_visible(false)

	hero.play_animation(DEATH_ANIMATIONS.pick_random(), false, 0.1)


## Keeps the body where it fell, no input is read from here on.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	hero.stand_still(delta)

	# The scene change lands at the end of the frame, so this runs a few more times.
	if _has_returned:
		return null

	_time_left -= delta
	if _time_left > 0.0:
		return null

	_has_returned = true
	GameManager.return_to_character_select()

	return null
