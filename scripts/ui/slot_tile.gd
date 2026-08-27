class_name SlotTile
extends PanelContainer

signal lock_toggled(slot_index: int, is_locked: bool)

enum HazardType {
	NONE,
	SPIKE,  # 📌 Deals direct damage to Firewall/Bankroll on reel settle
	POISON  # ☣️ Drains Credits every turn until cleansed
}

@export var slot_index: int = 0

var current_symbol: SymbolData
var is_locked: bool = false
var is_spinning: bool = false
var is_corrupted: bool = false
var hazard_type: HazardType = HazardType.NONE

@onready var lock_button: Button = %LockButton
@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel
@onready var mult_label: Label = %MultLabel
@onready var glow_rect: ColorRect = %GlowRect
@onready var shimmer_overlay: ColorRect = %ShimmerOverlay
@onready var hazard_overlay: ColorRect = %HazardOverlay
@onready var hazard_badge: Label = %HazardBadge
@onready var corrupt_overlay: ColorRect = %CorruptOverlay

var _base_style: StyleBoxFlat

func _ready() -> void:
	_base_style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", _base_style)

	lock_button.toggled.connect(_on_lock_button_toggled)
	glow_rect.modulate.a = 0.0
	hazard_overlay.visible = false
	hazard_badge.visible = false
	corrupt_overlay.visible = false
	mult_label.visible = false

func _on_lock_button_toggled(button_pressed: bool) -> void:
	if is_corrupted:
		lock_button.button_pressed = true
		return
	is_locked = button_pressed
	lock_button.text = "🔒" if is_locked else "🔓"
	_update_border_color(Color(1.0, 0.85, 0.2) if is_locked else (current_symbol.icon_color if current_symbol else Color.WHITE))
	lock_toggled.emit(slot_index, is_locked)

func set_locked(locked: bool) -> void:
	is_locked = locked
	lock_button.set_pressed_no_signal(locked)
	lock_button.text = "🔒" if locked else "🔓"
	_update_border_color(Color(1.0, 0.85, 0.2) if locked else (current_symbol.icon_color if current_symbol else Color.WHITE))

func set_symbol(sym: SymbolData, calculated_mult: float = 1.0) -> void:
	current_symbol = sym
	if sym == null:
		icon_label.text = "·"
		name_label.text = "EMPTY"
		value_label.text = ""
		mult_label.visible = false
		return

	icon_label.text = sym.icon_glyph
	name_label.text = sym.display_name
	name_label.modulate = sym.icon_color

	if calculated_mult > 1.0:
		mult_label.visible = true
		mult_label.text = "x%.1f" % calculated_mult
		value_label.text = "%d" % int(round(sym.base_chips * calculated_mult))
		value_label.modulate = Color(1.0, 0.9, 0.3)
	else:
		if sym.symbol_type == SymbolData.SymbolType.RAM:
			value_label.text = "+%d 💾" % sym.base_chips
		elif sym.symbol_type == SymbolData.SymbolType.BATTERY:
			value_label.text = "+50%"
		elif sym.symbol_type == SymbolData.SymbolType.MINER:
			value_label.text = "+%d 💳" % sym.base_chips
		else:
			value_label.text = "%d" % sym.base_chips
		mult_label.visible = false
		value_label.modulate = Color(0.9, 0.9, 1.0)

	_update_tooltip()
	_update_visual_styling()

func set_hazard(hazard: HazardType) -> void:
	hazard_type = hazard
	_update_visual_styling()
	_update_tooltip()

func clear_hazard() -> void:
	hazard_type = HazardType.NONE
	_update_visual_styling()
	_update_tooltip()

