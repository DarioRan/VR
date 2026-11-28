extends SceneTree
## Headless smoke test for the core contracts. Run from the project folder:
##   godot --headless --xr-mode off -s tests/smoke_test.gd
## Exit code = number of failed checks.
## Project classes (Portal, BoundaryMonitor...) are loaded at runtime, not named
## directly: with -s this script compiles before the autoloads exist.

var _failures: int = 0


func _check(ok: bool, what: String) -> void:
	if ok:
		print("PASS  ", what)
	else:
		_failures += 1
		printerr("FAIL  ", what)


func _wait_physics(n: int = 2) -> void:
	for i in n:
		await physics_frame


## Last row of the current session CSV, split into columns (handles the quoted JSON column).
func _last_log_row(logger: Node) -> PackedStringArray:
	var f := FileAccess.open(logger.file_path, FileAccess.READ)
	if f == null:
		return PackedStringArray()
	var row := PackedStringArray()
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() > 1:
			row = r
	return row


func _initialize() -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _wait_physics()

	var rm: Node = root.get_node("RoomManager")
	var room01: Node3D = main.get_node("Rooms/Room01")
	var room02: Node3D = main.get_node("Rooms/Room02")
	var origin: XROrigin3D = main.get_node("XROrigin3D")
	var cam: XRCamera3D = origin.get_node("XRCamera3D")

	# RoomManager
	_check(rm.current_room == room01, "starts in room_01")
	_check(room01.visible and not room02.visible, "only the active room is visible")
	rm.activate(&"room_02")
	_check(rm.current_room == room02 and not room01.visible and room02.visible, "activate() swaps rooms")

	# Stride scaling: room_02 is 5 x 2.5 m -> gain (2, 1).
	# Entering with the head 0.5 m off-centre is a 0.5 m jump, so the new gain
	# waits for the screen fade to reach black (A-04).
	var stride: Node = origin.get_node("StrideScaler")
	var fade: Node = cam.get_node("ScreenFade")
	rm.activate(&"room_01")
	cam.position = Vector3(0.5, 1.7, 0.5)
	await _wait_physics()
	var darkest := [0.0]
	var watch := func() -> void: darkest[0] = maxf(darkest[0], fade.get_amount())
	process_frame.connect(watch)
	rm.activate(&"room_02")
	await _wait_physics(1)
	_check(stride.current_gain == Vector2.ONE, "big gain change waits for the fade")
	await _wait_physics(40)
	process_frame.disconnect(watch)
	_check(darkest[0] > 0.95, "fade reaches black during the gain change (%.2f)" % darkest[0])
	var head := cam.global_position
	_check(is_equal_approx(head.x, 1.0) and is_equal_approx(head.z, 0.5),
		"stride gain 2 on x in room_02 (head at %s)" % head)
	_check(fade.get_amount() < 0.01, "fade clears after the gain change")

	# Small jump near the centre: applied at once, no fade
	cam.position = Vector3(0.01, 1.7, 0.0)
	rm.activate(&"room_01")
	await _wait_physics(1)
	_check(stride.current_gain == Vector2.ONE, "small gain change applies at once")
	rm.activate(&"room_02")
	await _wait_physics(1)

	# Pilot gain caps (A-07): 2.0 -> 1.25 -> 1.5 -> 2.0
	_check(is_equal_approx(stride.cycle_gain_cap(), 1.25), "gain cap cycles to 1.25")
	await _wait_physics(1)
	_check(is_equal_approx(stride.current_gain.x, 1.25), "cap limits room_02 gain to 1.25")
	stride.cycle_gain_cap()
	stride.cycle_gain_cap()
	_check(is_equal_approx(stride.max_gain, 2.0), "gain cap cycles back to 2.0")
	await _wait_physics(1)

	# Footprint shows the scaled play area
	var footprint: Node3D = main.get_node("PlayAreaOutline")
	_check(is_equal_approx(footprint.global_basis.get_scale().x, 2.0), "footprint scaled by the gain")

	# Hands are small spheres, not stretched capsules
	var hand_mesh: SphereMesh = origin.get_node("LeftHand/Area3D/MeshInstance3D").mesh
	_check(is_equal_approx(hand_mesh.height, hand_mesh.radius * 2.0), "hand mesh is a sphere")

	# Boundary warning (A-06): dark near the edge, clear in the centre
	var monitor: Node = origin.get_node("BoundaryMonitor")
	cam.position = Vector3(0.0, 1.7, 0.0)
	await _wait_physics()
	_check(fade.get_amount() < 0.01, "no warning in the centre")
	cam.position = Vector3(1.05, 1.7, 0.0)
	await _wait_physics()
	_check(fade.get_amount() > 0.3, "warning 0.2 m from the edge (%.2f)" % fade.get_amount())
	cam.position = Vector3(0.0, 1.7, 0.0)
	await _wait_physics()

	# Boundary: 1.2 m from the centre is past the 0.2 m margin
	var hits := [0]
	monitor.boundary_left.connect(func() -> void: hits[0] += 1)
	cam.position = Vector3(1.2, 1.7, 0.0)
	await _wait_physics()
	cam.position = Vector3(1.15, 1.7, 0.0)
	await _wait_physics()
	_check(hits[0] == 1, "one boundary hit per exit (got %d)" % hits[0])

	# Portal crossing: walk from +Z to -Z through a portal at the centre
	cam.position = Vector3(0.0, 1.7, 0.0)
	rm.activate(&"room_01")
	await _wait_physics()
	var portal: Node3D = load("res://connectors/portal.gd").new()
	portal.from_room = &"room_01"
	portal.to_room = &"room_02"
	main.add_child(portal)
	cam.position = Vector3(0.0, 1.7, 0.3)
	await _wait_physics()
	cam.position = Vector3(0.0, 1.7, -0.3)
	await _wait_physics()
	_check(rm.current_room == room02, "portal crossing activates to_room")
	_check(rm.current_technique == 0, "technique is PORTAL")

	# Debug joystick locomotion (stick input fed through the XR simulator's trackers)
	portal.queue_free()
	var left_tracker := XRServer.get_tracker(&"left_hand") as XRPositionalTracker
	var right_tracker := XRServer.get_tracker(&"right_hand") as XRPositionalTracker
	_check(left_tracker != null and right_tracker != null, "controller trackers exist")
	if left_tracker != null and right_tracker != null:
		cam.position = Vector3(0.0, 1.7, 0.0)
		await _wait_physics()
		var start := cam.global_position
		var forward := Vector3(-cam.global_basis.z.x, 0.0, -cam.global_basis.z.z).normalized()
		left_tracker.set_input("primary", Vector2(0.0, 1.0))
		await _wait_physics(30)
		left_tracker.set_input("primary", Vector2.ZERO)
		await _wait_physics()
		var moved := (cam.global_position - start).dot(forward)
		_check(moved > 0.5 and moved < 1.0, "left stick moves forward (%.2f m in 0.5 s)" % moved)

		var yaw_before := cam.global_basis.get_euler().y
		var pos_before := cam.global_position
		right_tracker.set_input("primary", Vector2(1.0, 0.0))
		await _wait_physics(10)
		right_tracker.set_input("primary", Vector2.ZERO)
		await _wait_physics()
		var turned := rad_to_deg(angle_difference(yaw_before, cam.global_basis.get_euler().y))
		_check(is_equal_approx(snappedf(turned, 0.1), -30.0), "right stick snap-turns once (%.1f deg)" % turned)
		_check(cam.global_position.distance_to(pos_before) < 0.01, "snap turn pivots around the head")

		# Recenter (A-01) undoes debug joystick moves
		origin.recenter()
		await _wait_physics()
		var back := cam.global_position
		_check(absf(back.x) < 0.01 and absf(back.z) < 0.01, "recenter resets the play area (head at %s)" % back)

	# EventLogger: room_entered records the connector used, technique column stays the layout's
	var logger: Node = root.get_node("EventLogger")
	var corridor: Node3D = load("res://connectors/corridor.gd").new()
	rm.on_connector_crossed(corridor, rm.current_room.room_id, &"room_01")
	corridor.free()
	var row := _last_log_row(logger)
	_check(row.size() == 8 and row[4] == "room_entered" and row[2] == "PORTAL" and row[7].contains("CORRIDOR"),
		"room_entered logs via=CORRIDOR, technique column PORTAL (%s)" % [row])

	logger.set_participant(" P07 ")
	logger.log_event("piece_collected", {"piece_id": 6})
	row = _last_log_row(logger)
	_check(row.size() == 8 and row[1] == "P07" and row[3] == "room_01" and row[4] == "piece_collected"
		and JSON.parse_string(row[7]) == {"piece_id": 6.0},
		"participant and data written to the CSV (%s)" % [row])

	# DebugHud: attached to the camera, shows room and participant, red near the edge
	var hud: Node = root.get_node("DebugHud")
	cam.position = Vector3(0.0, 1.7, 0.0)
	hud.toggle()
	hud.toggle()  # off and on again forces a refresh
	await process_frame
	await process_frame
	var label := cam.get_node_or_null("DebugHud") as Label3D
	_check(label != null and label.visible, "HUD label is attached to the camera")
	_check(hud.get_text().contains("room_01") and hud.get_text().contains("P07")
		and hud.get_text().contains("cap 2.00"),
		"HUD shows room, gain cap and participant (%s)" % hud.get_text().replace("\n", " | "))
	cam.position = Vector3(1.15, 1.7, 0.0)
	hud.toggle()
	hud.toggle()  # off and on again forces a refresh
	await process_frame
	await process_frame
	_check(hud.get_text().contains("edge  0.10 m") and label.modulate == hud.COLOR_WARN,
		"HUD warns 0.10 m from the edge (%s)" % hud.get_text().replace("\n", " | "))
	hud.toggle()
	await process_frame
	await process_frame
	_check(not label.visible, "HUD toggles off")
	# Left X toggles it on the Quest; left Y is the stride cap and leaves it alone.
	var left := XRServer.get_tracker(&"left_hand") as XRPositionalTracker
	if left != null:
		left.set_input("ax_button", true)
		left.set_input("ax_button", false)
		await process_frame
		await process_frame
		_check(label.visible, "left X toggles the HUD")
		var cap_before: float = stride.max_gain
		left.set_input("by_button", true)
		left.set_input("by_button", false)
		await process_frame
		await process_frame
		_check(label.visible, "left Y does not toggle the HUD")
		stride.max_gain = cap_before  # Y cycled the cap: put it back
	else:
		hud.toggle()

	print("\n%d failure(s)" % _failures)
	quit(_failures)
