class_name HUD
extends CanvasLayer
## The scene responsible for displaying information to the player


## Colour of the stamina bar, used when the class spends stamina.
const STAMINA_COLOR: Color = Color(0.24, 0.62, 0.24)
## Colour of the mana bar, used when the class spends mana.
const MANA_COLOR: Color = Color(0.2, 0.42, 0.85)

@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %ExperienceBar
@onready var resource_bar: ProgressBar = %ResourceBar
@onready var ammo_counter: Label = %AmmoCounter
@onready var level_label: Label = %LevelLabel
@onready var crosshair: Control = %Crosshair
@onready var hotbar_row: HBoxContainer = %HotbarRow


## Builds the slots and picks up the experience the run has already earned.
func _ready() -> void:
	_build_hotbar_slots()

	Progression.xp_changed.connect(_on_xp_changed)
	_on_xp_changed(Progression.xp, Progression.get_xp_to_next(), Progression.level)


## Fills the row with empty slots, so Hero always finds them ready to be written to.
func _build_hotbar_slots() -> void:
	for index: int in Hotbar.SLOT_COUNT:
		var slot: HotbarSlot = HotbarSlot.new()
		hotbar_row.add_child(slot)
		# Numbered after the add, since the labels only exist once the slot is ready.
		slot.set_slot_number(index + 1)


## Function called by the Player to insert the data
func set_health(current: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


## Switches between a bar and a counter, depending on what the class spends.
func setup_resource(hero_data: HeroClassData) -> void:
	if not hero_data: return

	var is_ammo: bool = hero_data.is_ammo()
	# Ammo is a handful of arrows, and a bar of five is harder to read than a number.
	resource_bar.visible = not is_ammo
	ammo_counter.visible = is_ammo

	if is_ammo: return

	var fill: StyleBoxFlat = resource_bar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = MANA_COLOR if hero_data.resource_type == HeroClassData.ResourceType.MANA \
		else STAMINA_COLOR
	# Overridden on this bar alone, or every class would repaint the shared style.
	resource_bar.add_theme_stylebox_override("fill", fill)


## Shows how much stamina, mana or ammo is left.
func set_resource(current: int, max_value: int) -> void:
	resource_bar.max_value = max_value
	resource_bar.value = current

	ammo_counter.text = str(current) + " / " + str(max_value)


## Redraws the whole row of slots, marking the one currently in hand.
func set_hotbar(slots: Array[WeaponData], selected_index: int) -> void:
	for index: int in hotbar_row.get_child_count():
		var slot: HotbarSlot = hotbar_row.get_child(index)
		var item: WeaponData = slots[index] if index < slots.size() else null

		slot.show_item(item, index == selected_index)


## Shows the crosshair while aiming and hides it the rest of the time.
func set_crosshair_visible(should_show: bool) -> void:
	crosshair.visible = should_show


## Fills the experience bar, and shows it full once there is nothing left to gain.
func _on_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
	level_label.text = "Lv " + str(level)

	# A max level hero has no next level to fill towards, so the bar sits full.
	if xp_to_next <= 0:
		xp_bar.max_value = 1
		xp_bar.value = 1
		return

	xp_bar.max_value = xp_to_next
	xp_bar.value = current_xp
