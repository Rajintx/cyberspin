class_name PiPOverlay
extends Control

@onready var drag_header: PanelContainer = %DragHeader
@onready var snap_menu_btn: MenuButton = %SnapMenuBtn
@onready var opacity_slider: HSlider = %OpacitySlider
@onready var expand_btn: Button = %ExpandBtn
@onready var auto_spin_btn: Button = %AutoSpinBtn

var is_auto_spinning: bool = false
var _auto_spin_timer: float = 0.0

func _ready() -> void:
	setup_snap_menu()
	connect_signals()
	_on_opacity_changed(WindowManager.pip_opacity)

func _process(delta: float) -> void:
	if not visible:
		return

	if is_auto_spinning:
		var spd := RunState.game_speed
		_auto_spin_timer += delta * spd
		if _auto_spin_timer >= 1.4:
			_auto_spin_timer = 0.0
			_try_trigger_auto_spin()

func setup_snap_menu() -> void:
	var popup := snap_menu_btn.get_popup()
	popup.clear()
	popup.add_item("↘️ Bottom-Right", 0)
	popup.add_item("↙️ Bottom-Left", 1)
	popup.add_item("↗️ Top-Right", 2)
	popup.add_item("↖️ Top-Left", 3)
	popup.id_pressed.connect(func(id: int):
		var corners: Array[WindowManager.CornerDock] = [
			WindowManager.CornerDock.BOTTOM_RIGHT,
			WindowManager.CornerDock.BOTTOM_LEFT,
			WindowManager.CornerDock.TOP_RIGHT,
			WindowManager.CornerDock.TOP_LEFT
		]
		WindowManager.snap_to_corner(corners[id])
	)

func connect_signals() -> void:
	expand_btn.pressed.connect(func():
		AudioSynth.play_click()
		WindowManager.set_pip_mode(false)
	)

	opacity_slider.value = WindowManager.pip_opacity * 100.0
	opacity_slider.value_changed.connect(func(val: float):
		WindowManager.set_opacity(val / 100.0)
	)
	WindowManager.opacity_changed.connect(_on_opacity_changed)

	drag_header.gui_input.connect(_on_header_gui_input)
	auto_spin_btn.toggled.connect(_on_auto_spin_toggled)

func _on_opacity_changed(alpha: float) -> void:
	var parent_game := get_parent() as Control
	if parent_game:
		parent_game.modulate.a = alpha

func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				WindowManager.start_drag()
			else:
				WindowManager.stop_drag()

func _on_auto_spin_toggled(toggled_on: bool) -> void:
	is_auto_spinning = toggled_on
	AudioSynth.play_click()
	if is_auto_spinning:
		auto_spin_btn.text = "🤖 AUTO: ON"
		auto_spin_btn.modulate = Color(0.2, 1.0, 0.4)
		_try_trigger_auto_spin()
	else:
		auto_spin_btn.text = "🤖 AUTO: OFF"
		auto_spin_btn.modulate = Color(0.7, 0.7, 0.8)

func _try_trigger_auto_spin() -> void:
	var main_scene := get_tree().root.get_node_or_null("MainGame")
	if main_scene:
		var arena: CombatManager = main_scene.combat_arena
		if arena and arena.visible and arena.orbital_slot_machine.can_spin and not arena.orbital_slot_machine.is_spinning:
			arena.orbital_slot_machine.pull_lever_and_spin()
