class_name StrideScaler
extends Node
## Stride scaling (plan Section 6.6, tickets A-03, A-04, A-07). Owner: A. Child of XROrigin3D.
##
## Virtual position = play-area centre + gain * physical position, per axis.
## With gain 2 one physical step moves you two virtual steps, so a 5 m room
## fits in the 2.5 m play area. The mapping is absolute (no drift), and its base
## is the calibrated origin, which every room shares, so leaving a scaled room
## does not shift the next one.
## Assumes rooms are centred on the play area and axis-aligned with it.
##
## Gain changes (room swaps): the view would jump by (new - old) * position.
## When that jump is larger than jump_threshold, the view fades to black, the
## new gain is applied in the dark, and it fades back (A-04).

signal gain_changed(gain: Vector2)
signal cap_changed(cap: float)

@export var enabled: bool = true
## Global cap on top of each room's own max_stride_gain. The paper uses 2.0.
@export var max_gain: float = 2.0
## Caps to cycle through during the pilot (A-07). Known detection thresholds
## are about 0.86 to 1.26 (Steinicke 2010).
@export var gain_presets: Array[float] = [1.25, 1.5, 2.0]
## Jumps smaller than this (metres) are applied directly, larger ones behind a fade.
@export var jump_threshold: float = 0.05
@export var screen_fade: ScreenFade
## Optional: a node showing the play area (2.5 x 2.5 m plane). It is moved and
## scaled to show where the physical square lands in the virtual world.
@export var footprint: Node3D

var current_gain: Vector2 = Vector2.ONE

var _origin: XROrigin3D
var _camera: XRCamera3D
var _base: Transform3D
var _initial_base: Transform3D
var _pending_gain: Vector2 = Vector2.ONE
var _waiting_for_dark: bool = false


func _ready() -> void:
	_origin = get_parent() as XROrigin3D
	_camera = _origin.get_node_or_null(^"XRCamera3D") as XRCamera3D
	# Calibrated origin without any stride offset.
	_base = _origin.global_transform
	_initial_base = _base


## Back to the calibrated base: undoes debug joystick moves. Called on recenter.
func reset_base() -> void:
	_base = _initial_base


## Move the calibrated base by a world-space transform (used by DebugLocomotion).
## The current stride offset is reapplied on top in the next physics frame.
func transform_base(t: Transform3D) -> void:
	_base = t * _base


## Next preset cap (A-07). Returns the new cap.
func cycle_gain_cap() -> float:
	if gain_presets.is_empty():
		return max_gain
	var i := gain_presets.find(max_gain)
	max_gain = gain_presets[(i + 1) % gain_presets.size()]
	cap_changed.emit(max_gain)
	EventLogger.log_event("stride_cap_changed", {"cap": max_gain})
	return max_gain


func target_gain() -> Vector2:
	var room := RoomManager.current_room
	if not enabled or room == null:
		return Vector2.ONE
	return room.stride_gain.min(Vector2(max_gain, max_gain))


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return
	var p := _camera.position
	_update_gain(p)
	var offset := Vector3((current_gain.x - 1.0) * p.x, 0.0, (current_gain.y - 1.0) * p.z)
	_origin.global_transform = Transform3D(_base.basis, _base.origin + _base.basis * offset)
	if footprint != null:
		footprint.global_transform = Transform3D(
			_base.basis * Basis.from_scale(Vector3(current_gain.x, 1.0, current_gain.y)),
			_base.origin + _base.basis * Vector3(0.0, 0.01, 0.0))


func _update_gain(p: Vector3) -> void:
	var target := target_gain()
	if target == current_gain:
		_waiting_for_dark = false
		return
	_pending_gain = target
	if _waiting_for_dark:
		return
	var jump := ((target - current_gain) * Vector2(p.x, p.z)).length()
	if screen_fade == null or jump <= jump_threshold:
		_set_gain(target)
	else:
		_waiting_for_dark = true
		screen_fade.fully_dark.connect(_on_fully_dark, CONNECT_ONE_SHOT)
		screen_fade.flash()


func _on_fully_dark() -> void:
	_waiting_for_dark = false
	_set_gain(_pending_gain)


func _set_gain(g: Vector2) -> void:
	current_gain = g
	gain_changed.emit(g)
