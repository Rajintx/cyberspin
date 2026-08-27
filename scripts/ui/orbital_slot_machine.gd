class_name OrbitalSlotMachine
extends Control

signal spin_requested()
signal spin_completed(eval_result: Dictionary)
signal lock_toggled(index: int, is_locked: bool)
signal spin_failed_bankrupt()

@onready var grid_container: GridContainer = %GridContainer
@onready var boss_core: BossCore = %BossCore
@onready var lever_handle: Control = %LeverHandle
@onready var lever_knob: Button = %LeverKnob
@onready var spin_button: Button = %SpinButton
@onready var payline_canvas: Control = %PaylineCanvas
@onready var info_banner: Label = %InfoBanner

# Quick Hack Action Buttons
@onready var purge_btn: Button = %PurgeBtn
@onready var reroll_btn: Button = %RerollBtn
@onready var overdrive_btn: Button = %OverdriveBtn
@onready var bet_toggle_btn: Button = %BetToggleBtn
@onready var speed_toggle_btn: Button = %SpeedToggleBtn

# 8 perimeter slot tiles in ring order:
# 0: Top-Left (0,0), 1: Top-Mid (1,0), 2: Top-Right (2,0)
# 3: Right-Mid (2,1), 4: Bot-Right (2,2), 5: Bot-Mid (1,2)
# 6: Bot-Left (0,2), 7: Left-Mid (0,1)
var slot_tiles: Array[SlotTile] = []
var active_symbols: Array[SymbolData] = []
var locked_indices: Array[bool] = [false, false, false, false, false, false, false, false]
var corrupted_indices: Array[bool] = [false, false, false, false, false, false, false, false]

var is_spinning: bool = false
var can_spin: bool = true
var is_laser_on_cooldown: bool = false
var _lever_initial_pos: Vector2

# Payline drawing overlays
var _active_lines_to_draw: Array = []

func _ready() -> void:
	_setup_tiles()
	spin_button.pressed.connect(_on_spin_button_pressed)
	lever_knob.pressed.connect(_on_lever_pulled)
	payline_canvas.draw.connect(_on_payline_canvas_draw)
	_lever_initial_pos = lever_handle.position

	purge_btn.pressed.connect(_on_purge_pressed)
	reroll_btn.pressed.connect(_on_reroll_pressed)
	overdrive_btn.pressed.connect(_on_overdrive_pressed)
	bet_toggle_btn.pressed.connect(_on_bet_toggle_pressed)
	speed_toggle_btn.pressed.connect(_on_speed_toggle_pressed)

	RunState.spin_cost_changed.connect(_on_spin_cost_changed)
	RunState.speed_changed.connect(_on_speed_changed)

	_on_spin_cost_changed(RunState.get_current_spin_cost(), RunState.battle_turn_number)
	_on_speed_changed(RunState.game_speed)

	active_symbols.resize(8)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if can_spin and not is_spinning:
			pull_lever_and_spin()
	elif event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var slot_idx: int = event.keycode - KEY_1
			if slot_idx < 8 and not is_spinning:
				_on_tile_lock_toggled(slot_idx, not locked_indices[slot_idx])
		elif event.keycode == KEY_C and can_spin and not is_spinning:
			_on_purge_pressed()
		elif event.keycode == KEY_R and can_spin and not is_spinning:
			_on_reroll_pressed()
		elif event.keycode == KEY_O and can_spin and not is_spinning:
			_on_overdrive_pressed()
		elif event.keycode == KEY_B:
			_on_bet_toggle_pressed()
		elif event.keycode == KEY_TAB:
			_on_speed_toggle_pressed()

func _setup_tiles() -> void:
	slot_tiles.clear()
	var tile0: SlotTile = %Tile0
	var tile1: SlotTile = %Tile1
	var tile2: SlotTile = %Tile2
	var tile3: SlotTile = %Tile3
	var tile4: SlotTile = %Tile4
	var tile5: SlotTile = %Tile5
	var tile6: SlotTile = %Tile6
	var tile7: SlotTile = %Tile7

	slot_tiles = [tile0, tile1, tile2, tile3, tile4, tile5, tile6, tile7]

	for i in range(8):
		slot_tiles[i].slot_index = i
		slot_tiles[i].lock_toggled.connect(_on_tile_lock_toggled)

