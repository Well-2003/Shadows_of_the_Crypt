class_name Projectile
extends Area3D
## A shot in flight, shared by every arrow, bolt and orb in the game.
##
## Everything that changes from one shot to the next lives in ProjectileData, so
## a new kind of projectile is a resource and never a new scene.


## The scene every projectile is spawned from, by uid so moving the file is safe.
const SCENE_UID: String = "res://characters/projectile/projectile.tscn"

## Downward pull at gravity_scale 1.0, the same the characters fall with.
const GRAVITY: float = 9.8

var data: ProjectileData = null
var damage: float = 0.0
var shooter: Node3D = null

var velocity: Vector3 = Vector3.ZERO

var _time_left: float = 0.0
var _is_stuck: bool = false
var _materials: Array[StandardMaterial3D] = []

@onready var hit_shape: CollisionShape3D = $HitShape


## Puts one projectile in the level, already flying.
static func spawn(
	new_data: ProjectileData, 
	new_damage: float, 
	new_shooter: Node3D,
	from_position: Vector3, 
	direction: Vector3
	) -> Projectile:
		
	# load and not preload, or the scene would wait on its own script.
	var scene: PackedScene = load(SCENE_UID)
	var projectile: Projectile = scene.instantiate()

	# Added to the level and not to the shooter, so the shot survives its death.
	var level: Node = new_shooter.get_tree().current_scene
	# There is no current scene mid change, and the shot still has to land somewhere.
	if not level:
		level = new_shooter.get_parent()

	level.add_child(projectile)
	projectile.launch(new_data, new_damage, new_shooter, from_position, direction)

	return projectile


## Starts one shot on its way, right after the projectile enters the tree.
func launch(
	new_data: ProjectileData, 
	new_damage: float, 
	new_shooter: Node3D,
	from_position: Vector3, 
	direction: Vector3
	) -> void:
	
	data = new_data
	damage = new_damage
	shooter = new_shooter

	global_position = from_position
	velocity = direction.normalized() * data.speed
	_time_left = data.lifetime

	_apply_sides()
	_build_model()
	_face_travel_direction()


## Flies the shot and clears it away once its time is up.
func _physics_process(delta: float) -> void:
	# Planted where it landed, so nothing moves it and its lifetime stops counting.
	if _is_stuck: return

	# Applied before the step, so the shot curves as it travels instead of dropping at the end.
	velocity.y -= GRAVITY * data.gravity_scale * delta

	global_position += velocity * delta
	_face_travel_direction()

	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


## Puts the shot on its shooter's side, copied from the layers set on the shooter's scene.
func _apply_sides() -> void:
	collision_layer = shooter.attack_layer
	collision_mask = shooter.attack_mask

	# An empty mask makes every shot pass through everything without a word.
	if collision_mask == 0:
		push_error("Projectile: " + shooter.name + " has no attack_mask set on its scene.")


## Hangs the model on the shot and sizes the ball it notices things with.
func _build_model() -> void:
	# The shape is local to the scene, so resizing it only touches this shot.
	hit_shape.shape.radius = data.hit_radius

	if not data.model: return

	var model: Node3D = data.model.instantiate()
	add_child(model)
	# Each model has its own pivot, so the rotation that aligns it lives on the resource.
	model.rotation_degrees = data.model_rotation
	model.scale = Vector3.ONE * data.model_scale


## Turns the shot to look along the way it is travelling.
func _face_travel_direction() -> void:
	if velocity.length() < 0.01: return

	look_at(global_position + velocity, Vector3.UP)


## Lands the hit on whatever the shot ran into, then clears the shot away.
func _on_body_entered(body: Node3D) -> void:
	# Already planted, and the area only goes quiet on the next frame.
	if _is_stuck: return

	# Use the centerline at the height of the shot to avoid hitting external bones (like the arms).
	if body == shooter:
		push_error("Projectile: " + shooter.name + " was hit by its own shot. Check its "
			+ "collision_layer, which should not be one the shot's mask covers.")
		queue_free()
		return

	_deal_damage(body)

	# An arrow stays planted in whatever it hit, an orb has nothing to plant.
	if not data.sticks_on_hit:
		queue_free()
		return

	_stick_into(body)


