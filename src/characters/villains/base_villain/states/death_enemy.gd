class_name DeathEnemy
extends State
## Death state: plays the death animation and clears the enemy away.
##
## Terminal, nothing transitions out of it. The body is left lying there for a
## moment and then faded out, so the kill has time to read on screen.


## The skeleton falling apart, its own animation and not the general death one.
const DEATH_ANIMATION: String = "special/Skeletons_Death"

var enemy: BaseEnemy = null
var _is_finished: bool = false
var _is_fading: bool = false
var _time_left: float = 0.0


## Stops the enemy and starts the death animation.
func enter() -> void:
	enemy = context
	_is_finished = false
	_is_fading = false
	_time_left = enemy.corpse_linger_time

	# The corpse leaves the fight at once, so it cannot block shots or push anyone.
	enemy.collision_layer = 0
	enemy.collision_mask = 0

	# A blink still running would keep writing colours over the fade below.
	enemy.damage_flash.stop()

	Signals.enemy_died.emit(enemy.villain_data)

	enemy.play_animation(DEATH_ANIMATION, false, 0.1)
	enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Lets the body lie there after the animation, then starts fading it out.
func physics_update() -> State:
	var delta: float = get_physics_process_delta_time()

	# Nothing to count while the skeleton is still coming apart.
	if not _is_finished:
		return null

	# From here the Tween owns the rest, and it frees the enemy when it is done.
	if _is_fading:
		return null

	_time_left -= delta
	if _time_left > 0.0:
		return null

	_is_fading = true
	_start_fading()

	return null


## Fades every piece of the body out together, and clears it away at the end.
func _start_fading() -> void:
	# DamageFlash already copied these, so the alpha only touches this corpse.
	var materials: Array[StandardMaterial3D] = enemy.damage_flash.get_materials()

	var tween: Tween = enemy.create_tween()
	# Parallel, otherwise the skeleton would fade one bone at a time.
	tween.set_parallel(true)

	for material: StandardMaterial3D in materials:
		# An opaque material throws the alpha away, leaving the body solid.
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, enemy.corpse_fade_time)

	# The gear shares its material with every weapon of its kind, so it shrinks instead.
	for slot: BoneAttachment3D in enemy.equipment_slots:
		if not is_instance_valid(slot): continue
		if slot.get_child_count() == 0: continue

		tween.tween_property(slot.get_child(0), "scale", Vector3.ZERO, enemy.corpse_fade_time)

	# chain waits for every fade above to finish before the body is freed.
	tween.chain().tween_callback(enemy.queue_free)


func _on_animation_finished(_animation_name: StringName) -> void:
	_is_finished = true
