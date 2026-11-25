extends Node
## Autoload "RoomManager" (plan Section 5.4). Owner: A.
##
## All rooms sit on the same physical floor (the play area). Only one room is
## active at a time: visible, processing and colliding. The others are hidden.

signal room_entered(room_id: StringName, technique: int)
signal room_exited(room_id: StringName)
signal technique_changed(technique: int)

var current_room: Room = null
var current_technique: int = Connector.Technique.PORTAL

var _rooms: Dictionary[StringName, Room] = {}


## Rooms call this from their own _ready(). New rooms start hidden.
func register_room(room: Room) -> void:
	if _rooms.has(room.room_id) and _rooms[room.room_id] != room:
		push_warning("Duplicate room_id '%s'" % room.room_id)
	_rooms[room.room_id] = room
	if room != current_room:
		room.set_active(false)


func get_room(room_id: StringName) -> Room:
	return _rooms.get(room_id)


func room_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_rooms.keys())
	return ids


## Make `room_id` the only active room.
func activate(room_id: StringName, technique: int = current_technique) -> void:
	var next: Room = _rooms.get(room_id)
	if next == null:
		push_warning("RoomManager.activate: unknown room '%s'" % room_id)
		return
	if next == current_room:
		return
	if current_room != null:
		current_room.set_active(false)
		room_exited.emit(current_room.room_id)
	current_room = next
	current_room.set_active(true)
	room_entered.emit(room_id, technique)


## Get the next room ready without showing it (for example to render a portal preview).
## Named prepare_room because `preload` is a GDScript keyword.
func prepare_room(room_id: StringName) -> void:
	var room: Room = _rooms.get(room_id)
	if room != null and room != current_room:
		room.process_mode = Node.PROCESS_MODE_INHERIT


func set_technique(technique: int) -> void:
	if technique == current_technique:
		return
	current_technique = technique
	technique_changed.emit(technique)


func on_connector_crossed(connector: Connector, _from_room: StringName, to_room: StringName) -> void:
	activate(to_room, connector.technique)
