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

	# Stride scaling: room_02 is 5 x 2.5 m -> gain (2, 1)
	cam.position = Vector3(0.5, 1.7, 0.5)
	await _wait_physics()
	var head := cam.global_position
	_check(is_equal_approx(head.x, 1.0) and is_equal_approx(head.z, 0.5),
		"stride gain 2 on x in room_02 (head at %s)" % head)

	# Boundary: 1.2 m from the centre is past the 0.2 m margin
	var monitor: Node = origin.get_node("BoundaryMonitor")
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

	await _check_office(main, rm)

	print("\n%d failure(s)" % _failures)


## Office greybox: contract, door markers on the blueprint slots, doors open, paths clear.
func _check_office(main: Node3D, rm: Node) -> void:
	var office: Node3D = load("res://rooms/office.tscn").instantiate()
	main.add_child(office)
	rm.activate(&"office")
	await _wait_physics(3)

	_check(rm.current_room == office and office.stride_gain == Vector2.ONE, "office registers, gain 1")
	var n1: Marker3D = office.get_door(&"hallway")
	var e2: Marker3D = office.get_door(&"bedroom")
	_check(n1 != null and n1.position.is_equal_approx(Vector3(-0.8, 0, -0.5)) and n1.get_meta(&"slot") == "N1",
		"Door_hallway on slot N1")
	_check(e2 != null and e2.position.is_equal_approx(Vector3(0.5, 0, 0.85)) and e2.get_meta(&"slot") == "E2",
		"Door_bedroom on slot E2")
	# Door markers face out of the room (-Z of the marker): N1 north, E2 east.
	_check((-n1.basis.z).is_equal_approx(Vector3.FORWARD) and (-e2.basis.z).is_equal_approx(Vector3.RIGHT),
		"door markers face out of the room")
	var safe: Marker3D = office.get_node("SafeSlot")
	_check((-safe.basis.z).is_equal_approx(Vector3.RIGHT), "safe slot faces into the room (east)")

	# Rays at chest height: through each door from the band into the room, and through a wall.
	var space := main.get_world_3d().direct_space_state
	var hit := func(from: Vector3, to: Vector3) -> bool:
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to)).is_empty()
	_check(not hit.call(Vector3(-0.8, 1.2, -0.9), Vector3(-0.8, 1.2, 0.2)), "N1 opening is walkable")
	_check(not hit.call(Vector3(0.9, 1.2, 0.85), Vector3(-0.2, 1.2, 0.85)), "E2 opening is walkable")
	_check(hit.call(Vector3(0.0, 1.2, -0.9), Vector3(0.0, 1.2, 0.2)), "north wall is solid beside N1")
	# 0.75 m clear inside each door (knee height, where the desk would be).
	_check(not hit.call(Vector3(-1.175, 0.4, -0.45), Vector3(-1.175, 0.4, 0.25)), "path from N1 clear of the desk")
	_check(not hit.call(Vector3(0.45, 0.4, 0.85), Vector3(-0.25, 0.4, 0.85)), "path from E2 clear")
	office.queue_free()
	quit(_failures)
