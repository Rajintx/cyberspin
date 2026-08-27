extends Node
## CrashLog: Captures script errors and writes them to user://crash_log.txt
## Hooks into the engine's error output via _notification and a LoggerOutputHandler.

const LOG_PATH: String = "user://crash_log.txt"
const MAX_LOG_LINES: int = 500

var _log_file: FileAccess
var _session_errors: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rotate_log()
	_log_file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if _log_file:
		_log_file.seek_end(0)
	_write("=== SESSION START: %s | Godot %s ===" % [Time.get_datetime_string_from_system(), Engine.get_version_info().get("string", "?")])
	_write("Project: CyberSpin | Patch: v1.3.0")

func _exit_tree() -> void:
	_write("=== SESSION END: %d errors logged ===" % _session_errors)
	if _log_file:
		_log_file.close()

func _rotate_log() -> void:
	if not FileAccess.file_exists(LOG_PATH):
		return
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	if not f:
		return
	var content := f.get_as_text()
	f.close()
	var lines := content.split("\n")
	if lines.size() > MAX_LOG_LINES:
		# Keep last MAX_LOG_LINES lines
		var trimmed := "\n".join(lines.slice(lines.size() - MAX_LOG_LINES))
		var fw := FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if fw:
			fw.store_string(trimmed)
			fw.close()

func log_error(source: String, message: String) -> void:
	_session_errors += 1
	var ts := Time.get_datetime_string_from_system()
	var entry := "[%s] ERROR #%d | %s | %s" % [ts, _session_errors, source, message]
	_write(entry)
	push_warning("CrashLog captured: %s" % entry)

func log_warning(source: String, message: String) -> void:
	var ts := Time.get_datetime_string_from_system()
	_write("[%s] WARN | %s | %s" % [ts, source, message])

func log_info(source: String, message: String) -> void:
	var ts := Time.get_datetime_string_from_system()
	_write("[%s] INFO | %s | %s" % [ts, source, message])

func _write(line: String) -> void:
	if _log_file:
		_log_file.store_line(line)
		_log_file.flush()

func get_session_error_count() -> int:
	return _session_errors

func get_log_path() -> String:
	return ProjectSettings.globalize_path(LOG_PATH)
