class_name HeroClassData
extends Resource
## Gameplay attributes and equipment for a playable hero class.


## Unique identifier for each available hero class in the game.
enum HeroId {
	KNIGHT,
	BARBARIAN,
	RANGER,
	ROGUE,
	MAGE,
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

@export var id: HeroId
@export_multiline var profile: String

@export_group("Attributes")
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var physical_damage_melee: float = 0.0
@export var physical_damage_ranged: float = 0.0
@export var magic_damage: float = 0.0
@export var resource_max: float = 100.0
@export var resource_type: ResourceType = ResourceType.STAMINA

@export_group("Equipment")
## Weapon attached to the "handslot.r" bone.
@export var main_hand_weapon: WeaponType = WeaponType.NONE
## Weapon/shield attached to the "handslot.l" bone.
@export var off_hand_weapon: WeaponType = WeaponType.NONE
