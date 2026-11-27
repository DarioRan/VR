extends Node3D
## Dev preview: the XR rig plus ONE room, to try a room on its own.
## Open tests/room_preview.tscn, set `room_scene` in the inspector, press F6
## (desktop simulator) or deploy with this as the main scene (Quest).
## Delete once the team's RoomSandbox.tscn from the starter kit exists.

@export var room_scene: PackedScene


func _ready() -> void:
	if room_scene == null:
		push_warning("room_preview: set room_scene in the inspector")
		return
	var room := room_scene.instantiate()
	add_child(room)  # the room registers itself with RoomManager in its _ready()
	RoomManager.activate(room.room_id)
