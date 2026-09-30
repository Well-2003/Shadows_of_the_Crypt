class_name SpellArea
extends Area3D
## A spell that stays where it landed and keeps hurting whatever stands in it.
##
## Dropped at the spot the crosshair pointed to, it damages everything inside on
## a beat until its time runs out, then closes and clears itself away.


## The scene every area spell is built from.
const SCENE_PATH: String = "res://characters/projectile/spells/spell_area/spell_area.tscn"
## How long the effect is left to close itself before the node goes.
const CLOSE_TIME: float = 1.0

var damage: float = 0.0
var caster: Node3D = null

var _time_left: float = 0.0
var _beat: float = 0.6
var _beat_left: float = 0.0
var _effect: Node3D = null

@onready var shape: CollisionShape3D = $Shape


## Drops one area spell in the level, already burning.
static func cast(spell: SpellData, new_caster: Node3D, spot: Vector3, new_damage: float) -> SpellArea:
	var scene: PackedScene = load(SCENE_PATH)
	var area: SpellArea = scene.instantiate()

	# Added to the level and not to the caster, so it stays where it landed.
	var level: Node = new_caster.get_tree().current_scene
	level.add_child(area)

	area.global_position = spot
	area.setup(spell, new_caster, new_damage)

	return area


## Fills in everything that changes from one spell to the next.
func setup(spell: SpellData, new_caster: Node3D, new_damage: float) -> void:
	caster = new_caster
	damage = new_damage

	_time_left = spell.duration
	_beat = spell.damage_interval
	# Zero, so whoever is already standing in it is burned on the first frame.
	_beat_left = 0.0

	collision_layer = new_caster.attack_layer
	collision_mask = new_caster.attack_mask

	# The shape is local to the scene, so resizing it only touches this patch.
	shape.shape.radius = spell.radius

	if not spell.effect: return

	_effect = spell.effect.instantiate()
	add_child(_effect)
	_effect.scale = Vector3.ONE * spell.effect_scale


## Burns whoever is inside on every beat, until the spell runs out of time.
func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_finish()
		return

	_beat_left -= delta
	if _beat_left > 0.0: return

	_beat_left = _beat
	_burn_everything_inside()


## Lands one beat of damage on everything standing in the patch.
func _burn_everything_inside() -> void:
	for body: Node3D in get_overlapping_bodies():
		if body is BaseEnemy:
			body.take_damage(damage, true)
			continue

		if body is Hero:
			body.take_damage(damage, global_position, true)


## Stops the burn and lets the effect close before the node goes.
func _finish() -> void:
	set_physics_process(false)
	monitoring = false

	if is_instance_valid(_effect):
		_effect.close()

	var tween: Tween = create_tween()
	tween.tween_interval(CLOSE_TIME)
	tween.tween_callback(queue_free)
