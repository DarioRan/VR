class_name StrideScaler
extends Node
## Stride scaling (plan Section 6.6). Owner: A. Child of XROrigin3D.
##
## Virtual position = play-area centre + gain * physical position, per axis.
## With gain 2 one physical step moves you two virtual steps, so a 5 m room
## fits in the 2.5 m play area. The mapping is absolute (no drift), and its base
## is the calibrated origin, which every room shares, so leaving a scaled room
## does not shift the next one.
## Assumes rooms are centred on the play area and axis-aligned with it.

@export var enabled: bool = true
## Global cap on top of each room's own max_stride_gain (pilot: try 1.25, 1.5, 2.0).
@export var max_gain: float = 2.0

var _origin: XROrigin3D
var _camera: XRCamera3D
var _base: Transform3D


func _ready() -> void:
	_origin = get_parent() as XROrigin3D
	_camera = _origin.get_node_or_null(^"XRCamera3D") as XRCamera3D
	# Calibrated origin without any stride offset. Call recalibrate() after recentering.
	_base = _origin.global_transform


## Call after the play area has been recentered.
## TODO (A): when the gain changes at a room swap while the player is off-centre,
## the view jumps by (new_gain - old_gain) * position. Swaps happen near doors,
## so test on the headset whether this needs smoothing.
func recalibrate() -> void:
	_base = _origin.global_transform


func _physics_process(_delta: float) -> void:
	var room := RoomManager.current_room
	if not enabled or room == null or _camera == null:
		return
	var g := room.stride_gain.min(Vector2(max_gain, max_gain))
	var p := _camera.position
	var offset := Vector3((g.x - 1.0) * p.x, 0.0, (g.y - 1.0) * p.z)
	_origin.global_position = _base.origin + _base.basis * offset
