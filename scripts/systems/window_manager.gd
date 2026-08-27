extends Node

signal window_mode_changed(is_pip: bool)
signal opacity_changed(alpha: float)

enum CornerDock { BOTTOM_RIGHT, BOTTOM_LEFT, TOP_RIGHT, TOP_LEFT, CUSTOM }

var is_pip_mode: bool = false
var pip_opacity: float = 0.95
var current_corner: CornerDock = CornerDock.BOTTOM_RIGHT

const NORMAL_WINDOW_SIZE: Vector2i = Vector2i(1280, 720)
const PIP_WINDOW_SIZE: Vector2i = Vector2i(620, 680)
const SCREEN_PADDING: int = 16

const RESOLUTION_PRESETS: Array[Dictionary] = [
	{"label": "1280 x 720 (Default)", "size": Vector2i(1280, 720)},
	{"label": "1600 x 900 (HD+)", "size": Vector2i(1600, 900)},
	{"label": "1920 x 1080 (Full HD)", "size": Vector2i(1920, 1080)},
	{"label": "960 x 540 (Compact)", "size": Vector2i(960, 540)}
]

var last_normal_pos: Vector2i = Vector2i(100, 100)
var current_resolution: Vector2i = Vector2i(1280, 720)
var is_fullscreen: bool = false
var is_dragging_window: bool = false
var drag_start_mouse_pos: Vector2i = Vector2i.ZERO
var drag_start_win_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_resolution(target_size: Vector2i) -> void:
	current_resolution = target_size
	if not is_pip_mode and not is_fullscreen:
		DisplayServer.window_set_size(target_size)
		get_tree().root.content_scale_size = target_size
		# Center window on current screen
		var current_screen := DisplayServer.window_get_current_screen()
		var screen_rect := DisplayServer.screen_get_usable_rect(current_screen)
		var new_pos := Vector2i(
			screen_rect.position.x + int((screen_rect.size.x - target_size.x) / 2.0),
			screen_rect.position.y + int((screen_rect.size.y - target_size.y) / 2.0)
		)
		DisplayServer.window_set_position(new_pos)
		last_normal_pos = new_pos

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen)

func set_fullscreen(enabled: bool) -> void:
	is_fullscreen = enabled
	if is_fullscreen:
		if is_pip_mode:
			set_pip_mode(false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		set_resolution(current_resolution)

func _process(_delta: float) -> void:
	if is_dragging_window:
		var current_mouse := DisplayServer.mouse_get_position()
		var new_pos := drag_start_win_pos + (current_mouse - drag_start_mouse_pos)
		DisplayServer.window_set_position(new_pos)

func toggle_pip_mode() -> void:
	set_pip_mode(not is_pip_mode)

func set_pip_mode(enable: bool) -> void:
	is_pip_mode = enable

	if is_pip_mode:
		last_normal_pos = DisplayServer.window_get_position()
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_size(PIP_WINDOW_SIZE)
		get_tree().root.content_scale_size = PIP_WINDOW_SIZE
		get_tree().root.transparent_bg = true
		snap_to_corner(current_corner)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(NORMAL_WINDOW_SIZE)
		get_tree().root.content_scale_size = NORMAL_WINDOW_SIZE
		get_tree().root.transparent_bg = false
		DisplayServer.window_set_position(last_normal_pos)

	window_mode_changed.emit(is_pip_mode)

func snap_to_corner(corner: CornerDock) -> void:
	current_corner = corner
	var current_screen := DisplayServer.window_get_current_screen()
	var screen_rect := DisplayServer.screen_get_usable_rect(current_screen)
	var win_size := DisplayServer.window_get_size()

	var target_pos := Vector2i.ZERO
	match corner:
		CornerDock.BOTTOM_RIGHT:
			target_pos = Vector2i(
				screen_rect.position.x + screen_rect.size.x - win_size.x - SCREEN_PADDING,
				screen_rect.position.y + screen_rect.size.y - win_size.y - SCREEN_PADDING
			)
		CornerDock.BOTTOM_LEFT:
			target_pos = Vector2i(
				screen_rect.position.x + SCREEN_PADDING,
				screen_rect.position.y + screen_rect.size.y - win_size.y - SCREEN_PADDING
			)
		CornerDock.TOP_RIGHT:
			target_pos = Vector2i(
				screen_rect.position.x + screen_rect.size.x - win_size.x - SCREEN_PADDING,
				screen_rect.position.y + SCREEN_PADDING
			)
		CornerDock.TOP_LEFT:
			target_pos = Vector2i(
				screen_rect.position.x + SCREEN_PADDING,
				screen_rect.position.y + SCREEN_PADDING
			)
		CornerDock.CUSTOM:
			return

	DisplayServer.window_set_position(target_pos)

func set_opacity(alpha: float) -> void:
	pip_opacity = clampf(alpha, 0.25, 1.0)
	opacity_changed.emit(pip_opacity)

func start_drag() -> void:
	is_dragging_window = true
	drag_start_mouse_pos = DisplayServer.mouse_get_position()
	drag_start_win_pos = DisplayServer.window_get_position()
	current_corner = CornerDock.CUSTOM

func stop_drag() -> void:
	is_dragging_window = false
