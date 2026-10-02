class_name Hotbar
extends Node
## The hero's item slots and the switching between them.
##
## Only decides what is selected, never touches the skeleton: Hero listens for
## the change and re-hangs the models. Off hand items are worn rather than
## selected, which is why a shield slot cannot be switched to.


## How many slots the bar has, matching the hotbar_1 to hotbar_5 input actions.
const SLOT_COUNT: int = 5

## Emitted whenever the contents or the selection move, for the HUD and the Hero.
signal changed(all_slots: Array[WeaponData], selected: int)

var slots: Array[WeaponData] = []
var selected_index: int = 0


## Fills the bar from a class's starting gear and picks the first usable slot.
func setup(hero_data: HeroClassData) -> void:
	slots.clear()
	# Every slot exists from the start, empty ones included, so the row never resizes.
	slots.resize(SLOT_COUNT)

	if hero_data:
		for index: int in mini(hero_data.starting_weapons.size(), SLOT_COUNT):
			slots[index] = hero_data.starting_weapons[index]

	selected_index = _first_selectable_slot()

	changed.emit(slots, selected_index)


## Selects one slot, ignoring the ones holding nothing or holding an off hand item.
func select(index: int) -> void:
	if index < 0 or index >= slots.size(): return
	if index == selected_index: return
	if not is_selectable(index): return

	selected_index = index

	changed.emit(slots, selected_index)


## True when the slot holds something the main hand can actually take.
func is_selectable(index: int) -> bool:
	var item: WeaponData = slots[index]
	if not item: return false

	# A shield or a grimoire is worn alongside, so switching to it would empty the main hand.
	return item.handedness != WeaponData.Handedness.OFF_HAND


## What the main hand should be holding.
func get_selected() -> WeaponData:
	return slots[selected_index]


## What the off hand should be wearing, or null while a two handed weapon is out.
func get_off_hand() -> WeaponData:
	var selected: WeaponData = get_selected()

	# Both hands are busy, so whatever is worn stays stowed until the weapon changes.
	if selected and selected.handedness == WeaponData.Handedness.TWO_HANDED:
		return null

	for item: WeaponData in slots:
		if item and item.handedness == WeaponData.Handedness.OFF_HAND:
			return item

	return null


## The lowest slot the main hand can take, or 0 when the class carries nothing.
func _first_selectable_slot() -> int:
	for index: int in slots.size():
		if is_selectable(index):
			return index

	return 0
