class_name RewardScreen
extends Control

signal reward_completed()

@onready var cards_container: HBoxContainer = %CardsContainer
@onready var skip_button: Button = %SkipButton
@onready var victory_label: Label = %VictoryLabel
@onready var credits_reward_label: Label = %CreditsRewardLabel

var _current_choices: Array[SymbolData] = []

func _ready() -> void:
	skip_button.pressed.connect(_on_skip_pressed)

func show_rewards(earned_credits: int) -> void:
	victory_label.text = "CORP ENFORCER PURGED // SECTOR CLEARED"
	credits_reward_label.text = "+%d CREDITS TRANSFERRED TO WALLET" % earned_credits
	_current_choices = RunState.get_random_draft_symbols(3)
	_build_choice_cards()

func _build_choice_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for i in range(_current_choices.size()):
		var sym: SymbolData = _current_choices[i]
		var card := _create_reward_card(sym, i)
		cards_container.add_child(card)

func _create_reward_card(sym: SymbolData, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 260)
	panel.pivot_offset = Vector2(90, 130)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = sym.icon_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(sym.icon_color.r, sym.icon_color.g, sym.icon_color.b, 0.35)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Rarity badge
	var rarity_lbl := Label.new()
	rarity_lbl.text = SymbolData.Rarity.keys()[sym.rarity]
	rarity_lbl.add_theme_font_size_override("font_size", 10)
	rarity_lbl.modulate = Color(0.7, 0.7, 0.9)
	vbox.add_child(rarity_lbl)

	# Big Glyph
	var glyph_lbl := Label.new()
	glyph_lbl.text = sym.icon_glyph
	glyph_lbl.add_theme_font_size_override("font_size", 44)
	glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(glyph_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = sym.display_name
	name_lbl.modulate = sym.icon_color
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = sym.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.modulate = Color(0.8, 0.85, 0.95)
	vbox.add_child(desc_lbl)

	# Pick Button
	var btn := Button.new()
	btn.text = "INSTALL CHIP"
	btn.custom_minimum_size = Vector2(0, 36)
	btn.focus_mode = Control.FOCUS_NONE

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = sym.icon_color * 0.8
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.1))

	btn.pressed.connect(func(): _on_card_selected(index))
	vbox.add_child(btn)

	return panel

func _on_card_selected(index: int) -> void:
	if index >= 0 and index < _current_choices.size():
		var chosen: SymbolData = _current_choices[index]
		RunState.add_symbol(chosen)
		AudioSynth.play_jackpot()
		reward_completed.emit()

func _on_skip_pressed() -> void:
	RunState.modify_credits(15)
	AudioSynth.play_click()
	reward_completed.emit()
