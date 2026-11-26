class_name PerfMonitor
extends Node
## Frame-rate check for the Quest (ticket A-08). Owner: A.
## Every `interval` seconds it logs a "perf" event with the average fps,
## the worst frame time and how many frames missed the target.
## Use it to prove the 72 Hz definition of done.

@export var enabled: bool = true
@export var interval: float = 5.0
## Overwritten with the headset's refresh rate when the XR session starts.
@export var target_fps: float = 72.0

var _elapsed: float = 0.0
var _frames: int = 0
var _worst: float = 0.0
var _missed: int = 0


func _process(delta: float) -> void:
	if not enabled:
		return
	_elapsed += delta
	_frames += 1
	_worst = maxf(_worst, delta)
	# A frame counts as missed when it took longer than 1.5 target frames.
	if delta > 1.5 / target_fps:
		_missed += 1
	if _elapsed >= interval:
		var avg := _frames / _elapsed
		EventLogger.log_event("perf", {
			"fps_avg": snappedf(avg, 0.1),
			"frame_ms_max": snappedf(_worst * 1000.0, 0.1),
			"missed": _missed,
			"target": target_fps,
		})
		if avg < target_fps - 2.0:
			push_warning("PerfMonitor: %.1f fps, below the %.0f fps target" % [avg, target_fps])
		_elapsed = 0.0
		_frames = 0
		_worst = 0.0
		_missed = 0
