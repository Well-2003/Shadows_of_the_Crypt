class_name HealthBar3D
extends Sprite3D
## Floating health bar that appears over a character when it gets hurt.
##
## The bar itself is the TextureProgressBar inside this scene's SubViewport, so
## its look comes from the textures set in the inspector. This script only feeds
## it the health, shows it, and fades it out once the character is left alone.


## How long the bar stays up after the last hit, in seconds.
@export var visible_time: float = 3.0
## How long it takes to fade out once that time is up.
@export var fade_time: float = 0.6

var _time_left: float = 0.0
var _tween: Tween = null

@onready var viewport: SubViewport = $SubViewport
@onready var progress_bar: TextureProgressBar = $SubViewport/ProgressBar


## Starts hidden, since nothing has been hurt yet.
func _ready() -> void:
	visible = false


## Counts down the bar's time on screen and starts the fade when it runs out.
func _process(delta: float) -> void:
	if not visible: return

	# A tween is already fading it out, so the countdown has done its job.
	if _tween and _tween.is_running(): return

	_time_left -= delta
	if _time_left <= 0.0:
		_start_fade()


## Shows the bar at the given health and restarts its time on screen.
func show_damage(current_value: int, max_value: int) -> void:
	if max_value <= 0: return

	if _tween:
		_tween.kill()

	progress_bar.max_value = max_value
	progress_bar.value = current_value

	# The viewport only draws when asked, so a new value needs one fresh frame.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	_time_left = visible_time
	modulate.a = 1.0
	visible = true


## Takes the bar off screen at once, for when the character is dead.
func hide_bar() -> void:
	if _tween:
		_tween.kill()

	visible = false


## Fades the bar out and leaves it hidden at the end.
func _start_fade() -> void:
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(hide_bar)
