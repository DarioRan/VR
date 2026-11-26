extends XROrigin3D
## XR rig root (ticket A-01). Owner: A.
##
## - Starts OpenXR, or the XR simulator on desktop when no headset is found.
## - Sets the headset refresh rate and matches the physics rate to it (A-08).
## - Recenters the play area onto the taped square (calibration).
##
## Calibration: stand in the centre of the taped square, face the "front" edge,
## then hold the LEFT MENU button (three lines) for 1 s. Holding the Meta button
## (system recenter) does the same. Desktop: R.
## Left Y button (desktop: G) cycles the stride gain cap for the pilot (A-07).

signal recentered

@export var target_refresh_rate: float = 72.0
@export var recenter_hold_time: float = 1.0

var xr_interface: OpenXRInterface

var _menu_held: float = 0.0
var _hold_consumed: bool = false

@onready var _left: XRController3D = $LeftHand
@onready var _stride: StrideScaler = $StrideScaler
@onready var _perf: PerfMonitor = $PerfMonitor


func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR") as OpenXRInterface
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		# The headset paces frames, not the monitor.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		xr_interface.session_begun.connect(_on_session_begun)
		xr_interface.pose_recentered.connect(recenter)
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		print("Connecting XRSimulator")
		var xr_simulator_scene := load("res://addons/xr-simulator/XRSimulator.tscn") as PackedScene
		add_child(xr_simulator_scene.instantiate())
	_left.button_pressed.connect(_on_left_button_pressed)


func _on_session_begun() -> void:
	var rates := xr_interface.get_available_display_refresh_rates()
	if not rates.is_empty():
		var best: float = rates[0]
		for r: float in rates:
			if absf(r - target_refresh_rate) < absf(best - target_refresh_rate):
				best = r
		xr_interface.display_refresh_rate = best
	var hz := xr_interface.display_refresh_rate
	if hz > 0.0:
		# Physics in step with the display avoids jitter in VR.
		Engine.physics_ticks_per_second = roundi(hz)
		_perf.target_fps = hz
	EventLogger.log_event("xr_session_begun", {"refresh_rate": hz, "available": rates})


func _process(delta: float) -> void:
	# Hold-to-recenter on the left menu button.
	if _left.is_button_pressed(&"menu_button"):
		_menu_held += delta
		if _menu_held >= recenter_hold_time and not _hold_consumed:
			_hold_consumed = true
			recenter()
	else:
		_menu_held = 0.0
		_hold_consumed = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				recenter()
			KEY_G:
				_stride.cycle_gain_cap()


func _on_left_button_pressed(action: String) -> void:
	if action == "by_button":
		_stride.cycle_gain_cap()


## Make the head's current floor position and facing the centre and front of
## the play area. Also undoes debug joystick moves.
func recenter() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
	_stride.reset_base()
	EventLogger.log_event("recentered")
	recentered.emit()
