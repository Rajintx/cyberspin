class_name MapScreen
extends Control

signal node_selected(node_type: String, floor_number: int)

@onready var floors_container: HBoxContainer = %FloorsContainer
@onready var title_label: Label = %MapTitleLabel
@onready var header_stats: Label = %HeaderStats
@onready var map_pip_button: Button = %MapPipButton

# Map definition: 5 floors
var map_structure: Array[Array] = [
	# Floor 1
	[{"type": "COMBAT", "name": "Patrol Drone", "icon": "🤖", "color": Color(0.0, 0.85, 1.0)}],
	# Floor 2
	[
		{"type": "COMBAT", "name": "Sec-Bot Guard", "icon": "🦿", "color": Color(0.2, 0.6, 1.0)},
		{"type": "SHOP", "name": "Data Vendor", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 3
	[{"type": "ELITE", "name": "Viper AI Subroutine", "icon": "🐍", "color": Color(0.9, 0.1, 0.4)}],
	# Floor 4
	[
		{"type": "SHOP", "name": "Cyber Clinic & Store", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)},
		{"type": "COMBAT", "name": "Heavy Dreadnought", "icon": "🛸", "color": Color(1.0, 0.4, 0.0)}
	],
	# Floor 5
	[{"type": "BOSS", "name": "MEGACORP NEXUS CORE", "icon": "👁️", "color": Color(1.0, 0.05, 0.3)}]
]

func _ready() -> void:
	map_pip_button.pressed.connect(func():
		AudioSynth.play_click()
		WindowManager.toggle_pip_mode()
	)

func refresh_map() -> void:
	var current_floor: int = RunState.current_floor
	title_label.text = "NETWORK SECTOR MAP // FLOOR %d OF 5" % current_floor
	header_stats.text = "💳 %d BANKROLL  |  💾 %d/%d RAM  |  SECTOR %d/5" % [
		RunState.credits,
		RunState.player_ram,
		RunState.max_ram,
		RunState.current_floor
	]

	for child in floors_container.get_children():
		child.queue_free()

	for f_idx in range(map_structure.size()):
		var floor_num: int = f_idx + 1
		var nodes: Array = map_structure[f_idx]

		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(140, 0)
		col.add_theme_constant_override("separation", 16)
		col.alignment = BoxContainer.ALIGNMENT_CENTER

		var fl_title := Label.new()
		fl_title.text = "FLOOR %d" % floor_num
		fl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl_title.add_theme_font_size_override("font_size", 12)
		if floor_num == current_floor:
			fl_title.modulate = Color(0.0, 1.0, 0.5)
		elif floor_num < current_floor:
			fl_title.modulate = Color(0.4, 0.4, 0.5)
		else:
			fl_title.modulate = Color(0.7, 0.7, 0.8)
		col.add_child(fl_title)

		for node_data in nodes:
			var btn := _create_node_button(node_data, floor_num, current_floor)
			col.add_child(btn)

		floors_container.add_child(col)

func _create_node_button(node_data: Dictionary, floor_num: int, current_floor: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 80)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = "%s\n%s" % [node_data.icon, node_data.name]

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if floor_num == current_floor:
		# Current selectable node
		style.bg_color = Color(0.08, 0.12, 0.22, 0.95)
		style.border_color = node_data.color
		style.shadow_color = Color(node_data.color.r, node_data.color.g, node_data.color.b, 0.5)
		style.shadow_size = 8
		btn.disabled = false
		btn.pressed.connect(func():
			AudioSynth.play_click()
			node_selected.emit(node_data.type, floor_num)
		)
	elif floor_num < current_floor:
		# Cleared node
		style.bg_color = Color(0.04, 0.04, 0.07, 0.6)
		style.border_color = Color(0.3, 0.3, 0.4, 0.4)
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
	else:
		# Future node
		style.bg_color = Color(0.05, 0.06, 0.1, 0.8)
		style.border_color = Color(0.2, 0.3, 0.5, 0.5)
		btn.disabled = true
		btn.modulate = Color(0.7, 0.7, 0.7, 0.8)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("disabled", style)
	return btn
