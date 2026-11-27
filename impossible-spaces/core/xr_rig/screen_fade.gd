class_name ScreenFade
extends MeshInstance3D
## Darkens the whole view. Owner: A. Child of XRCamera3D.
##
## Two inputs, the darker one wins:
##   - warning: a steady level set every frame (BoundaryMonitor, near the edge)
##   - flash: a short fade out and back in (StrideScaler hides a jump with it)
## A small inside-out sphere around the head, drawn on top of everything.

## Emitted when a flash reaches full black: the moment to move the player.
signal fully_dark

@export var color: Color = Color(0.0, 0.0, 0.0)

var _warning: float = 0.0
var _flash: float = 0.0
var _material: StandardMaterial3D
var _tween: Tween


func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	sphere.flip_faces = true
	mesh = sphere
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.no_depth_test = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.render_priority = Material.RENDER_PRIORITY_MAX
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_update()


## Steady darkening from 0 (none) to 1 (black).
func set_warning(amount: float) -> void:
	_warning = clampf(amount, 0.0, 1.0)
	_update()


## Fade to black, emit fully_dark, hold, fade back.
func flash(fade_in: float = 0.12, hold: float = 0.05, fade_out: float = 0.15) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_flash, _flash, 1.0, fade_in)
	_tween.tween_callback(fully_dark.emit)
	_tween.tween_interval(hold)
	_tween.tween_method(_set_flash, 1.0, 0.0, fade_out)


func get_amount() -> float:
	return maxf(_warning, _flash)


func _set_flash(value: float) -> void:
	_flash = value
	_update()


func _update() -> void:
	if _material == null:
		return
	var a := get_amount()
	_material.albedo_color = Color(color, a)
	visible = a > 0.001
