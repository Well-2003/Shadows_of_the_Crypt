class_name WeaponIcon
extends SubViewportContainer
## A small live render of a weapon's model, used as its icon in the hotbar.
##
## The thumbnail the inspector shows is an editor feature, so the icon is
## rendered at runtime instead: the weapon scene goes into a tiny viewport with
## its own light, framed by its own bounding box and drawn a single time.


## How much room is left around the model, 1.2 leaving a fifth of the frame free.
const PADDING: float = 1.2
## How far the camera sits from the model. Any distance works with no perspective.
const CAMERA_DISTANCE: float = 4.0
## Fallback frame size for a model that reports no bounds at all.
const FALLBACK_SIZE: float = 1.0

var _viewport: SubViewport = null
var _holder: Node3D = null
var _camera: Camera3D = null
var _model: Node3D = null


## Builds the viewport, its camera and its light, all empty until an item arrives.
func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_viewport = SubViewport.new()
	# Its own world, or this viewport would draw the whole level behind the weapon.
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	# Nothing to draw yet, and drawing every frame would cost five renders a frame.
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)

	_holder = Node3D.new()
	_viewport.add_child(_holder)

	_camera = Camera3D.new()
	# Orthogonal, so a weapon does not get wider at the end nearest the camera.
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.near = 0.01
	_camera.far = CAMERA_DISTANCE * 2.0
	_viewport.add_child(_camera)

	_add_lighting()


## Puts one weapon in the frame, or clears it when the slot holds nothing.
func show_item(item: WeaponData) -> void:
	if is_instance_valid(_model):
		_model.queue_free()
		_model = null

	if not item or not item.world_model:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		visible = false
		return

	visible = true

	_model = item.world_model.instantiate()
	_holder.add_child(_model)
	# The pose is per weapon, the same way the grip values are, since each model
	# is built facing its own way.
	_model.rotation_degrees = item.icon_rotation

	_frame_model()

	# Drawn once and then left alone: the icon only changes when the item does.
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Points the camera at the model and pulls back far enough to hold all of it.
func _frame_model() -> void:
	var bounds: AABB = _model_bounds()
	var center: Vector3 = bounds.get_center()

	# The widest side decides the frame, so a long weapon is not cut off.
	var widest: float = maxf(bounds.size.x, bounds.size.y)
	if widest <= 0.0:
		widest = FALLBACK_SIZE

	_camera.size = widest * PADDING
	_camera.position = center + Vector3(0.0, 0.0, CAMERA_DISTANCE)
	_camera.look_at(center, Vector3.UP)


## The box the model fills, measured in the holder's space.
func _model_bounds() -> AABB:
	var bounds: AABB = AABB()
	var has_any: bool = false

	# owned = false because the model comes from an instantiated scene at runtime.
	for mesh: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		var to_holder: Transform3D = _holder.global_transform.affine_inverse() \
			* mesh.global_transform
		var mesh_box: AABB = to_holder * mesh.get_aabb()

		if not has_any:
			bounds = mesh_box
			has_any = true
			continue

		bounds = bounds.merge(mesh_box)

	return bounds


## A key light and a flat ambient, so no face of the model comes out black.
func _add_lighting() -> void:
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30.0, -40.0, 0.0)
	# No shadow, since nothing else is in this world for the weapon to fall on.
	light.shadow_enabled = false
	_viewport.add_child(light)

	var settings: Environment = Environment.new()
	# Clear colour and not a sky, which is what lets transparent_bg show through.
	settings.background_mode = Environment.BG_CLEAR_COLOR
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.75, 0.75, 0.8)
	settings.ambient_light_energy = 1.0

	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = settings
	_viewport.add_child(world)
