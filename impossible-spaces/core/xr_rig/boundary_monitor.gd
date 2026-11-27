class_name BoundaryMonitor
extends Node
## Boundary hits and warning (plan Section 6.7, tickets A-05, A-06). Owner: A.
## Child of XROrigin3D.
##
## - Hit: the head gets closer than PlayArea.BOUNDARY_MARGIN to the edge.
##   Logged once per exit as "boundary_hit".
## - Warning: the view darkens from warn_distance down to the edge, so the
##   player stops before reaching the tape.

signal boundary_left
signal boundary_returned

## Start darkening this far from the physical edge (metres).
@export var warn_distance: float = 0.5
## Darkness at the edge and beyond (0 to 1).
@export_range(0.0, 1.0) var max_warning: float = 0.85
@export var screen_fade: ScreenFade

var distance_to_edge: float = INF

var _camera: XRCamera3D
var _outside: bool = false


func _ready() -> void:
	_camera = get_parent().get_node_or_null(^"XRCamera3D") as XRCamera3D


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return
	# Camera position is in tracking space = play-area space (after recentering).
	var p := _camera.position
	distance_to_edge = PlayArea.distance_to_edge(p)

	if screen_fade != null:
		var t := clampf(1.0 - distance_to_edge / warn_distance, 0.0, 1.0)
		screen_fade.set_warning(t * t * max_warning)

	var inside := PlayArea.is_inside(p)
	if not inside and not _outside:
		_outside = true
		EventLogger.log_event("boundary_hit", {"distance_to_edge": snappedf(distance_to_edge, 0.01)})
		boundary_left.emit()
	elif inside and _outside:
		_outside = false
		boundary_returned.emit()