func populate_initial_grid(deck: Array[SymbolData]) -> void:
	if deck.is_empty():
		return
	var pool := deck.duplicate()
	pool.shuffle()
	for i in range(8):
		var sym: SymbolData = pool[i % pool.size()].duplicate()
		active_symbols[i] = sym
		slot_tiles[i].set_symbol(sym)

func set_controls_enabled(enabled: bool) -> void:
	can_spin = enabled
	if enabled:
		is_spinning = false
	spin_button.disabled = not enabled
	lever_knob.disabled = not enabled
	purge_btn.disabled = not enabled
	reroll_btn.disabled = not enabled
	overdrive_btn.disabled = not enabled
	bet_toggle_btn.disabled = not enabled

func set_pip_mode(is_pip: bool) -> void:
	spin_button.add_theme_font_size_override("font_size", 16 if is_pip else 14)
	spin_button.custom_minimum_size.y = 46 if is_pip else 40

	var act_font: int = 11 if is_pip else 9
	var act_h: int = 34 if is_pip else 28
	purge_btn.add_theme_font_size_override("font_size", act_font)
	purge_btn.custom_minimum_size.y = act_h
	reroll_btn.add_theme_font_size_override("font_size", act_font)
	reroll_btn.custom_minimum_size.y = act_h
	overdrive_btn.add_theme_font_size_override("font_size", act_font)
	overdrive_btn.custom_minimum_size.y = act_h
	bet_toggle_btn.add_theme_font_size_override("font_size", act_font)
	bet_toggle_btn.custom_minimum_size.y = act_h
	speed_toggle_btn.add_theme_font_size_override("font_size", act_font)
	speed_toggle_btn.custom_minimum_size.y = act_h

	for tile in slot_tiles:
		if is_instance_valid(tile):
			tile.set_pip_mode(is_pip)
	if is_instance_valid(boss_core):
		boss_core.set_pip_mode(is_pip)

func _on_tile_lock_toggled(slot_index: int, is_locked: bool) -> void:
	if is_spinning or not can_spin:
		return

	# Locking costs 1 RAM if newly locking
	if is_locked:
		if RunState.spend_ram(1):
			locked_indices[slot_index] = true
			slot_tiles[slot_index].set_locked(true)
			lock_toggled.emit(slot_index, true)
		else:
			slot_tiles[slot_index].set_locked(false)
			show_banner("⚠️ NOT ENOUGH RAM TO LOCK REEL! (Cost: 1 RAM)")
	else:
		locked_indices[slot_index] = false
		slot_tiles[slot_index].set_locked(false)
		lock_toggled.emit(slot_index, false)

func _on_purge_pressed() -> void:
	if is_spinning or not can_spin:
		return

	var has_hazards: bool = false
	for tile in slot_tiles:
		if tile.hazard_type != SlotTile.HazardType.NONE:
			has_hazards = true
			break

	if not has_hazards:
		show_banner("✨ No active hazards to cleanse!")
		return

	if RunState.spend_ram(1):
		AudioSynth.play_shield()
		clear_all_hazards()
		show_banner("🧹 CLEANSED: All Spikes & Poison purged from grid!")
	else:
		show_banner("⚠️ NOT ENOUGH RAM TO CLEANSE! (Cost: 1 RAM)")

func _on_reroll_pressed() -> void:
	if is_spinning or not can_spin:
		return
	if RunState.spend_ram(2):
		AudioSynth.play_laser()
		show_banner("🎲 HACK REROLL: Unlocked reels respun!")
		set_controls_enabled(false)
		is_spinning = true
		_execute_spin_visuals(false)
	else:
		show_banner("⚠️ NOT ENOUGH RAM FOR HACK REROLL! (Cost: 2 RAM)")

