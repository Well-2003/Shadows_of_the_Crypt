@tool
class_name DamageFlash
extends Node
## Blinks a character red when it takes a hit.
##
## Holds a copy of every material on the body, because the models share theirs
## between bones and between instances: tinting one straight would turn every
## skeleton in the room red at once. The weapons are left alone.


## Colour the body turns at the peak of the blink.
@export var flash_color: Color = Color(1.0, 0.25, 0.25)
## How long the whole blink takes, turning red and coming back.
@export var flash_time: float = 0.18

var _materials: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []

var _tween: Tween = null


## Copies every material on the body, dropping any held for an older mesh.
func setup(body: Node3D) -> void:
	# The blink is a gameplay effect, so the editor keeps the shared materials.
	if Engine.is_editor_hint(): return

	stop()
	_materials.clear()
	_base_colors.clear()

	# owned = false because nodes built by script have no owner, and find_children skips those.
	for mesh: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		for surface: int in mesh.get_surface_override_material_count():
			_copy_material(mesh, surface)


## Blinks the body once.
func flash() -> void:
	if _materials.is_empty(): return

	# Restarts instead of stacking, so two hits don't leave the body stuck red.
	stop()

	var half_time: float = flash_time * 0.5

	_tween = create_tween()
	_tween.tween_method(_apply_tint, 0.0, 1.0, half_time)
	_tween.tween_method(_apply_tint, 1.0, 0.0, half_time)


## Cancels the blink and puts the body back to its own colours.
func stop() -> void:
	if _tween:
		_tween.kill()
		_tween = null

	_apply_tint(0.0)


## The copies this component made, for the fade an enemy goes through when it dies.
func get_materials() -> Array[StandardMaterial3D]:
	return _materials


## Swaps one surface for a copy of its material, and remembers both.
func _copy_material(mesh: MeshInstance3D, surface: int) -> void:
	var source: Material = mesh.get_active_material(surface)
	# Skips a surface with no material, and any that is not the kind we tint.
	if not (source is StandardMaterial3D): return

	var copy: StandardMaterial3D = source.duplicate()
	mesh.set_surface_override_material(surface, copy)

	_materials.append(copy)
	_base_colors.append(copy.albedo_color)


## Tints the body, where 0 is its normal colours and 1 is the peak of the blink.
func _apply_tint(amount: float) -> void:
	for index: int in _materials.size():
		_materials[index].albedo_color = _base_colors[index].lerp(flash_color, amount)
