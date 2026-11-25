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

	print("\n%d failure(s)" % _failures)
	quit(_failures)
