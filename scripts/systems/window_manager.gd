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

var last_normal_pos: Vector2i = Vector2i(100, 100)
var is_dragging_window: bool = false
var drag_start_mouse_pos: Vector2i = Vector2i.ZERO
var drag_start_win_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
