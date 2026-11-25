class_name Room
extends Node3D
## Contract for every room scene (plan Section 5.3). Owner: C.
##
## Put this script on the root of rooms/room_XX.tscn and add:
##   - a Marker3D called "Spawn"
##   - one Marker3D called "Door_<target_room_id>" per exit (for example "Door_room_02")
## The room is centred on the play area: (0, 0, 0) is the centre of the taped square.

@export var room_id: StringName = &""
@export var display_name: String = ""
## Virtual floor size in metres (x = width, y = depth).
## Anything larger than PlayArea.SIZE is reached with stride scaling.
@export var floor_size: Vector2 = PlayArea.SIZE
## Upper limit for the stride gain in this room (the paper uses 2.0).
@export var max_stride_gain: float = 2.0

var stride_gain: Vector2:
	get:
		return PlayArea.stride_gain_for(floor_size, max_stride_gain)


func _ready() -> void:
	if room_id == &"":
		push_error("Room '%s' has no room_id" % name)
		return
	RoomManager.register_room(self)


func get_spawn() -> Marker3D:
	return get_node_or_null(^"Spawn") as Marker3D


func get_door(target_room_id: StringName) -> Marker3D:
	return get_node_or_null(NodePath("Door_%s" % target_room_id)) as Marker3D


## Called by RoomManager. An inactive room is hidden and stops processing.
## Physics bodies inside are removed from the physics world while disabled
## (CollisionObject3D.disable_mode defaults to REMOVE).
func set_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
