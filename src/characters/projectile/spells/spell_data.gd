class_name SpellData
extends Resource
## One spell the hero can cast, and everything that changes between spells.
##
## One .tres per spell. A projectile spell throws a shot, an area spell drops a
## patch that keeps burning where it landed, and both come from this same file.


## What the spell does when it is cast.
enum Kind {
	## Flies forward and hits the first thing in its way.
	PROJECTILE,
	## Lands where the crosshair points and hurts whatever stands in it.
	AREA
}


## Name shown in the HUD.
@export var display_name: String = ""
## Icon shown in the spell bar, empty for a spell with no art yet.
@export var icon: Texture2D = null
## Tint laid over that icon, so one drawing serves a spell in its own colour.
@export var icon_color: Color = Color.WHITE
## What the spell does when it is cast.
@export var kind: Kind = Kind.PROJECTILE
## Mana spent per cast.
@export var mana_cost: int = 5
## Damage before the hero's magic power is added in.
@export var base_damage: int = 10
## How much of the hero's magic power is added, 1.0 adds it whole.
@export var scaling_multiplier: float = 1.0

@export_group("Projectile")
## Shot thrown by a projectile spell, empty for an area one.
@export var projectile: ProjectileData = null

@export_group("Area")
## Effect scene dropped by an area spell, empty for a projectile one.
@export var effect: PackedScene = null
## Size of that effect, 1.0 keeps the size it was built at.
@export var effect_scale: float = 1.0
## How far the patch reaches from where it landed, in metres.
@export var radius: float = 2.5
## How long the patch stays before it closes, in seconds.
@export var duration: float = 5.0
## Seconds between one tick of damage and the next.
@export var damage_interval: float = 0.6
## How high off the ground it sits, for a spell that hovers instead of pooling.
@export var height_offset: float = 0.0


## Damage one cast is worth, with the caster's magic power added in.
func get_damage(magic_power: int) -> float:
	return base_damage + magic_power * scaling_multiplier
