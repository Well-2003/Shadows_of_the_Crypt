extends Node
## Displays real-time overlay information during gameplay.
##
## This script manages the display of debug and gameplay information.


#region Properties
## Emitted when a tooltip should be shown or hidden.
@warning_ignore("unused_signal")
signal tooltip_requested(should_show: bool, node: Node, min_size: Vector2)

@export var show_game_version: bool = true: set = _set_show_game_version
@export var show_fps: bool = true: set = _set_show_fps
@export var show_advanced_fps: bool = false: set = _set_show_advanced_fps

var _overlay_visible: bool = true

@onready var adjustment: ColorRect = %Adjustment
@onready var fps_label: Label = %FPSLabel
@onready var version_label: Label = %VersionLabel
@onready var overlay_color: ColorRect = %OverlayColor
#endregion


func _ready() -> void:
	# Set default clear color to black to ensure "holes" in the world show black
	# This acts as the ultimate background if the Underground layer is missed for some reason,
	# but the Underground layer (Rect) allows for potential shader effects later.
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	version_label.text = "Ver.: %s" % Versioning.game_version_string

	_set_show_game_version(show_game_version)
	_update_overlay_visibility()


func _process(delta: float) -> void:
	FPSHelper.track_frame_time(delta)
	_update_fps_display()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle_overlay"):
		_overlay_visible = not _overlay_visible
		_update_overlay_visibility()
	
	if event.is_action_pressed(&"debug_close"):
		get_tree().quit()


## Updates the FPS label with the current frames per second.
func _update_fps_display() -> void:
	if not _overlay_visible or (not show_fps and not show_advanced_fps):
		return

	fps_label.text = FPSHelper.get_fps_string(show_advanced_fps)


## Setter for show_advanced_fps.
func _set_show_advanced_fps(value: bool) -> void:
	show_advanced_fps = value
	if show_advanced_fps:
		show_fps = false
	
	_update_overlay_visibility()


## Updates the visibility of all overlay labels.
func _update_overlay_visibility() -> void:
	fps_label.visible = _overlay_visible and (show_fps or show_advanced_fps)
	version_label.visible = _overlay_visible and show_game_version


#region Setters
func set_gamma(gamma: float) -> void:
	adjustment.material.set_shader_parameter("gamma", gamma)


func set_contratst(contrast: float) -> void:
	adjustment.material.set_shader_parameter("contrast", contrast)


func set_brightness(brightness: float) -> void:
	adjustment.material.set_shader_parameter("brightness", brightness)


## Setter for show_fps.
func _set_show_fps(value: bool) -> void:
	show_fps = value
	if show_fps:
		show_advanced_fps = false
	_update_overlay_visibility()


## Setter for show_game_version.
func _set_show_game_version(value: bool) -> void:
	show_game_version = value
	if value:
		version_label.text = "Ver.: %s" % Versioning.game_version_string
	_update_overlay_visibility()
#endregion
