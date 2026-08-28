class_name CharacterSelect
extends Control

signal specialist_chosen(specialist_type: RunState.SpecialistClass)

@onready var margin_container: MarginContainer = %Margin
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var scroll_container: ScrollContainer = %ScrollContainer

@onready var sniper_card: PanelContainer = %SniperCard
@onready var tank_card: PanelContainer = %TankCard
@onready var hacker_card: PanelContainer = %HackerCard
@onready var gambler_card: PanelContainer = %GamblerCard

@onready var sniper_btn: Button = %SniperBtn
@onready var tank_btn: Button = %TankBtn
@onready var hacker_btn: Button = %HackerBtn
@onready var gambler_btn: Button = %GamblerBtn

func _ready() -> void:
	sniper_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.SNIPER))
	tank_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.TANK))
	hacker_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.HACKER))
	gambler_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.GAMBLER))

	scroll_container.gui_input.connect(_on_scroll_container_gui_input)
	WindowManager.window_mode_changed.connect(_on_window_mode_changed)
	_on_window_mode_changed(WindowManager.is_pip_mode)

func _on_window_mode_changed(is_pip: bool) -> void:
	if is_pip:
		margin_container.add_theme_constant_override("margin_left", 14)
		margin_container.add_theme_constant_override("margin_right", 14)
		margin_container.add_theme_constant_override("margin_top", 44)
		margin_container.add_theme_constant_override("margin_bottom", 14)
		title_label.add_theme_font_size_override("font_size", 18)
		subtitle_label.add_theme_font_size_override("font_size", 11)
	else:
		margin_container.add_theme_constant_override("margin_left", 32)
		margin_container.add_theme_constant_override("margin_right", 32)
		margin_container.add_theme_constant_override("margin_top", 24)
		margin_container.add_theme_constant_override("margin_bottom", 24)
		title_label.add_theme_font_size_override("font_size", 24)
		subtitle_label.add_theme_font_size_override("font_size", 12)

func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_container.scroll_horizontal -= 50
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_container.scroll_horizontal += 50
			get_viewport().set_input_as_handled()

func _choose_class(cls: RunState.SpecialistClass) -> void:
	AudioSynth.play_jackpot()
	specialist_chosen.emit(cls)

func reset_view() -> void:
	visible = true
	if is_instance_valid(scroll_container):
		scroll_container.scroll_horizontal = 0
