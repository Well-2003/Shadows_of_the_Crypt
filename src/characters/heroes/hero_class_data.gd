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

@export_group("Equipment")
## Starting gear, index 0 fills hotbar slot 1 and index 1 fills slot 2.
@export var starting_weapons: Array[WeaponData] = []
