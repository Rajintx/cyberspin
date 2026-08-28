class_name ShopScreen
extends Control

signal shop_closed()

@onready var margin_container: MarginContainer = %Margin
@onready var title_label: Label = %TitleLabel
@onready var credits_label: Label = %ShopCreditsLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var symbols_shelf: HBoxContainer = %SymbolsShelf
@onready var relics_shelf: HBoxContainer = %RelicsShelf
@onready var expand_ram_btn: Button = %ExpandRamBtn
@onready var restock_btn: Button = %RestockBtn
@onready var heal_button: Button = %HealButton
@onready var purge_button: Button = %PurgeButton
@onready var leave_button: Button = %LeaveButton
@onready var purge_modal: PanelContainer = %PurgeModal
@onready var purge_list: VBoxContainer = %PurgeList
@onready var close_purge_btn: Button = %ClosePurgeBtn

var for_sale_symbols: Array[SymbolData] = []
var for_sale_relics: Array[RelicData] = []

func _ready() -> void:
	expand_ram_btn.pressed.connect(_on_expand_ram_pressed)
	restock_btn.pressed.connect(_on_restock_pressed)
	heal_button.pressed.connect(_on_heal_pressed)
	purge_button.pressed.connect(_on_open_purge_pressed)
	close_purge_btn.pressed.connect(func(): purge_modal.visible = false)
	leave_button.pressed.connect(_on_leave_pressed)
	purge_modal.visible = false

	RunState.bankroll_changed.connect(func(curr: int, _max: int):
		_update_credits(curr)
		_update_ram_btn()
	)

	WindowManager.window_mode_changed.connect(_on_window_mode_changed)
	_on_window_mode_changed(WindowManager.is_pip_mode)

func _on_window_mode_changed(is_pip: bool) -> void:
	if is_pip:
		margin_container.add_theme_constant_override("margin_left", 12)
		margin_container.add_theme_constant_override("margin_right", 12)
		margin_container.add_theme_constant_override("margin_top", 44)
		margin_container.add_theme_constant_override("margin_bottom", 10)
		title_label.add_theme_font_size_override("font_size", 14)
		credits_label.add_theme_font_size_override("font_size", 11)
		leave_button.custom_minimum_size = Vector2(0, 40)
		leave_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		margin_container.add_theme_constant_override("margin_left", 24)
		margin_container.add_theme_constant_override("margin_right", 24)
		margin_container.add_theme_constant_override("margin_top", 16)
		margin_container.add_theme_constant_override("margin_bottom", 16)
		title_label.add_theme_font_size_override("font_size", 18)
		credits_label.add_theme_font_size_override("font_size", 15)
		leave_button.custom_minimum_size = Vector2(240, 38)
		leave_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func open_shop() -> void:
	if is_instance_valid(scroll_container):
		scroll_container.scroll_vertical = 0
	_update_credits(RunState.credits)
	_update_ram_btn()
	_generate_shop_inventory()
	heal_button.disabled = false
	heal_button.text = "RESTORE 15 BANKROLL (18💳)"
	purge_button.disabled = false

func _update_credits(amount: int) -> void:
	credits_label.text = "💳 BANKROLL: %d CREDITS  |  💾 %d/%d RAM" % [amount, RunState.player_ram, RunState.max_ram]

func _update_ram_btn() -> void:
	var cost := RunState.get_ram_upgrade_cost()
	if cost > 0:
		expand_ram_btn.text = "💾 +1 RAM (%d💳)" % cost
		expand_ram_btn.disabled = (RunState.credits < cost)
	else:
		expand_ram_btn.text = "MAX RAM (5/5)"
		expand_ram_btn.disabled = true

func _on_expand_ram_pressed() -> void:
	var cost := RunState.get_ram_upgrade_cost()
	if cost > 0 and RunState.credits >= cost:
		if RunState.upgrade_max_ram():
			AudioSynth.play_jackpot()
			_update_credits(RunState.credits)
			_update_ram_btn()
	else:
		AudioSynth.play_tone(150, 100, 0.15, -4.0, "saw")

func _on_restock_pressed() -> void:
	var restock_cost: int = 15
	if RunState.credits >= restock_cost:
		RunState.modify_credits(-restock_cost)
		AudioSynth.play_laser()
		_generate_shop_inventory()
	else:
		AudioSynth.play_tone(150, 100, 0.15, -4.0, "saw")

