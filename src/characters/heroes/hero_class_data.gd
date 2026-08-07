class_name HeroClassData
extends Resource
## Gameplay attributes and equipment for a playable hero class.


## Unique identifier for each available hero class in the game.
enum HeroId {
	## Axe and shield; tanky like the Knight, but without the slowness.
	BARBARIAN,
	## Sword and shield; the highest health, and the slowest.
	KNIGHT,
	## Wand and spellbook; the only class with magic damage, and the lowest health.
	MAGE,
	## Bow; the highest ranged damage.
	RANGER,
	## One-handed crossbow; the fastest, and the highest melee damage.
	ROGUE
}

## Represents the specific type of 3D weapon or equipment a hero can wield.
enum WeaponType {
	NONE,
	SWORD_1H,
	AXE_1H,
	BOW,
	CROSSBOW_1H,
	WAND,
	DAGGER,
	SHIELD_SQUARE,
	SPELLBOOK,
}

## Primary resource consumed by the hero's weapons and abilities.
enum ResourceType {
	STAMINA,
	MANA,
	ARROWS,
	BOLTS,
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
## Weapon attached to the "handslot.r" bone.
@export var main_hand_weapon: WeaponType = WeaponType.NONE
## Weapon/shield attached to the "handslot.l" bone.
@export var off_hand_weapon: WeaponType = WeaponType.NONE