func _update_visual_styling() -> void:
	if hazard_type == HazardType.SPIKE:
		hazard_overlay.visible = true
		hazard_overlay.color = Color(1.0, 0.1, 0.25, 0.35)
		hazard_badge.visible = true
		hazard_badge.text = "📌"
		_update_border_color(Color(1.0, 0.2, 0.3))
	elif hazard_type == HazardType.POISON:
		hazard_overlay.visible = true
		hazard_overlay.color = Color(0.6, 0.1, 1.0, 0.35)
		hazard_badge.visible = true
		hazard_badge.text = "☣️"
		_update_border_color(Color(0.8, 0.2, 1.0))
	else:
		hazard_overlay.visible = false
		hazard_badge.visible = false
		if current_symbol:
			_update_border_color(current_symbol.icon_color)
		else:
			_update_border_color(Color(0.2, 0.2, 0.3, 0.4))

func _update_tooltip() -> void:
	var base_tip: String = ""
	if current_symbol:
		base_tip = "[%s]\nType: %s\nChips: %d | Mult: +%.1f\n%s" % [
			current_symbol.display_name,
			current_symbol.get_type_name(),
			current_symbol.base_chips,
			current_symbol.mult_add,
			current_symbol.description
		]

	if hazard_type == HazardType.SPIKE:
		base_tip += "\n\n⚠️ [📌 SPIKE TRAP ARMED]\nWhen reel settles here, triggers direct damage to Firewall/Bankroll!"
	elif hazard_type == HazardType.POISON:
		base_tip += "\n\n☣️ [MALWARE POISON INFESTATION]\nDrains Credits on each turn until cleansed!"

	tooltip_text = base_tip

func _update_border_color(color: Color) -> void:
	if _base_style:
		_base_style.border_color = color
		_base_style.shadow_color = Color(color.r, color.g, color.b, 0.3)

func play_spin_animation(final_sym: SymbolData, delay: float = 0.0) -> void:
	if is_locked or is_corrupted:
		return

	is_spinning = true
	var spd := RunState.game_speed
	var tween := create_tween()
	if delay > 0:
		tween.tween_interval(delay)

	# Decelerating 7-step spin tick sequence
	var intervals: Array[float] = [0.06, 0.07, 0.08, 0.10, 0.13, 0.17, 0.22]
	for i in range(intervals.size()):
		var step_dur: float = intervals[i] / spd
		tween.tween_callback(func():
			var dummy_glyph: String = ["⚡", "🛡️", "💾", "🔋", "🔥", "☣️", "7️⃣", "💎"][randi() % 8]
			icon_label.text = dummy_glyph
			icon_label.modulate = Color(randf_range(0.4, 1.0), randf_range(0.4, 1.0), 1.0)
			AudioSynth.play_spin_tick()
		)
		tween.tween_interval(step_dur)

	# Land and set final
	tween.tween_callback(func():
		set_symbol(final_sym)
		is_spinning = false
		pulse_land()
	)

func pulse_land() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func highlight_synergy(col: Color = Color.WHITE) -> void:
	glow_rect.color = col
	var tween := create_tween()
	tween.tween_property(glow_rect, "modulate:a", 0.6, 0.15)
	tween.tween_property(glow_rect, "modulate:a", 0.0, 0.3)

func play_hazard_trigger_fx() -> void:
	var tween := create_tween()
	hazard_overlay.modulate.a = 1.0
	tween.tween_property(hazard_overlay, "modulate:a", 0.3, 0.25)
	AudioSynth.play_boss_hit()

func set_corrupted(corrupted: bool) -> void:
	is_corrupted = corrupted
	corrupt_overlay.visible = corrupted
	lock_button.disabled = corrupted
	if corrupted:
		is_locked = true
		lock_button.button_pressed = true
		lock_button.text = "⚡"

func reset_tile_visuals() -> void:
	is_locked = false
	is_spinning = false
	is_corrupted = false
	hazard_type = HazardType.NONE
	lock_button.button_pressed = false
	lock_button.disabled = false
	lock_button.text = "🔓"
	glow_rect.modulate.a = 0.0
	hazard_overlay.visible = false
	hazard_badge.visible = false
	corrupt_overlay.visible = false
	mult_label.visible = false
	scale = Vector2.ONE
	_update_visual_styling()
