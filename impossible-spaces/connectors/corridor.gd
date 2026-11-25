class_name Corridor
extends Connector
## Corridor connection (plan Section 6.4). Owner: C.
##
## v0: swaps rooms when the player stands in `swap_zone` (the bend of the
## corridor) and the old door is out of view.
##
## Scene setup:
##   - an Area3D for the bend, assigned to swap_zone
##   - a VisibleOnScreenNotifier3D on the old room's door, assigned to old_door_visibility
## The head-tracked Area3D (XRCamera3D/HeadArea) is in the "player" group.
##
## TODO (C): the way back (to_room -> from_room), corridor walls that fold inside the play area.

@export var swap_zone: Area3D
@export var old_door_visibility: VisibleOnScreenNotifier3D

var _player_in_zone: bool = false
var _swapped: bool = false


func _init() -> void:
	technique = Technique.CORRIDOR


func _ready() -> void:
	super()
	if swap_zone == null:
		push_warning("Corridor '%s' has no swap_zone" % name)
		return
	swap_zone.area_entered.connect(_on_zone_entered)
	swap_zone.area_exited.connect(_on_zone_exited)


func _on_zone_entered(area: Area3D) -> void:
	if area.is_in_group(&"player"):
		_player_in_zone = true


func _on_zone_exited(area: Area3D) -> void:
	if area.is_in_group(&"player"):
		_player_in_zone = false


func _process(_delta: float) -> void:
	if _swapped or not _player_in_zone:
		return
	if old_door_visibility == null or not old_door_visibility.is_on_screen():
		_swapped = true
		notify_crossed(true)