## Plants the shot where it landed, instead of clearing it away.
func _stick_into(body: Node3D) -> void:
	_is_stuck = true

	# Deferred, because the physics server is still flushing the hit that got here.
	set_deferred("monitoring", false)
	call_deferred("_attach_to", body)


## Hangs the shot on what it hit, so it rides along with an enemy that walks off.
func _attach_to(body: Node3D) -> void:
	if not is_instance_valid(body):
		queue_free()
		return

	if body is BaseEnemy:
		_plant_in_skeleton(body)
	else:
		reparent(body, true)
		# The shot stopped a whole hit_radius short of the surface, so it is pushed in.
		global_position -= global_basis.z * (data.hit_radius + data.stick_depth)

	_copy_materials()

	var tween: Tween = create_tween()
	tween.tween_interval(data.stick_linger_time)
	tween.tween_method(_set_alpha, 1.0, 0.0, data.stick_fade_time)
	tween.tween_callback(_clear_away)


## Plants the shot in the nearest bone, so it rides the animation and not the body.
func _plant_in_skeleton(enemy: BaseEnemy) -> void:
	if not enemy.skeleton:
		reparent(enemy, true)
		return

	# # Use the center of the body at the point of impact to find the right bone, rather than relying on extended limbs.
	var entry: Vector3 = Vector3(enemy.global_position.x, global_position.y, enemy.global_position.z)
	var bone: int = _nearest_bone(enemy.skeleton, entry)

	var slot: BoneAttachment3D = BoneAttachment3D.new()
	enemy.skeleton.add_child(slot)
	slot.bone_idx = bone

	reparent(slot, true)

	# Moved onto the bone itself. The collision capsule is far wider than the
	# skeleton inside it, so where the shot stopped is out in the air beside it.
	global_position = _bone_position(enemy.skeleton, bone) + global_basis.z * data.stick_depth


## The bone closest to a spot, so the shot plants in the part of the body it hit.
func _nearest_bone(skeleton: Skeleton3D, spot: Vector3) -> int:
	var closest: int = 0
	var shortest: float = INF

	for bone: int in skeleton.get_bone_count():
		var distance: float = spot.distance_to(_bone_position(skeleton, bone))

		if distance < shortest:
			shortest = distance
			closest = bone

	return closest


## Where one bone sits in the world right now.
func _bone_position(skeleton: Skeleton3D, bone: int) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin


## Clears the shot away, along with the bone slot it was planted on.
func _clear_away() -> void:
	var slot: Node = get_parent()

	# Freeing the slot takes the shot with it, since the shot hangs off it.
	if slot is BoneAttachment3D:
		slot.queue_free()
		return

	queue_free()


## Copies the model's materials, or fading one arrow would fade every other one.
func _copy_materials() -> void:
	# owned = false because the model comes from a scene instanced at runtime.
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface: int in mesh.get_surface_override_material_count():
			var material: StandardMaterial3D = mesh.get_active_material(surface)
			if not material: continue

			var copy: StandardMaterial3D = material.duplicate()
			# Alpha up front, since an opaque material throws the fade away.
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.set_surface_override_material(surface, copy)

			_materials.append(copy)


## Puts every copied material at the same transparency, fading the shot as one.
func _set_alpha(alpha: float) -> void:
	for material: StandardMaterial3D in _materials:
		material.albedo_color.a = alpha


## Passes the damage on, if what was hit is something that can take it.
func _deal_damage(body: Node3D) -> void:
	var is_magic: bool = data.damage_type == ProjectileData.DamageType.MAGIC

	if body is Hero:
		body.take_damage(damage, global_position, is_magic)
		return

	if body is BaseEnemy:
		body.take_damage(damage, is_magic)
