class_name ShieldData
extends WeaponData
## A shield, which blocks instead of attacking.
##
## Extends WeaponData so it reuses the model, rarity and shop fields, the
## ones here only matter while the shield is raised.


@export_group("Blocking")
## Share of frontal physical damage removed, 0.3 means 30% less.
@export var physical_reduction: float = 0.0
## Share of frontal magic damage removed.
@export var magic_reduction: float = 0.0
## Share of move speed lost while equipped, epic shields bring this back to 0.
@export var speed_penalty: float = 0.0
## Cone in front of the hero that the shield actually covers.
@export var block_angle_degrees: float = 120.0
