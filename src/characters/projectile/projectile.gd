class_name Projectile
extends Area3D
## A shot in flight, shared by every arrow, bolt and orb in the game.
##
## Everything that changes from one shot to the next lives in ProjectileData, so
## a new kind of projectile is a resource and never a new scene.


## The scene every projectile is spawned from, by uid so moving the file is safe.
const SCENE_UID: String = "uid://dnrxc8mcgkpfh"

#region Physics layers, as the bit values the engine stores them in
## Walls and floor.
const LAYER_WORLD: int = 1
## The hero's body.
const LAYER_PLAYER: int = 2
## The enemies' bodies.
const LAYER_ENEMY: int = 4
## Shots and swings coming from the hero.
const LAYER_PLAYER_HITBOX: int = 8
## Shots and swings coming from the enemies.
const LAYER_ENEMY_HITBOX: int = 16
#endregion

## Downward pull at gravity_scale 1.0, the same the characters fall with.
const GRAVITY: float = 9.8

var data: ProjectileData = null
var damage: float = 0.0
var shooter: Node3D = null

var velocity: Vector3 = Vector3.ZERO

var _time_left: float = 0.0

@onready var hit_shape: CollisionShape3D = $HitShape


## Puts one projectile in the level, already flying.
static func spawn(new_data: ProjectileData, new_damage: float, new_shooter: Node3D,
		from_position: Vector3, direction: Vector3) -> Projectile:
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
func launch(new_data: ProjectileData, new_damage: float, new_shooter: Node3D,
		from_position: Vector3, direction: Vector3) -> void:
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
	# Applied before the step, so the shot curves as it travels instead of dropping at the end.
	velocity.y -= GRAVITY * data.gravity_scale * delta

	global_position += velocity * delta
	_face_travel_direction()

	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


## Puts the shot on its shooter's side and points it at the other one.
func _apply_sides() -> void:
	# Layers are added because each is a separate bit, which is how Godot holds a mask.
	if shooter is Hero:
		collision_layer = LAYER_PLAYER_HITBOX
		collision_mask = LAYER_WORLD + LAYER_ENEMY
		return

	collision_layer = LAYER_ENEMY_HITBOX
	collision_mask = LAYER_WORLD + LAYER_PLAYER


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
	# The layers already keep the shooter out, this covers a point blank shot into its own wall.
	if body == shooter: return

	_deal_damage(body)
	queue_free()


## Passes the damage on, if what was hit is something that can take it.
func _deal_damage(body: Node3D) -> void:
	var is_magic: bool = data.damage_type == ProjectileData.DamageType.MAGIC

	if body is Hero:
		body.take_damage(damage, global_position, is_magic)
		return

	if body is BaseEnemy:
		body.take_damage(damage, is_magic)