func _generate_shop_inventory() -> void:
	for child in symbols_shelf.get_children():
		child.queue_free()
	for child in relics_shelf.get_children():
		child.queue_free()

	for_sale_symbols = RunState.get_random_draft_symbols(3)
	for_sale_relics = RunState.get_random_relics(2)

	# Build Symbol cards for sale
	for sym in for_sale_symbols:
		var price: int = 16 + (sym.rarity * 10)
		var item_card := _create_symbol_shop_card(sym, price)
		symbols_shelf.add_child(item_card)

	# Build Relic cards for sale
	for relic in for_sale_relics:
		var item_card := _create_relic_shop_card(relic, relic.cost)
		relics_shelf.add_child(item_card)

func _create_symbol_shop_card(sym: SymbolData, price: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 190)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = sym.icon_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var glyph_lbl := Label.new()
	glyph_lbl.text = sym.icon_glyph
	glyph_lbl.add_theme_font_size_override("font_size", 28)
	glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(glyph_lbl)

	var name_lbl := Label.new()
	name_lbl.text = sym.display_name
	name_lbl.modulate = sym.icon_color
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = sym.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "BUY 💳%d" % price
	buy_btn.focus_mode = Control.FOCUS_NONE
	buy_btn.pressed.connect(func():
		if RunState.credits >= price:
			if not RunState.can_add_symbol():
				buy_btn.text = "DECK FULL (20/20)"
				return
			RunState.modify_credits(-price)
			RunState.add_symbol(sym)
			AudioSynth.play_jackpot()
			buy_btn.disabled = true
			buy_btn.text = "PURCHASED"
		else:
			AudioSynth.play_tone(150, 100, 0.15, -4.0, "saw")
	)
	vbox.add_child(buy_btn)

	return panel

func _create_relic_shop_card(relic: RelicData, price: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 190)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.14, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.4, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var glyph_lbl := Label.new()
	glyph_lbl.text = relic.icon_glyph
	glyph_lbl.add_theme_font_size_override("font_size", 28)
	glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(glyph_lbl)

	var name_lbl := Label.new()
	name_lbl.text = relic.display_name
	name_lbl.modulate = Color(0.9, 0.5, 1.0)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = relic.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "INSTALL 💳%d" % price
	buy_btn.focus_mode = Control.FOCUS_NONE
	buy_btn.pressed.connect(func():
		if RunState.credits >= price:
			RunState.modify_credits(-price)
			RunState.add_relic(relic)
			AudioSynth.play_jackpot()
			buy_btn.disabled = true
			buy_btn.text = "INSTALLED"
		else:
			AudioSynth.play_tone(150, 100, 0.15, -4.0, "saw")
	)
	vbox.add_child(buy_btn)

	return panel

func _on_heal_pressed() -> void:
	var heal_cost: int = 18
	if RunState.credits >= heal_cost:
		RunState.modify_credits(-heal_cost)
		RunState.add_credits(15)
		AudioSynth.play_shield()
		heal_button.disabled = true
		heal_button.text = "BANKROLL RESTORED (+15)"
	else:
		AudioSynth.play_tone(150, 100, 0.15, -4.0, "saw")

func _on_open_purge_pressed() -> void:
	var purge_cost: int = 25
	if RunState.credits < purge_cost:
		AudioSynth.play_tone(150, 100, 0.15, -4.0, "saw")
		return

	for child in purge_list.get_children():
		child.queue_free()

	for i in range(RunState.symbol_deck.size()):
		var sym: SymbolData = RunState.symbol_deck[i]
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s %s (%s, Chips: %d)" % [sym.icon_glyph, sym.display_name, sym.get_type_name(), sym.base_chips]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var del_btn := Button.new()
		del_btn.text = "PURGE (💳25)"
		var sym_idx: int = i
		del_btn.pressed.connect(func():
			RunState.modify_credits(-purge_cost)
			RunState.remove_symbol_at(sym_idx)
			AudioSynth.play_laser()
			purge_modal.visible = false
			purge_button.disabled = true
		)
		row.add_child(del_btn)
		purge_list.add_child(row)

	purge_modal.visible = true

func _on_leave_pressed() -> void:
	AudioSynth.play_click()
	shop_closed.emit()
