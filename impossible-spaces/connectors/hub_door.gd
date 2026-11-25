class_name HubDoor
extends Corridor
## A door of the central hub (plan Section 6.5). Owner: C.
## Behaves like a short corridor; the hub itself is a normal Room
## (for example room_id "hub") with one HubDoor per connected room.
##
## TODO (C): hub room scene with 3+ doors, way back to the hub.


func _init() -> void:
	technique = Technique.HUB
