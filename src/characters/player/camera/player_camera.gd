class_name PlayerCamera
extends Node3D
## Over-the-shoulder camera pivot that orbits the Hero via the mouse.
##
## Node3D.rotation's Y (yaw) is set directly by the Hero, X (pitch)
## is controlled by apply_pitch. The over-the-shoulder position comes from
## the local transform of the child Camera3D node.


## How far down the camera can look.
@export var pitch_min_degrees: float = -40.0
## How far up the camera can look.
@export var pitch_max_degrees: float = 60.0

@export_group("Zoom")
## Field of view while walking around.
@export var default_fov: float = 75.0
## Field of view while aiming, lower than the default to zoom in.
@export var aim_fov: float = 55.0
## How fast the view zooms between the two, higher is snappier.
@export var zoom_speed: float = 10.0

var _target_fov: float = 75.0

@onready var camera: Camera3D = $Camera3D


## Forces this camera to stay active, without depending on node entry order.
func _ready() -> void:
	camera.make_current()
	camera.fov = default_fov
	_target_fov = default_fov


## Eases the view towards the target, so the zoom is never an instant jump.
func _process(delta: float) -> void:
	camera.fov = lerpf(camera.fov, _target_fov, zoom_speed * delta)


## Zooms in while aiming and back out when the aim is released.
func set_aiming(aiming: bool) -> void:
	_target_fov = aim_fov if aiming else default_fov


## Turns the camera up/down gradually, without letting it exceed the set limits.
func apply_pitch(delta_pitch: float) -> void:
	var new_pitch: float = rotation.x + delta_pitch
	var min_pitch: float = deg_to_rad(pitch_min_degrees)
	var max_pitch: float = deg_to_rad(pitch_max_degrees)

	rotation.x = clampf(new_pitch, min_pitch, max_pitch)