func _on_overdrive_pressed() -> void:
	if is_spinning or not can_spin:
		return
	if RunState.spend_ram(2):
		AudioSynth.play_jackpot()
		show_banner("⚡ OVERDRIVE: Laser Cross-Beam Guaranteed!")
		var heavy_laser := RunState.get_symbol_by_id("laser")
		if heavy_laser:
			active_symbols[1] = heavy_laser.duplicate()
			active_symbols[5] = heavy_laser.duplicate()
			slot_tiles[1].set_symbol(active_symbols[1])
			slot_tiles[5].set_symbol(active_symbols[5])
			locked_indices[1] = true
			locked_indices[5] = true
			slot_tiles[1].set_locked(true)
			slot_tiles[5].set_locked(true)
	else:
		show_banner("⚠️ NOT ENOUGH RAM FOR OVERDRIVE! (Cost: 2 RAM)")

func _on_bet_toggle_pressed() -> void:
	AudioSynth.play_click()
	RunState.cycle_bet_level()

func _on_speed_toggle_pressed() -> void:
	AudioSynth.play_click()
	RunState.cycle_game_speed()

func _on_spin_cost_changed(cost: int, turn_num: int) -> void:
	bet_toggle_btn.text = "💰 %d💳 (T%d)" % [cost, turn_num]
	if cost <= 5:
		bet_toggle_btn.modulate = Color(0.8, 0.9, 1.0)
	elif cost <= 10:
		bet_toggle_btn.modulate = Color(1.0, 0.8, 0.2)
	else:
		bet_toggle_btn.modulate = Color(1.0, 0.2, 0.5)

func _on_speed_changed(spd: float) -> void:
	if spd <= 0.6:
		speed_toggle_btn.text = "⏩ 0.6X (SLOW)"
	elif spd <= 1.0:
		speed_toggle_btn.text = "⏩ 1.0X (NORM)"
	elif spd <= 1.5:
		speed_toggle_btn.text = "⏩ 1.5X (FAST)"
	else:
		speed_toggle_btn.text = "⏩ 2.5X (TURBO)"

func show_banner(text: String) -> void:
	info_banner.text = text
	var t := create_tween()
	t.tween_property(info_banner, "modulate:a", 1.0, 0.1)
	t.tween_interval(1.8)
	t.tween_property(info_banner, "modulate:a", 0.0, 0.4)

func set_slot_hazard(slot_index: int, hazard: SlotTile.HazardType) -> void:
	if slot_index >= 0 and slot_index < 8:
		slot_tiles[slot_index].set_hazard(hazard)

func set_slot_corrupted(slot_index: int, corrupted: bool) -> void:
	if slot_index >= 0 and slot_index < 8:
		corrupted_indices[slot_index] = corrupted
		slot_tiles[slot_index].set_corrupted(corrupted)

func clear_all_hazards() -> void:
	for i in range(8):
		slot_tiles[i].clear_hazard()

func clear_all_corruptions() -> void:
	for i in range(8):
		corrupted_indices[i] = false
		slot_tiles[i].set_corrupted(false)

func reset_machine_visuals() -> void:
	for tile in slot_tiles:
		if tile:
			tile.reset_tile_visuals()
	for i in range(8):
		locked_indices[i] = false
		corrupted_indices[i] = false
	_active_lines_to_draw.clear()
	payline_canvas.queue_redraw()
	lever_handle.position = _lever_initial_pos

func _on_spin_button_pressed() -> void:
	pull_lever_and_spin()

func _on_lever_pulled() -> void:
	pull_lever_and_spin()

func pull_lever_and_spin() -> void:
	if not can_spin or is_spinning:
		return

	# Deduct spin ante from bankroll
	if not RunState.spend_spin_bet():
		show_banner("☠️ BANKRUPT! Insufficient Credits (%d💳) for spin ante (%d💳)!" % [RunState.credits, RunState.get_current_spin_cost()])
		set_controls_enabled(false)
		spin_failed_bankrupt.emit()
		return

	RunState.total_spins += 1
	set_controls_enabled(false)
	is_spinning = true
	_active_lines_to_draw.clear()
	payline_canvas.queue_redraw()

	# Lever Pull Animation
	var spd := RunState.game_speed
	AudioSynth.play_lever_pull()
	var lever_tween := create_tween()
	lever_tween.tween_property(lever_handle, "position:y", _lever_initial_pos.y + 40.0, 0.12 / spd).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	lever_tween.tween_property(lever_handle, "position:y", _lever_initial_pos.y, 0.22 / spd).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	spin_requested.emit()
	_execute_spin_visuals(true)

