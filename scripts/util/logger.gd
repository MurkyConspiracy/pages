# logger.gd (AutoLoad as "Logger")
extends Node

enum LogLevel { DEBUG, INFO, WARNING, ERROR }
var current_level = LogLevel.DEBUG
var log_to_file = true
var log_file_path = "user://game.log"
var enable_in_release = false  # Set to true if you want logging in release builds

func debug(message: String, context: String = "") -> void:
	_log(LogLevel.DEBUG, message, context)

func info(message: String, context: String = "") -> void:
	_log(LogLevel.INFO, message, context)

func warn(message: String, context: String = "") -> void:
	_log(LogLevel.WARNING, message, context)

func error(message: String, context: String = "") -> void:
	_log(LogLevel.ERROR, message, context)

func _log(level: LogLevel, message: String, context: String) -> void:
	# Skip logging entirely in release builds unless explicitly enabled
	if not OS.is_debug_build() and not enable_in_release:
		return
	
	if level < current_level:
		return
	
	# Auto-detect context from call stack if not provided
	if context.is_empty():
		context = _get_caller_context()
	
	var timestamp = Time.get_datetime_string_from_system()
	var level_str = LogLevel.keys()[level]
	var ctx = (" [%s]" % context) if context else ""
	var formatted = "[%s] %s%s: %s" % [timestamp, level_str, ctx, message]
	
	match level:
		LogLevel.WARNING: push_warning(formatted)
		LogLevel.ERROR: push_error(formatted)
		_: print(formatted)
	
	if log_to_file:
		_write_to_file(formatted)

func _get_caller_context() -> String:
	var stack = get_stack()
	
	if stack.size() >= 4:
		var caller = stack[3]
		var source = caller.get("source", "")
		
		if source:
			var filename = source.get_file().get_basename()
			return filename
	
	return "Unknown"

func _write_to_file(text: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(text)
