class_name DebugLocomotion
extends Node
## Joystick locomotion for DEBUGGING ONLY. Child of XROrigin3D. Owner: A.
##
##   Left stick:  move smoothly, relative to where you look
##   Right stick: snap turn left/right (or smooth turn if snap_turn is off)
##   Desktop (XR simulator): WASD = left stick, arrow keys = right stick
##
## The real experience uses natural walking only. This node is off in release
## exports, and the first use per session is logged ("debug_locomotion_used")
## so pilot data recorded with it can be spotted.
##
## It moves the whole play area through the virtual world. Since StrideScaler
## rewrites the origin every physics frame, movement goes through its base.

@export var enabled: bool = true
## Turn off automatically in release exports.
@export var only_in_debug_builds: bool = true
@export var move_speed: float = 1.5          # metres per second
@export var deadzone: float = 0.2
@export var snap_turn: bool = true
@export var snap_angle_deg: float = 30.0
@export var smooth_turn_speed_deg: float = 90.0  # degrees per second
## Name of the thumbstick action in openxr_action_map.tres.
@export var stick_action: StringName = &"primary"

var _origin: XROrigin3D
var _camera: XRCamera3D
var _left: XRController3D
var _right: XRController3D
var _scaler: StrideScaler
var _turn_latched: bool = false
var _logged_use: bool = false


func _ready() -> void:
	if only_in_debug_builds and not OS.is_debug_build():
		enabled = false
	_origin = get_parent() as XROrigin3D
	_camera = _origin.get_node_or_null(^"XRCamera3D") as XRCamera3D
	_left = _origin.get_node_or_null(^"LeftHand") as XRController3D
	_right = _origin.get_node_or_null(^"RightHand") as XRController3D
	_scaler = _origin.get_node_or_null(^"StrideScaler") as StrideScaler


func _physics_process(delta: float) -> void:
	if not enabled or _camera == null:
		return
	var move := _stick(_left)
	var turn := _stick(_right).x
	if move != Vector2.ZERO:
		_move(move, delta)
	_turn(turn, delta)


func _stick(controller: XRController3D) -> Vector2:
	if controller == null:
		return Vector2.ZERO
	var v := controller.get_vector2(stick_action)
	return v if v.length() > deadzone else Vector2.ZERO


func _move(stick: Vector2, delta: float) -> void:
	# Forward/right from the head's yaw, flattened onto the floor.
	var basis := _camera.global_basis
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
	var right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var offset := (right * stick.x + forward * stick.y) * move_speed * delta
	_apply_transform(Transform3D(Basis.IDENTITY, offset))


func _turn(x: float, delta: float) -> void:
	var angle := 0.0
	if snap_turn:
		if absf(x) < 0.3:
			_turn_latched = false
		elif absf(x) > 0.6 and not _turn_latched:
			_turn_latched = true
			angle = -signf(x) * deg_to_rad(snap_angle_deg)
	elif x != 0.0:
		angle = -x * deg_to_rad(smooth_turn_speed_deg) * delta
	if angle == 0.0:
		return
	# Rotate around the head so the view turns in place.
	var pivot := _camera.global_position
	pivot.y = 0.0
	var around := Transform3D(Basis.IDENTITY, pivot) \
		* Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO) \
		* Transform3D(Basis.IDENTITY, -pivot)
	_apply_transform(around)


## Apply a world-space transform to the play area (origin and stride base).
func _apply_transform(t: Transform3D) -> void:
	if not _logged_use:
		_logged_use = true
		EventLogger.log_event("debug_locomotion_used")
	if _scaler != null:
		_scaler.transform_base(t)
	if _scaler == null or not _scaler.enabled:
		_origin.global_transform = t * _origin.global_transform
