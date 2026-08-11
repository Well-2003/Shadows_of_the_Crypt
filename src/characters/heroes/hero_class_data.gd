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

## Represents the specific type of 3D weapon or equipment a hero can wield.
enum WeaponType {
	## Empty slot, the hero carries nothing in this hand.
	NONE,
	## One-handed sword, carried by the Knight.
	SWORD_1H,
	## One-handed axe, carried by the Barbarian.
	AXE_1H,
	## Bow, carried by the Ranger.
	BOW,
	## One-handed crossbow, carried by the Rogue.
	CROSSBOW_1H,
	## Magic wand, carried by the Mage.
	WAND,
	## Short blade, the off-hand of the Mage, Ranger and Rogue.
	DAGGER,
	## Square shield, the off-hand of the Barbarian and Knight.
	SHIELD_SQUARE
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
## Weapon attached to the "handslot.r" bone.
@export var main_hand_weapon: WeaponType = WeaponType.NONE
## Weapon/shield attached to the "handslot.l" bone.
@export var off_hand_weapon: WeaponType = WeaponType.NONE
