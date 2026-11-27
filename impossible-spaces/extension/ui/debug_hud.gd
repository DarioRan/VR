extends Node
## Autoload "DebugHud" (plan D-02). Owner: D (Dario). Debug builds only.
##
## A small text panel fixed in the lower-left of the view:
## room and stride gain (applied gain and the pilot cap), technique, fps,
## distance to the play-area edge, participant.
## It turns red when the head is within the boundary margin.
##
## Toggle: X on the left controller (Y is the stride cap, A-07). Desktop: H
## (or hold Q + 2 in the XR simulator).
## It attaches itself to the active camera, so it works in any scene
## (main, the room sandbox...) without editing the rig.

## Position in head space, metres: left, down, forward.
@export var offset: Vector3 = Vector3(-0.16, -0.14, -0.6)
@export var visible_on_start: bool = true

const REFRESH_S := 0.25
const COLOR_OK := Color(1.0, 0.95, 0.55)
const COLOR_WARN := Color(1.0, 0.35, 0.3)
const TOGGLE_BUTTON := "ax_button"  # X on the left controller

var _label: Label3D
var _shown: bool = true
var _timer: float = 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_shown = visible_on_start
	XRServer.tracker_added.connect(_on_tracker_added)
	for tracker_name: StringName in XRServer.get_trackers(XRServer.TRACKER_CONTROLLER):
		_on_tracker_added(tracker_name, XRServer.TRACKER_CONTROLLER)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_attach_to(cam)
	_label.visible = _shown
	_timer -= delta
	if _shown and _timer <= 0.0:
		_timer = REFRESH_S
		_refresh(cam)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		toggle()


func toggle() -> void:
	_shown = not _shown
	_timer = 0.0


## The text currently shown (used by the smoke test).
func get_text() -> String:
	return _label.text if is_instance_valid(_label) else ""


func _attach_to(cam: Camera3D) -> void:
	# The label lives under the camera so it never lags behind the head.
	# If the camera was freed (scene change), the label went with it: make a new one.
	if not is_instance_valid(_label):
		_label = _make_label()
	if _label.get_parent() != cam:
		if _label.get_parent() != null:
			_label.get_parent().remove_child(_label)
		cam.add_child(_label)
		_label.position = offset


func _make_label() -> Label3D:
	var l := Label3D.new()
	l.name = "DebugHud"
	l.font_size = 32
	l.pixel_size = 0.0005
	l.outline_size = 8
	l.modulate = COLOR_OK
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	l.no_depth_test = true          # always drawn on top of the room
	l.render_priority = 10
	l.outline_render_priority = 9
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return l


func _refresh(cam: Camera3D) -> void:
	var room := RoomManager.current_room
	var room_text := "-"
	if room != null:
		room_text = String(room.room_id)
		# The gain actually applied (after the cap and the fade) comes from the rig.
		var stride := cam.get_parent().get_node_or_null(^"StrideScaler") as StrideScaler
		if stride != null:
			var g := stride.current_gain
			room_text += "  (gain %.2f x %.2f, cap %.2f)" % [g.x, g.y, stride.max_gain]
		else:
			var g := room.stride_gain
			room_text += "  (gain %.2f x %.2f)" % [g.x, g.y]

	# Camera position relative to XROrigin3D = position in the taped square.
	var edge := PlayArea.distance_to_edge(cam.position)

	_label.text = "room  %s\ntech  %s\nfps   %d\nedge  %.2f m\npid   %s" % [
		room_text,
		Connector.technique_name(RoomManager.current_technique),
		Engine.get_frames_per_second(),
		edge,
		EventLogger.participant_id,
	]
	_label.modulate = COLOR_WARN if edge < PlayArea.BOUNDARY_MARGIN else COLOR_OK


func _on_tracker_added(tracker_name: StringName, _type: int) -> void:
	if tracker_name != &"left_hand":
		return
	var tracker := XRServer.get_tracker(tracker_name) as XRPositionalTracker
	if tracker != null and not tracker.button_pressed.is_connected(_on_left_button):
		tracker.button_pressed.connect(_on_left_button)


func _on_left_button(button: String) -> void:
	if button == TOGGLE_BUTTON:
		toggle()
