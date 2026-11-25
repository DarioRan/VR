extends Node3D
## Main scene: the XR rig plus every room, all on the same physical floor. Owner: A.

@export var start_room: StringName = &"room_01"

@onready var _right_hand: XRController3D = $XROrigin3D/RightHand


func _ready() -> void:
	# Rooms registered themselves in their own _ready(), which runs before this one.
	RoomManager.activate(start_room)
	_right_hand.button_pressed.connect(_on_right_button_pressed)


## Debug until connectors exist: A button (or Tab / key 2 in the XR simulator)
## cycles through the rooms, so RoomManager can be tested on the headset.
func _on_right_button_pressed(action: String) -> void:
	if action == "ax_button":
		_cycle_room()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_cycle_room()


func _cycle_room() -> void:
	var ids := RoomManager.room_ids()
	if ids.is_empty():
		return
	var i := -1
	if RoomManager.current_room != null:
		i = ids.find(RoomManager.current_room.room_id)
	RoomManager.activate(ids[(i + 1) % ids.size()])
