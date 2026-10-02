class_name HotbarSlot
extends Panel
## One square of the hotbar, showing what it holds and whether it is in hand.
##
## Built in code because the five slots are identical and only differ by the
## number in the corner, so a scene per slot would be five copies of one thing.


## Size of the square, in pixels.
const SLOT_SIZE: Vector2 = Vector2(80.0, 80.0)
## Gap between the icon and the edge of the square, in pixels.
const ICON_MARGIN: float = 6.0
## Border colour of a slot holding nothing.
const EMPTY_BORDER: Color = Color(0.35, 0.35, 0.35, 0.7)
## Background behind every slot.
const BACKGROUND: Color = Color(0.08, 0.08, 0.08, 0.8)

var _style: StyleBoxFlat = null
var _key_label: Label = null
var _icon: WeaponIcon = null


## Builds the square, its icon and its number, and shows itself empty to start with.
func _ready() -> void:
	custom_minimum_size = SLOT_SIZE

	_style = StyleBoxFlat.new()
	_style.bg_color = BACKGROUND
	_style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", _style)

	_icon = WeaponIcon.new()
	# Pinned to all four sides, so the render follows whatever size the slot takes.
	_icon.anchor_right = 1.0
	_icon.anchor_bottom = 1.0
	_icon.offset_left = ICON_MARGIN
	_icon.offset_top = ICON_MARGIN
	_icon.offset_right = -ICON_MARGIN
	_icon.offset_bottom = -ICON_MARGIN
	add_child(_icon)

	# Added after the icon so the number stays readable on top of the model.
	_key_label = Label.new()
	_key_label.add_theme_font_size_override("font_size", 12)
	_key_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_key_label.add_theme_constant_override("outline_size", 4)
	_key_label.offset_left = 6.0
	_key_label.offset_top = 2.0
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_key_label)

	_apply_border(EMPTY_BORDER, 1)


## Puts one item in the slot, or empties it when there is nothing to show.
func show_item(item: WeaponData, is_selected: bool) -> void:
	_icon.show_item(item)

	if not item:
		_apply_border(EMPTY_BORDER, 1)
		return

	# The rarity tint is the same one the model gets, so the two always agree.
	var border: Color = item.get_rarity_color()
	# The selected slot is called out by a thicker border rather than another colour.
	_apply_border(border, 3 if is_selected else 1)


## Numbers the slot for the key that selects it, counting from one.
func set_slot_number(number: int) -> void:
	_key_label.text = str(number)


## Repaints the border, which is what carries both rarity and selection.
func _apply_border(color: Color, width: int) -> void:
	_style.border_color = color
	_style.set_border_width_all(width)
