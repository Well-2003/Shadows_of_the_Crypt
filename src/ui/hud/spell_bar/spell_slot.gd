class_name SpellSlot
extends Panel
## One square of the spell bar, holding a single magic.
##
## The whole look lives in the scene. This only swaps the drawing, tints it in
## the spell's own colour and thickens the border on the one that is selected.


## Border of an empty slot and of the ones waiting their turn.
const IDLE_BORDER: Color = Color("595959b3")
## Border of the slot the next cast will use.
const PICKED_BORDER: Color = Color("ffffffe6")
## Thickness of that border, in pixels, idle and selected.
const IDLE_WIDTH: int = 1
const PICKED_WIDTH: int = 3

@onready var icon: TextureRect = $Icon


## Puts one spell in the slot, or leaves it empty when the book has none there.
func show_spell(spell: SpellData, is_selected: bool) -> void:
	# An empty slot still draws its square, so the plus never loses an arm.
	icon.visible = spell != null and spell.icon != null

	if spell and spell.icon:
		icon.texture = spell.icon
		# The tint is what puts one drawing in each spell's own colour.
		icon.modulate = spell.icon_color

	if is_selected:
		_apply_border(PICKED_BORDER, PICKED_WIDTH)
		return

	_apply_border(IDLE_BORDER, IDLE_WIDTH)


## Repaints the border, which is what marks the slot that is up next.
func _apply_border(color: Color, width: int) -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel")
	style.border_color = color
	style.set_border_width_all(width)
