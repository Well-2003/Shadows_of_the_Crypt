class_name HUD
extends CanvasLayer
## The scene responsible for displaying information to the player


## Colour of the stamina bar, used when the class spends stamina.
const STAMINA_COLOR: Color = Color("3d9e3dff")
## Colour of the mana bar, used when the class spends mana.
const MANA_COLOR: Color = Color("852dc4ff")
## How much darker a bar goes on the flash, 0.45 being near half as bright.
const FLASH_DARKEN: float = 0.45
## How many times a bar pulses on a single loss.
const FLASH_COUNT: int = 3
## How long the fill takes to dim, in seconds.
const FLASH_DIM_TIME: float = 0.12
## How long it takes to climb back to its own colour, in seconds.
const FLASH_RISE_TIME: float = 0.45

@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %ExperienceBar
@onready var resource_bar: ProgressBar = %ResourceBar
@onready var ammo_counter: Label = %AmmoCounter
@onready var level_label: Label = %LevelLabel
@onready var spell_bar: SpellBar = %SpellBar
@onready var crosshair: Control = %Crosshair
@onready var hotbar_row: BoxContainer = %HotbarRow

# Kept so the flash knows the colour to climb back to, and which one is playing.
var _health_color: Color = Color.WHITE
var _resource_color: Color = Color.WHITE
var _health_tween: Tween = null
var _resource_tween: Tween = null
var _last_health: int = -1
var _last_resource: int = -1


## Builds the slots and picks up the experience the run has already earned.
func _ready() -> void:
	_build_hotbar_slots()

	# Read from the scene, so repainting the bar there is all it takes to change it.
	_health_color = health_bar.get_theme_stylebox("fill").bg_color

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

	# Only a loss flashes: healing and the first fill have nothing to call out.
	if _last_health > current:
		_health_tween = _flash_bar(health_bar, _health_color, _health_tween)

	_last_health = current


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

	_resource_color = fill.bg_color
	# Cleared, or swapping class would flash the bar on the way in.
	_last_resource = -1


## Shows how much stamina, mana or ammo is left.
func set_resource(current: int, max_value: int) -> void:
	resource_bar.max_value = max_value
	resource_bar.value = current

	ammo_counter.text = str(current) + " / " + str(max_value)

	# Only spending flashes, or the slow refill would blink the bar all the time.
	if _last_resource > current:
		_resource_tween = _flash_bar(resource_bar, _resource_color, _resource_tween)

	_last_resource = current


## Darkens a bar's fill and lets it climb back, so a loss is felt and not only read.
func _flash_bar(bar: ProgressBar, color: Color, running: Tween) -> Tween:
	# A second hit restarts the flash instead of fighting the one still playing.
	if running and running.is_running():
		running.kill()

	var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
	# Put back by hand, since a killed tween leaves the fill stopped halfway down.
	fill.bg_color = color

	var tween: Tween = create_tween()
	tween.set_loops(FLASH_COUNT)
	tween.tween_property(fill, "bg_color", color.darkened(FLASH_DARKEN), FLASH_DIM_TIME)
	tween.tween_property(fill, "bg_color", color, FLASH_RISE_TIME)

	return tween


## Redraws the whole row of slots, marking the one currently in hand.
func set_hotbar(slots: Array[WeaponData], selected_index: int) -> void:
	for index: int in hotbar_row.get_child_count():
		var slot: HotbarSlot = hotbar_row.get_child(index)
		var item: WeaponData = slots[index] if index < slots.size() else null

		slot.show_item(item, index == selected_index)


## Puts the spell cross on screen, only for a class that casts.
func setup_spellbook(hero_data: HeroClassData) -> void:
	spell_bar.visible = hero_data != null and hero_data.uses_spells


## Paints the spell cross, calling out the slot the next cast will use.
func set_spellbook(spells: Array[SpellData], selected: int) -> void:
	spell_bar.show_spells(spells, selected)


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
