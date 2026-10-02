class_name HeroClassData
extends Resource
## Gameplay attributes and equipment for a playable hero class.


## Unique identifier for each available hero class in the game.
enum HeroId {
	## Axe and shield; tanky like the Knight, but without the slowness.
	BARBARIAN,
	## Sword and shield; the highest health, and the slowest.
	KNIGHT,
	## Wand and dagger; the only class with magic damage, and the lowest health.
	MAGE,
	## Bow; the highest ranged damage.
	RANGER,
	## One-handed crossbow; the fastest, and the highest melee damage.
	ROGUE
}

## Primary resource consumed by the hero's weapons and abilities.
enum ResourceType {
	## Default resource, spent by the Barbarian and Knight.
	STAMINA,
	## Spent on spells by the Mage.
	MANA,
	## Ammo for the Ranger's bow.
	ARROWS,
	## Ammo for the Rogue's crossbow.
	BOLTS
}

## Which class this resource is; also the index Hero.MESHES uses to load the model.
@export var id: HeroId
## Flavor text describing the class.
@export_multiline var profile: String

@export_group("Attributes")
## Starting and maximum health, fills the Hero's health_pool.
@export var max_health: float = 100.0
## Movement speed.
@export var move_speed: float = 5.0
## Damage dealt by close range attacks.
@export var physical_damage_melee: float = 0.0
## Damage dealt by ranged attacks.
@export var physical_damage_ranged: float = 0.0
## Damage dealt by spells.
@export var magic_damage: float = 0.0
## Maximum amount of the resource set in resource_type.
@export var resource_max: float = 100.0
## Which resource this class spends: stamina, mana, arrows or bolts.
@export var resource_type: ResourceType = ResourceType.STAMINA
## How much of the resource comes back per second, so a class is never stranded.
@export var resource_regen_per_second: float = 8.0
## How long after spending before the refill starts, in seconds.
@export var resource_regen_delay: float = 2.5

@export_group("Equipment")
## Starting gear, index 0 fills hotbar slot 1 and index 1 fills slot 2.
@export var starting_weapons: Array[WeaponData] = []
## True for a class that casts, which is what puts the spell cross on screen.
@export var uses_spells: bool = false
## Spells the class knows, in the order they fill the four spell slots.
@export var starting_spells: Array[SpellData] = []


@export_group("Growth")
## Health added on every level gained after the first.
@export var health_per_level: float = 8.0
## Close range damage added on every level gained.
@export var melee_damage_per_level: float = 1.0
## Ranged damage added on every level gained.
@export var ranged_damage_per_level: float = 1.0
## Spell damage added on every level gained.
@export var magic_damage_per_level: float = 1.0
## Stamina, mana or ammo capacity added on every level gained.
@export var resource_per_level: float = 5.0


## Health this class has at a given level.
func get_max_health(level: int) -> float:
	return max_health + _growth(health_per_level, level)


## Close range damage this class has at a given level.
func get_melee_damage(level: int) -> float:
	return physical_damage_melee + _growth(melee_damage_per_level, level)


## Ranged damage this class has at a given level.
func get_ranged_damage(level: int) -> float:
	return physical_damage_ranged + _growth(ranged_damage_per_level, level)


## Spell damage this class has at a given level.
func get_magic_damage(level: int) -> float:
	return magic_damage + _growth(magic_damage_per_level, level)


## Resource capacity this class has at a given level.
func get_resource_max(level: int) -> float:
	return resource_max + _growth(resource_per_level, level)


## How much the levels have added to a stat, nothing at all on level one.
func _growth(per_level: float, level: int) -> float:
	return per_level * (level - 1)

## True when the resource is ammo, which the HUD counts instead of drawing a bar.
func is_ammo() -> bool:
	return resource_type == ResourceType.ARROWS or resource_type == ResourceType.BOLTS


## True when the resource is mana, which only magic is allowed to spend.
func is_mana() -> bool:
	return resource_type == ResourceType.MANA


## Name shown to the player, taken from the enum so there is no text to keep in sync.
func get_resource_name() -> String:
	return ResourceType.keys()[resource_type].capitalize()
