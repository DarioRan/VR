class_name Connector
extends Node3D
## Base class for the three room connection techniques (plan Section 5.5).
## Portal, Corridor and HubDoor extend it. A subclass only has to detect that
## the player went through and call notify_crossed().

enum Technique { PORTAL, CORRIDOR, HUB }

signal crossed(connector: Connector, from_room: StringName, to_room: StringName)

@export var from_room: StringName = &""
@export var to_room: StringName = &""

var technique: Technique = Technique.PORTAL


func _ready() -> void:
	crossed.connect(RoomManager.on_connector_crossed)


## forward = true means from_room -> to_room, false means the way back.
func notify_crossed(forward: bool = true) -> void:
	if forward:
		crossed.emit(self, from_room, to_room)
	else:
		crossed.emit(self, to_room, from_room)


static func technique_name(t: int) -> String:
	return Technique.keys()[t]