func _execute_spin_visuals(trigger_combat: bool) -> void:
	var deck: Array[SymbolData] = RunState.symbol_deck
	if deck.is_empty():
		return

	var pool := deck.duplicate()
	pool.shuffle()

	var new_symbols: Array[SymbolData] = []
	new_symbols.resize(8)

	for i in range(8):
		if locked_indices[i] or corrupted_indices[i]:
			new_symbols[i] = active_symbols[i]
		else:
			new_symbols[i] = pool[randi() % pool.size()].duplicate()
			active_symbols[i] = new_symbols[i]

	var spd := RunState.game_speed

	# Stagger reel spin animations clockwise around the ring
	for i in range(8):
		if not locked_indices[i] and not corrupted_indices[i]:
			slot_tiles[i].play_spin_animation(new_symbols[i], (i * 0.07) / spd)

	# Evaluate after all reels land
	var eval_timer := get_tree().create_timer((0.85 + (8 * 0.07)) / spd)
	eval_timer.timeout.connect(func():
		_on_reels_settled(new_symbols, trigger_combat)
	)

func _on_reels_settled(symbols: Array[SymbolData], trigger_combat: bool) -> void:
	var is_vuln: bool = (boss_core.glitch_stacks > 0)
	var active_relics: Array[RelicData] = RunState.relics
	var bet_mult: float = RunState.get_current_mult()
	var eval_result := OrbitalEvaluator.evaluate_spin(symbols, is_vuln, active_relics, bet_mult, RunState.credits, is_laser_on_cooldown)

	# Update laser cooldown cycle for next turn
	if is_laser_on_cooldown:
		is_laser_on_cooldown = false
	elif eval_result.get("laser_fired", false):
		is_laser_on_cooldown = true

	# Apply slot multiplier labels
	for i in range(8):
		var mult: float = eval_result.slot_multipliers[i]
		slot_tiles[i].set_symbol(symbols[i], mult)

	# Highlight triggered paylines & cross-core lasers
	_active_lines_to_draw = eval_result.get("lines_triggered", [])
	payline_canvas.queue_redraw()

	if not _active_lines_to_draw.is_empty():
		AudioSynth.play_payline()
		for line in _active_lines_to_draw:
			var line_indices: Array = line.get("indices", [])
			var line_col: Color = line.get("color", Color.WHITE)
			for idx in line_indices:
				if idx >= 0 and idx < slot_tiles.size():
					slot_tiles[idx].highlight_synergy(line_col)

	if eval_result.get("is_jackpot_fever", false):
		AudioSynth.play_jackpot()
		RunState.total_jackpots += 1

	is_spinning = false

	if trigger_combat:
		spin_completed.emit(eval_result)
	else:
		set_controls_enabled(true)

func _on_payline_canvas_draw() -> void:
	for line in _active_lines_to_draw:
		var indices: Array = line.get("indices", [])
		var line_color: Color = line.get("color", Color.CYAN)
		line_color.a = 0.85

		if indices.size() == 2:
			# Cross-core laser beam
			var p1 := slot_tiles[indices[0]].global_position + (slot_tiles[indices[0]].size / 2.0) - payline_canvas.global_position
			var p2 := slot_tiles[indices[1]].global_position + (slot_tiles[indices[1]].size / 2.0) - payline_canvas.global_position
			payline_canvas.draw_line(p1, p2, line_color, 4.5, true)
			payline_canvas.draw_line(p1, p2, Color(line_color.r, line_color.g, line_color.b, 0.35), 12.0, true)
		elif indices.size() == 3:
			# Perimeter triad line
			var p1 := slot_tiles[indices[0]].global_position + (slot_tiles[indices[0]].size / 2.0) - payline_canvas.global_position
			var p2 := slot_tiles[indices[1]].global_position + (slot_tiles[indices[1]].size / 2.0) - payline_canvas.global_position
			var p3 := slot_tiles[indices[2]].global_position + (slot_tiles[indices[2]].size / 2.0) - payline_canvas.global_position
			payline_canvas.draw_line(p1, p2, line_color, 4.0, true)
			payline_canvas.draw_line(p2, p3, line_color, 4.0, true)
