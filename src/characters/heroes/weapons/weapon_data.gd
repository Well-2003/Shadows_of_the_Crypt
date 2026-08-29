class_name WeaponData
extends Resource
## Stats, model and animations for one weapon.
##
## One .tres per weapon. The stats are picked from enums so there is little
## to mistype, the grip values are typed in because they are measured by hand
## until the model sits right on the bone.


## Every weapon in the game, also used as its display name and save id.
enum WeaponId {
	## The fastest weapon and the weakest, the backup blade of the ranged classes.
	DAGGER_IRON,
	## Balanced blade that leaves a hand free, the Knight starts with it.
	SWORD_1HANDED,
	## Double the damage of the one-handed sword, at two thirds of the swing speed.
	SWORD_2HANDED,
	## Hits harder than the sword and swings slower, the Barbarian starts with it.
	AXE_1HANDED,
	## The heaviest hit in the game, and the slowest swing to land it.
	AXE_2HANDED,
	## Two-handed bow with steady damage, the Ranger starts with it.
	BOW_HUNTING,
	## Weak but quick, and leaves a hand free, the Rogue starts with it.
	CROSSBOW_1HANDED,
	## Trades the light crossbow's speed for more than double the damage.
	CROSSBOW_2HANDED,
	## Cheap, quick magic that leaves a hand free, the Mage starts with it.
	WAND,
	## Two-handed magic with the heaviest mana cost, and the damage to match.
	STAFF,
	## Off-hand book that adds a little magic damage instead of attacking.
	SPELLBOOK,
	## Deals no damage, thrown to break enemy detection.
	SMOKEBOMB,
	## No combat use, drunk for a short buff.
	MUG,
	## Light shield with no speed penalty, the Knight starts with it.
	SHIELD_WOODEN_BUCKLER,
	## Blocks more than the buckler, at a small cost in speed.
	SHIELD_CRUSADER,
	## Spiked shield that blocks half of the damage coming from the front.
	SHIELD_AEGIS_THORNS,
	## Blocks nearly everything, and its rarity cancels the usual speed penalty.
	SHIELD_SCARLET_BULWARK
}

## What the weapon is, which decides how it is used.
enum WeaponType {
	## One-handed blade, balanced and fast.
	SWORD,
	## Heavy chopping weapon, slow but hits hard.
	AXE,
	## Short blade, the fastest melee weapon.
	DAGGER,
	## Fires arrows, needs the string drawn before each shot.
	BOW,
	## Fires bolts, slower than the bow but hits harder.
	CROSSBOW,
	## One-handed magic weapon, cheap on mana.
	WAND,
	## Two-handed magic weapon, expensive but devastating.
	STAFF,
	## Off-hand item that blocks frontal damage instead of attacking.
	SHIELD,
	## Off-hand book that boosts magic instead of attacking.
	SPELLBOOK,
	## Item with no direct damage, like the smoke bomb.
	UTILITY
}

## How many slots the weapon takes up in the hotbar.
enum Handedness {
	## Leaves the second slot free for a shield, grimoire or dagger.
	ONE_HANDED,
	## Fills both slots, the second item is stowed while equipped.
	TWO_HANDED,
	## Only fits the second slot.
	OFF_HAND
}

## Which hand bone the model is attached to.
enum Hand {
	## The "handslot.r" bone, on the right.
	MAIN,
	## The "handslot.l" bone, on the left.
	OFF
}

## How good the weapon is, decides its tint and shop price.
enum Rarity {
	## Starting gear, base model.
	COMMON,
	## A small step above common.
	UNCOMMON,
	## Noticeably stronger.
	RARE,
	## The best gear in the game.
	EPIC
}

## Which player attribute the damage grows with.
enum Scaling {
	## Grows with Strength, for swords and axes.
	STRENGTH,
	## Grows with Agility, for bows, crossbows and daggers.
	AGILITY,
	## Grows with Magic Power, for staves, wands and grimoires.
	MAGIC
}

## Model tint per rarity, in the same order as Rarity.
const RARITY_COLORS: Array[Color] = [
	Color("ffffffff"),
	Color("66ff80ff"),
	Color("5999ffff"),
	Color("b359ffff")
]


## Which weapon this is, also its display name and its id in the save file.
@export var id: WeaponId = WeaponId.DAGGER_IRON
## What the weapon is.
@export var weapon_type: WeaponType = WeaponType.SWORD
## How many hotbar slots it fills.
@export var handedness: Handedness = Handedness.ONE_HANDED
## Which hand bone the model hangs from.
@export var hand: Hand = Hand.MAIN
## How good it is.
@export var rarity: Rarity = Rarity.COMMON

@export_group("Combat")
## Damage before the player's attribute is added in.
@export var base_damage: int = 0
## Animation speed multiplier, above 1.0 attacks faster.
@export var attack_speed: float = 1.0
## Stamina, mana or ammo spent per use.
@export var resource_cost: int = 0
## Which player attribute is added to the damage.
@export var scaling: Scaling = Scaling.STRENGTH
## How much of that attribute is added, 1.0 adds it whole.
@export var scaling_multiplier: float = 1.0

@export_group("Models")
## Model held in the hand bone, seen in third person.
@export var world_model: PackedScene = null
## Model shown in front of the camera in first person.
@export var view_model: PackedScene = null
## Projectile spawned on attack, left empty for melee weapons.
@export var projectile_scene: PackedScene = null

@export_group("Grip")
## Offset from the hand bone, measured in the editor until the model fits.
@export var grip_position: Vector3 = Vector3.ZERO
## Rotation in degrees from the hand bone, so the model points the right way.
@export var grip_rotation: Vector3 = Vector3.ZERO
## Size of the model in the hand, 1.0 keeps the size it was modelled at.
@export var grip_scale: float = 1.0

@export_group("Animations")
## Attack animations, one is picked per swing, as library/animation.
@export var attack_animations: Array[String] = []
## Animation held while this weapon is equipped and the hero stands still.
@export var idle_animation: String = ""

@export_group("Shop")
## Price in coins.
@export var shop_price: int = 0


## Name shown to the player, taken from the id so there is no text to keep in sync.
func get_display_name() -> String:
	return WeaponId.keys()[id].capitalize()


## Tint for this weapon's rarity.
func get_rarity_color() -> Color:
	return RARITY_COLORS[rarity]


## Final damage this weapon deals with the given attribute values.
func get_damage(strength: int, agility: int, magic_power: int) -> float:
	var attribute: int = 0

	match scaling:
		Scaling.STRENGTH: attribute = strength
		Scaling.AGILITY: attribute = agility
		Scaling.MAGIC: attribute = magic_power

	return base_damage + attribute * scaling_multiplier
