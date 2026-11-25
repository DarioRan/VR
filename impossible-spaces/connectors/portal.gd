class_name Portal
extends Connector
## Portal connection (plan Section 6.3). Owner: B.
##
## v0: detects when the head crosses the portal plane and swaps rooms.
## The portal faces +Z: walking from +Z to -Z goes from_room -> to_room.
##
## TODO (B):
##   1. Add a quad + SubViewport + Camera3D for the preview.
##      Camera pose = destination portal * inverse(this portal) * head.
##   2. Start with a mono preview, half resolution, render only while on screen.
##   3. Align the player to the destination portal after crossing.

## Opening size in metres (width, height). The bottom edge sits on the floor.
@export var opening_size: Vector2 = Vector2(1.0, 2.1)

var _last_side: float = 0.0


func _init() -> void:
	technique = Technique.PORTAL


func _physics_process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := to_local(cam.global_position)
	var in_opening := absf(p.x) <= opening_size.x * 0.5 and p.y >= -0.2 and p.y <= opening_size.y + 0.2
	var side := signf(p.z)
	if in_opening and _last_side != 0.0 and side != 0.0 and side != _last_side:
		notify_crossed(side < 0.0)
	_last_side = side
