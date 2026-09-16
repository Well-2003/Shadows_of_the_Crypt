class_name WeaponHitbox
extends Area3D
## The volume a swung weapon actually hits with.
##
## Built in code and hung on the weapon model, so the grip rotation already
## measured for the model lines the capsule up with the blade. It stays closed
## until a swing opens it, and each target is only hit once per swing.


var damage: float = 0.0
var is_magic: bool = false

var attacker: Node3D = null

var _already_hit: Array[Node3D] = []
var _is_open: bool = false


## Builds a hitbox and hands it back, ready to be added to the weapon model.
static func create(
	new_attacker: Node3D,
	length: float,
	radius: float,
	offset: Vector3,
	tilt: Vector3
	) -> WeaponHitbox:

	var hitbox: WeaponHitbox = WeaponHitbox.new()
	hitbox.attacker = new_attacker
	hitbox.name = "WeaponHitbox"

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = radius
	# The caps count towards the height, so a short blade would end up thinner than asked.
	capsule.height = maxf(length, radius * 2.0)

	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = capsule
	hitbox.add_child(shape)

	hitbox.position = offset
	hitbox.rotation_degrees = tilt

	hitbox._apply_sides()
	# Closed until a swing opens it, or walking past an enemy would hurt them.
	hitbox.close()
	# Watching from the start, because switching it on costs a physics frame to
	# work out the overlaps, and a swing would land a frame late every time.
	hitbox.monitoring = true

	return hitbox


## Opens the hitbox for one swing, with the damage that swing is worth.
func open(new_damage: float, new_is_magic: bool) -> void:
	damage = new_damage
	is_magic = new_is_magic

	_already_hit.clear()
	_is_open = true


## Shuts the hitbox again, which is what ends the swing's window to land.
func close() -> void:
	_is_open = false


## Hits whatever is inside the blade while the swing's window is open.
func _physics_process(_delta: float) -> void:
	if not _is_open: return

	# Read every frame instead of on body_entered, so a target already standing
	# inside the blade when the swing opens is hit like any other.
	for body: Node3D in get_overlapping_bodies():
		if body in _already_hit: continue

		_already_hit.append(body)
		_deal_damage(body)


## Puts the hitbox on its attacker's side, copied from the layers set on the attacker's scene.
func _apply_sides() -> void:
	collision_layer = attacker.attack_layer
	collision_mask = attacker.attack_mask

	# An empty mask makes every swing pass through everything without a word.
	if collision_mask == 0:
		push_warning("WeaponHitbox: " + attacker.name + " has no attack_mask set on its scene.")


## Passes the damage on, if what was hit is something that can take it.
func _deal_damage(body: Node3D) -> void:
	if body is Hero:
		# The attacker position tells the hero which way the blow came from, for the shield.
		body.take_damage(damage, attacker.global_position, is_magic)
		return

	if body is BaseEnemy:
		body.take_damage(damage, is_magic)
