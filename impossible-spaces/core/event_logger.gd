extends Node
## Autoload "EventLogger" (plan Section 5.7 and 8.2). Owner: D.
## Named EventLogger, not Logger, because Godot already has a built-in Logger class.
##
## One CSV per session in user://logs/. On the Quest pull them with:
##   adb pull /sdcard/Android/data/<package name>/files/logs/

const HEADER := "t_ms,participant,technique,room,event,head_x,head_z,data"

var participant_id: String = "P00"
var file_path: String = ""

var _file: FileAccess
var _start_ms: int = 0


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute("user://logs")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	file_path = "user://logs/session_%s.csv" % stamp
	_file = FileAccess.open(file_path, FileAccess.WRITE)
	if _file == null:
		push_error("EventLogger: cannot open %s" % file_path)
		return
	_file.store_line(HEADER)
	RoomManager.room_entered.connect(func(_id: StringName, _t: int) -> void: log_event("room_entered"))
	RoomManager.room_exited.connect(func(id: StringName) -> void: log_event("room_exited", {"room": id}))
	RoomManager.technique_changed.connect(func(_t: int) -> void: log_event("technique_changed"))
	log_event("session_start")


func _exit_tree() -> void:
	log_event("session_end")
	if _file != null:
		_file.close()


## Write one row. `data` is stored as JSON in the last column.
func log_event(event_name: String, data: Dictionary = {}) -> void:
	if _file == null:
		return
	var head := Vector3.ZERO
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		head = cam.global_position
	var room := RoomManager.current_room.room_id if RoomManager.current_room != null else &""
	var json := JSON.stringify(data).replace("\"", "\"\"")
	_file.store_line("%d,%s,%s,%s,%s,%.3f,%.3f,\"%s\"" % [
		Time.get_ticks_msec() - _start_ms,
		participant_id,
		Connector.technique_name(RoomManager.current_technique),
		room,
		event_name,
		head.x,
		head.z,
		json,
	])
	_file.flush()
