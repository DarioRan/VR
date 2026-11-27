extends Room
## Office (owner: Dario). Layout from Sofia's lobby plan (Lobby-North-Doors, 25 Nov).
##
## Play area coordinates: origin = centre of the taped square, x east, north = -z.
##   Lobby strip z +0.45 .. +1.1 (lobby scene, not this one). Office z -1.2 .. +0.45.
##   One lane, x -0.375 .. +0.375: lobby door (0, +0.45) -> return portal (0, -0.17)
##   -> safe front (0, -0.8), where the office piece is picked up.
## Walk north to the safe, take the piece, turn round, walk south through the portal.
##
## The return portal is one-way (walking south through it activates the lobby) and
## stays closed until open_return_portal(). Sofia's plan opens it after the pickup.

signal return_portal_opened

const FRAME_CLOSED := Color(0.38, 0.34, 0.42)
const FRAME_OPEN := Color(0.62, 0.3, 0.85)

var return_portal_open: bool = false

@onready var _portal: Node3D = $ReturnPortal
@onready var _surface: Node3D = $ReturnPortal/Surface
@onready var _frame: Node3D = $ReturnPortal/Frame


func _ready() -> void:
	super()
	_apply_portal_state()


## Call once the player holds the office piece.
func open_return_portal() -> void:
	if return_portal_open:
		return
	return_portal_open = true
	_apply_portal_state()
	return_portal_opened.emit()


func _apply_portal_state() -> void:
	# A disabled Portal does not track the head, so walking through it does nothing.
	_portal.process_mode = PROCESS_MODE_INHERIT if return_portal_open else PROCESS_MODE_DISABLED
	_surface.visible = return_portal_open
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FRAME_OPEN if return_portal_open else FRAME_CLOSED
	if return_portal_open:
		mat.emission_enabled = true
		mat.emission = FRAME_OPEN
		mat.emission_energy_multiplier = 0.6
	for part in _frame.get_children():
		(part as GeometryInstance3D).material_override = mat
