extends Node
## Autoload "EventLogger" (plan Section 5.7 and 8.2). Owner: D.
## Named EventLogger, not Logger, because Godot already has a built-in Logger class.
##
## One CSV per session in user://logs/. On the Quest pull them with:
##   adb pull /sdcard/Android/data/<package name>/files/logs/
##
## Columns: the `technique` column is the selected layout technique
## (RoomManager.current_technique). The connector actually used for a room change
## is in the data of `room_entered` as "via".
##
## Event names (use exactly these so the log analysis can find them):
##   session_start, session_end
##   participant_set                      when set_participant() is called
##   room_entered    {"via": "CORRIDOR"}  logged automatically from RoomManager
##   room_exited     {"room": "room_01"}  logged automatically from RoomManager
##   technique_changed                    logged automatically from RoomManager
##   boundary_hit                         BoundaryMonitor
##   poi_collected   {"poi_id": "..."}    tour task
##   piece_collected {"piece_id": 6}      painting pieces (1 to 9)
##   puzzle_solved   {"id": "P1"}         PuzzleState (P1, P2, safe, exit...)
##   debug_locomotion_used                DebugLocomotion, once per session

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
	RoomManager.room_entered.connect(func(_id: StringName, t: int) -> void:
		log_event("room_entered", {"via": Connector.technique_name(t)}))
	RoomManager.room_exited.connect(func(id: StringName) -> void: log_event("room_exited", {"room": id}))
	RoomManager.technique_changed.connect(func(_t: int) -> void: log_event("technique_changed"))
	log_event("session_start")


func _exit_tree() -> void:
	log_event("session_end")
	if _file != null:
		_file.close()


## Set the participant for the next rows (pilot: P01, P02...). Commas are
## replaced so the CSV stays valid.
func set_participant(id: String) -> void:
	id = id.strip_edges().replace(",", "_")
	if id.is_empty():
		push_warning("EventLogger.set_participant: empty id ignored")
		return
	participant_id = id
	log_event("participant_set")


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
