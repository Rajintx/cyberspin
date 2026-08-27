class_name SettingsModal
extends Control

signal closed()

@onready var close_btn: Button = %CloseSettingsBtn
@onready var crt_toggle: CheckButton = %CrtToggle
@onready var crt_slider: HSlider = %CrtSlider
@onready var crt_val_label: Label = %CrtValLabel

@onready var resolution_opt: OptionButton = %ResolutionOpt
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var pip_opacity_slider: HSlider = %PipOpacitySlider
@onready var opacity_val_label: Label = %OpacityValLabel

func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	
	# Setup CRT Controls
	crt_toggle.toggled.connect(_on_crt_toggled)
	crt_slider.value_changed.connect(_on_crt_slider_changed)
	
	# Setup Resolution OptionButton
	resolution_opt.clear()
	for i in range(WindowManager.RESOLUTION_PRESETS.size()):
		var preset: Dictionary = WindowManager.RESOLUTION_PRESETS[i]
		resolution_opt.add_item(preset.label, i)
	resolution_opt.item_selected.connect(_on_resolution_selected)
	
	# Setup Fullscreen Toggle
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	
	# Setup PiP Opacity Slider
	pip_opacity_slider.value_changed.connect(_on_opacity_slider_changed)

func open_settings() -> void:
	visible = true
	_refresh_ui_values()

func _refresh_ui_values() -> void:
	# CRT
	crt_toggle.set_pressed_no_signal(RunState.is_crt_enabled)
	crt_slider.set_value_no_signal(RunState.crt_level * 100.0)
	_update_crt_label(RunState.crt_level)
	crt_slider.editable = RunState.is_crt_enabled

	# Resolution
	var cur_res := WindowManager.current_resolution
	var found_idx: int = 0
	for i in range(WindowManager.RESOLUTION_PRESETS.size()):
		if WindowManager.RESOLUTION_PRESETS[i].size == cur_res:
			found_idx = i
			break
	resolution_opt.select(found_idx)
	resolution_opt.disabled = WindowManager.is_fullscreen or WindowManager.is_pip_mode

	# Fullscreen
	fullscreen_toggle.set_pressed_no_signal(WindowManager.is_fullscreen)

	# Opacity
	pip_opacity_slider.set_value_no_signal(WindowManager.pip_opacity * 100.0)
	_update_opacity_label(WindowManager.pip_opacity)

func _on_crt_toggled(toggled_on: bool) -> void:
	AudioSynth.play_click()
	RunState.set_crt_enabled(toggled_on)
	crt_slider.editable = toggled_on
	if toggled_on and RunState.crt_level <= 0.01:
		RunState.set_crt_level(1.0)
		crt_slider.value = 100.0
	_update_crt_label(RunState.crt_level if toggled_on else 0.0)

func _on_crt_slider_changed(value: float) -> void:
	var lvl := value / 100.0
	RunState.set_crt_level(lvl)
	_update_crt_label(lvl)

func _update_crt_label(lvl: float) -> void:
	if not RunState.is_crt_enabled or lvl <= 0.01:
		crt_val_label.text = "OFF"
		crt_val_label.modulate = Color(0.6, 0.6, 0.7)
	else:
		crt_val_label.text = "%d%%" % int(round(lvl * 100.0))
		crt_val_label.modulate = Color(0.0, 1.0, 0.8)

func _on_resolution_selected(index: int) -> void:
	AudioSynth.play_click()
	if index >= 0 and index < WindowManager.RESOLUTION_PRESETS.size():
		var preset: Dictionary = WindowManager.RESOLUTION_PRESETS[index]
		var target_size: Vector2i = preset.size
		WindowManager.set_resolution(target_size)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	AudioSynth.play_click()
	WindowManager.set_fullscreen(toggled_on)
	resolution_opt.disabled = toggled_on

func _on_opacity_slider_changed(value: float) -> void:
	var alpha := value / 100.0
	WindowManager.set_opacity(alpha)
	_update_opacity_label(alpha)

func _update_opacity_label(alpha: float) -> void:
	opacity_val_label.text = "%d%%" % int(round(alpha * 100.0))

func _on_close_pressed() -> void:
	AudioSynth.play_click()
	visible = false
	closed.emit()
