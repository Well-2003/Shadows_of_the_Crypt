class_name PlayerCamera
extends Node3D
## Over-the-shoulder camera pivot that orbits the Hero via the mouse.
##
## The Hero sets the yaw directly, apply_pitch handles the pitch, and the
## shoulder offset comes from the local transform of the child Camera3D.


## How far the crosshair looks for something to aim at.
const AIM_DISTANCE: float = 60.0
## What the aim may land on: walls and enemies, never the hero firing the shot.
const AIM_LAYERS: int = Projectile.LAYER_WORLD + Projectile.LAYER_ENEMY

## How far down the camera can look.
@export var pitch_min_degrees: float = -40.0
## How far up the camera can look.
@export var pitch_max_degrees: float = 60.0

@export_group("Zoom")
## Field of view while walking around, and at the far end of the aim.
@export var default_fov: float = 75.0
## Field of view at the near end of the aim, lower than the default to zoom in.
@export var aim_fov: float = 55.0
## How fast the view slides from one zoom to the next, higher is snappier.
@export var zoom_speed: float = 10.0
## How much of the way between the two ends one notch of the wheel covers.
@export var zoom_step: float = 0.15
## Angle above which a ranged weapon swaps to its raised pose.
@export var up_pose_angle_degrees: float = 30.0

var _aim_zoom: float = 1.0
var _is_aiming: bool = false

@onready var camera: Camera3D = $Camera3D


## Forces this camera to stay active, without depending on node entry order.
func _ready() -> void:
	camera.make_current()
	camera.fov = default_fov


## Eases the view towards where the aim wants it, so the zoom is never a jump.
func _process(delta: float) -> void:
	# Zero while the aim is down, which restores the normal view on release.
	var zoom: float = 0.0
	if _is_aiming:
		zoom = _aim_zoom

	# Only the lens closes. The camera stays at the spot it was placed at in the scene.
	var target_fov: float = lerpf(default_fov, aim_fov, zoom)

	camera.fov = lerpf(camera.fov, target_fov, zoom_speed * delta)


## Raises and lowers the aim, leaving the zoom level the player picked untouched.
func set_aiming(aiming: bool) -> void:
	_is_aiming = aiming


## Zooms the aim in or back out, one wheel notch at a time, positive zooming in.
func apply_zoom(steps: float) -> void:
	# Nothing to zoom with the aim down: outside the aim the view is always the plain one.
	if not _is_aiming: return

	_aim_zoom = clampf(_aim_zoom + steps * zoom_step, 0.0, 1.0)


## Direction from a point in the world towards whatever the crosshair covers.
func get_aim_direction(from_position: Vector3) -> Vector3:
	# Aimed at the spot itself, to compensate the shoulder offset of the camera.
	return (get_aim_point() - from_position).normalized()


## The spot the crosshair covers, or a far point when it is covering only air.
func get_aim_point() -> Vector3:
	var ray_start: Vector3 = camera.global_position
	# The crosshair is screen centre, so the ray is the camera line of sight.
	var ray_end: Vector3 = ray_start - camera.global_basis.z * AIM_DISTANCE

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = AIM_LAYERS

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ray_end

	return hit["position"]


## True while the hero points steeply up, where a level pose would look wrong.
func is_looking_up() -> bool:
	# Pitch grows going up, since apply_pitch flips the mouse's own direction.
	return rotation.x >= deg_to_rad(up_pose_angle_degrees)


## Turns the camera up/down gradually, without letting it exceed the set limits.
func apply_pitch(delta_pitch: float) -> void:
	var new_pitch: float = rotation.x + delta_pitch
	var min_pitch: float = deg_to_rad(pitch_min_degrees)
	var max_pitch: float = deg_to_rad(pitch_max_degrees)

	rotation.x = clampf(new_pitch, min_pitch, max_pitch)
