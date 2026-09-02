class_name VillainClassData
extends Resource
## Combat attributes and equipment for one class of enemy.
##
## One .tres per enemy class. The weapons carry no damage of their own: they
## are only the models the enemy spawns holding, and every hit is worth
## attack_damage no matter what is in its hands.


## Unique identifier for each enemy class in the game.
enum VillainId {
	## Slow caster with an area orb; fragile to blades, resistant to magic.
	MAGE,
	## The heavy one, a wall of health that cleaves and ignores light hits.
	MINION,
	## Keeps its distance and shoots, backing away when the player closes in.
	ROGUE,
	## Basic melee fodder, weak alone and dangerous in a group.
	WARRIOR
}


## Which enemy class this is; also the index BaseEnemy.MESHES uses for the model.
@export var id: VillainId
## Flavor text describing the enemy.
@export_multiline var profile: String

@export_group("Attributes")
## Starting and maximum health, fills the enemy's health_pool.
@export var max_health: float = 40.0
## Damage dealt by one hit, whatever the weapon in hand happens to be.
@export var attack_damage: float = 10.0
## Speed while patrolling.
@export var move_speed: float = 4.0
## Speed while running the player down.
@export var chase_speed: float = 5.0
## Speed while backing away to regain distance.
@export var escape_speed: float = 5.0

@export_group("Ranges")
## How far away the player can be spotted from.
@export var detection_range: float = 15.0
## How close the enemy must be to attack.
@export var attack_range: float = 1.5
## Distance the enemy backs away from; 0 for melee, which never retreats.
@export var retreat_range: float = 0.0
## Distance a ranged enemy tries to hold, between retreat_range and attack_range.
@export var ideal_range: float = 0.0

@export_group("Timing")
## Wind-up before the hit lands, the window the player has to read it.
@export var telegraph_time: float = 0.5
## Wait between one attack and the next.
@export var attack_cooldown: float = 1.2

@export_group("Resistances")
## When true, light hits do not stagger the enemy out of its attack.
@export var immune_to_light_stagger: bool = false
## Multiplier on incoming physical damage; above 1.0 means it hurts more.
@export var physical_damage_taken: float = 1.0
## Multiplier on incoming magic damage; below 1.0 means it hurts less.
@export var magic_damage_taken: float = 1.0

@export_group("Rewards")
## Experience granted for the kill.
@export var xp_reward: int = 25
## Lowest amount of coins dropped.
@export var coins_min: int = 10
## Highest amount of coins dropped.
@export var coins_max: int = 15

@export_group("Equipment")
## Models the enemy spawns holding; damage comes from attack_damage, not these.
@export var weapons: Array[WeaponData] = []


## Name shown to the player, taken from the id so there is no text to keep in sync.
func get_display_name() -> String:
	return VillainId.keys()[id].capitalize()


## A fresh coin drop for one kill, somewhere inside the class's range.
func roll_coin_drop() -> int:
	return randi_range(coins_min, coins_max)
