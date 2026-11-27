class_name OfficeSafe
extends Node3D
## P2: the office safe (plan "Escape mode" and "Cross-room flags"). Owner: D (Dario).
##
## A floor safe with a keypad. The right code opens the door; the office's
## painting piece is inside (PieceSlot until Piece.tscn exists). In Sofia's lobby
## plan the safe stands at the end of the office lane, facing the player.
## The code is on a note in the office for now (code_clue.gd); later one digit is
## seen only through Ahmed's portal window.
##
## Press keys by touching them with a hand (the rig's hand spheres, radius 0.1 m).
## Desktop, debug builds: numpad digits, numpad Enter = OK, numpad . = clear.
##
## On success: sets flag `safe_open` in PuzzleState (once the autoload exists),
## emits `solved`, logs puzzle_solved {"id": "P2"}.
## Every OK logs code_entered {"id": "P2", "ok": bool, "entry": "..."}.

signal solved
signal code_entered(ok: bool)

@export var code: String = "4719"
@export var puzzle_id: String = "P2"
@export var flag: StringName = &"safe_open"
## Radius of what presses the keys. The rig's hand spheres are 0.1 m;
## set about 0.01 with finger-tip hands (and poke_offset to the finger tip).
@export var poke_radius: float = 0.1
## Poke point in controller space.
@export var poke_offset: Vector3 = Vector3.ZERO

const KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]
const KEY_SIZE := Vector3(0.045, 0.04, 0.015)
const KEY_PITCH := Vector2(0.06, 0.05)
## The hand has to pull back this far past touching before it can press again.
const RELEASE_MARGIN := 0.03
## Opens towards the player's left, flat against the side, clear of the lane.
const OPEN_ANGLE_DEG := -90.0
const COLOR_IDLE := Color(0.55, 1.0, 0.6)
const COLOR_ERR := Color(1.0, 0.3, 0.25)

var is_open: bool = false
var entry: String = ""

var _controllers: Array[XRController3D] = []
var _held: Dictionary = {}  # XRController3D -> true while touching the keypad
var _key_meshes: Array[MeshInstance3D] = []
var _message_timer: SceneTreeTimer

@onready var _keypad: Node3D = $Keypad
@onready var _display: Label3D = $Display
@onready var _hinge: Node3D = $DoorHinge


func _ready() -> void:
	_build_keys()
	_update_display()
	for n in get_tree().root.find_children("*", "XRController3D", true, false):
		_controllers.append(n)
	get_tree().node_added.connect(_on_node_added)


## Press one key: "0".."9", "C" (clear) or "OK" (check the code).
func press(key: String) -> void:
	if is_open:
		return
	var i := KEYS.find(key)
	if i >= 0:
		_animate_key(i)
	match key:
		"C":
			entry = ""
		"OK":
			_submit()
			return
		_:
			if entry.length() < code.length():
				entry += key
	_update_display()


func open() -> void:
	if is_open:
		return
	is_open = true
	entry = ""
	_display.text = "OPEN"
	_display.modulate = COLOR_IDLE
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_hinge, "rotation_degrees:y", OPEN_ANGLE_DEG, 1.2)
	_set_flag()
	EventLogger.log_event("puzzle_solved", {"id": puzzle_id})
	solved.emit()


func _submit() -> void:
	var ok := entry == code
	EventLogger.log_event("code_entered", {"id": puzzle_id, "ok": ok, "entry": entry})
	code_entered.emit(ok)
	if ok:
		open()
		return
	entry = ""
	_display.text = "ERROR"
	_display.modulate = COLOR_ERR
	_message_timer = get_tree().create_timer(1.0)
	_message_timer.timeout.connect(_update_display)


func _update_display() -> void:
	if is_open:
		return
	var s := PackedStringArray()
	for i in code.length():
		s.append(entry[i] if i < entry.length() else "_")
	_display.text = " ".join(s)
	_display.modulate = COLOR_IDLE


func _set_flag() -> void:
	# PuzzleState comes with the starter kit; its API name is not fixed yet.
	var ps := get_node_or_null(^"/root/PuzzleState")
	if ps != null and ps.has_method(&"set_flag"):
		ps.call(&"set_flag", flag, true)


# --- Keypad -----------------------------------------------------------------

## Key i in keypad space. The keypad faces -Z, so the player's left is +X.
func _key_center(i: int) -> Vector2:
	@warning_ignore("integer_division")
	var row := i / 3
	var col := i % 3
	return Vector2((1 - col) * KEY_PITCH.x, (1.5 - row) * KEY_PITCH.y)


func _key_at(p: Vector2) -> int:
	for i in KEYS.size():
		var d := (p - _key_center(i)).abs()
		if d.x <= KEY_PITCH.x * 0.5 and d.y <= KEY_PITCH.y * 0.5:
			return i
	return -1


func _build_keys() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.82)
	var box := BoxMesh.new()
	box.size = KEY_SIZE
	for i in KEYS.size():
		var key := MeshInstance3D.new()
		key.name = "Key_" + KEYS[i]
		key.mesh = box
		key.material_override = mat
		var c := _key_center(i)
		key.position = Vector3(c.x, c.y, -KEY_SIZE.z * 0.5)
		var label := Label3D.new()
		label.text = KEYS[i]
		label.font_size = 48
		label.pixel_size = 0.0004
		label.outline_size = 0
		label.modulate = Color(0.1, 0.1, 0.1)
		label.rotation_degrees.y = 180.0  # face -Z, towards the player
		label.position.z = -KEY_SIZE.z * 0.5 - 0.001
		key.add_child(label)
		_keypad.add_child(key)
		_key_meshes.append(key)


func _animate_key(i: int) -> void:
	var key := _key_meshes[i]
	var t := create_tween()
	t.tween_property(key, "position:z", -KEY_SIZE.z * 0.15, 0.06)
	t.tween_property(key, "position:z", -KEY_SIZE.z * 0.5, 0.1)


func _on_node_added(node: Node) -> void:
	if node is XRController3D:
		_controllers.append(node)


func _physics_process(_delta: float) -> void:
	if is_open:
		return
	for c in _controllers:
		if not is_instance_valid(c):
			continue
		var p := _keypad.to_local(c.global_transform * poke_offset)
		var front := -p.z  # distance in front of the keypad plane
		var on_pad := absf(p.x) <= KEY_PITCH.x * 1.5 and absf(p.y) <= KEY_PITCH.y * 2.0
		if _held.get(c, false):
			if front > poke_radius + RELEASE_MARGIN or not on_pad:
				_held[c] = false
			continue
		if on_pad and front <= poke_radius and front > -poke_radius:
			var k := _key_at(Vector2(p.x, p.y))
			if k >= 0:
				_held[c] = true
				c.trigger_haptic_pulse(&"haptic", 0.0, 0.4, 0.05, 0.0)
				press(KEYS[k])
	_controllers = _controllers.filter(func(c: XRController3D) -> bool: return is_instance_valid(c))


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not is_visible_in_tree():
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode >= KEY_KP_0 and k.keycode <= KEY_KP_9:
		press(str(k.keycode - KEY_KP_0))
	elif k.keycode == KEY_KP_ENTER:
		press("OK")
	elif k.keycode == KEY_KP_PERIOD:
		press("C")
