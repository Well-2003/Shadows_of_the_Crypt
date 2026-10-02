class_name Spellbook
extends Node
## The hero's spell slots and the cycling between them.
##
## Only decides which spell is selected. Hero reads it when a magic weapon
## releases its attack, and the HUD reads it to show the name and the cost.


## How many slots the book has.
const SLOT_COUNT: int = 4

## Emitted whenever the contents or the selection move, for the HUD.
signal changed(all_spells: Array[SpellData], selected: int)

var spells: Array[SpellData] = []
var selected_index: int = 0


## Fills the book from a class's starting spells and picks the first one.
func setup(hero_data: HeroClassData) -> void:
	spells.clear()
	# Every slot exists from the start, empty ones included, so the row never resizes.
	spells.resize(SLOT_COUNT)

	if hero_data:
		for index: int in mini(hero_data.starting_spells.size(), SLOT_COUNT):
			spells[index] = hero_data.starting_spells[index]

	selected_index = _first_filled_slot()

	changed.emit(spells, selected_index)


## Moves to the next slot holding a spell, wrapping back around to the start.
func cycle() -> void:
	if not has_any(): return

	for step: int in SLOT_COUNT:
		# Starts one past the current slot, so an empty one is simply skipped.
		var index: int = (selected_index + step + 1) % SLOT_COUNT

		if spells[index]:
			selected_index = index
			break

	changed.emit(spells, selected_index)


## The spell the next cast will use, or null while the book is empty.
func get_selected() -> SpellData:
	return spells[selected_index]


## True while at least one slot holds a spell.
func has_any() -> bool:
	for spell: SpellData in spells:
		if spell: return true

	return false


## The first slot holding a spell, or 0 when the book is empty.
func _first_filled_slot() -> int:
	for index: int in spells.size():
		if spells[index]:
			return index

	return 0
