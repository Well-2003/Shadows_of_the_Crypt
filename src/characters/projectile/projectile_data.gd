class_name ProjectileData
extends Resource
## Model and flight of one kind of shot.
##
## One .tres per projectile: the arrow, the bolt, the arcane orb. The damage is
## not here on purpose, it comes from whoever pulled the trigger.


## What the target's resistances treat the hit as.
enum DamageType {
	## Arrows, bolts and anything else with a point on it.
	PHYSICAL,
	## Orbs and every other shot made of magic.
	MAGIC
}


## Model the shot flies as, left empty for an invisible one.
@export var model: PackedScene = null
## Rotation in degrees applied to the model, so it points where it is going.
@export var model_rotation: Vector3 = Vector3.ZERO
## Size of the model, 1.0 keeps the size it was modelled at.
@export var model_scale: float = 1.0

@export_group("Flight")
## Travel speed in metres per second.
@export var speed: float = 25.0
## How hard the shot is pulled down, 0.0 flies straight and 1.0 falls like a rock.
@export var gravity_scale: float = 0.0
## Seconds the shot lives before it clears itself away.
@export var lifetime: float = 6.0
## Radius of the ball the shot notices things with, bigger forgives bad aim.
@export var hit_radius: float = 0.15

@export_group("Impact")
## Which resistance the target applies to this hit.
@export var damage_type: DamageType = DamageType.PHYSICAL
