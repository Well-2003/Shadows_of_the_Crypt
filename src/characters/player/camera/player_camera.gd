class_name PlayerCamera
extends Node3D
## Over-the-shoulder camera pivot that orbits the Hero via the mouse.
##
## Node3D.rotation's Y (yaw) is set directly by the Hero; X (pitch)
## is controlled by apply_pitch. The over-the-shoulder position comes from
## the local transform of the child Camera3D node.


@export var pitch_min_degrees: float = -40.0
@export var pitch_max_degrees: float = 60.0

@onready var camera: Camera3D = $Camera3D


## Forces this camera to stay active, without depending on node entry order.
func _ready() -> void:
	camera.make_current()


## Turns the camera up/down gradually, without letting it exceed the set limits.
func apply_pitch(delta_pitch: float) -> void:
	var new_pitch: float = rotation.x + delta_pitch
	var min_pitch: float = deg_to_rad(pitch_min_degrees)
	var max_pitch: float = deg_to_rad(pitch_max_degrees)

	rotation.x = clampf(new_pitch, min_pitch, max_pitch)
