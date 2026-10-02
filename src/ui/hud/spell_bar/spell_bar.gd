class_name SpellBar
extends Control
## The four spell slots, laid out as a plus beside the weapon hotbar.
##
## Decides nothing on its own: Hero hands it the whole book every time the
## selection moves, and it paints the four squares from that.


@onready var slots: Array[SpellSlot] = [$Up, $Right, $Down, $Left]


## Fills the cross, clockwise from the top so cycling walks around it.
func show_spells(spells: Array[SpellData], selected: int) -> void:
	for index: int in slots.size():
		var spell: SpellData = null
		if index < spells.size():
			spell = spells[index]

		slots[index].show_spell(spell, index == selected)
