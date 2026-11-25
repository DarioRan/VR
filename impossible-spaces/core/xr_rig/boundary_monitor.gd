class_name BoundaryMonitor
extends Node
## Boundary hits (plan Section 6.7). Owner: A. Child of XROrigin3D.
## Logs a "boundary_hit" when the head leaves the safe square, once per exit.

signal boundary_left
signal boundary_returned

var _camera: XRCamera3D
var _outside: bool = false


func _ready() -> void:
	_camera = get_parent().get_node_or_null(^"XRCamera3D") as XRCamera3D


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return
	# Camera position is in tracking space = play-area space.
	var inside := PlayArea.is_inside(_camera.position)
	if not inside and not _outside:
		_outside = true
		EventLogger.log_event("boundary_hit")
		boundary_left.emit()
		# TODO (A): fade the view as a warning.
	elif inside and _outside:
		_outside = false
		boundary_returned.emit()
