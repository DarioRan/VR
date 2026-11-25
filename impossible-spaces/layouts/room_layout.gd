class_name RoomLayout
extends Resource
## One way of building the apartment with one technique (plan Section 5.6). Owner: C.
## The same room scenes are reused in all three layouts; only the connectors differ.

@export var technique: Connector.Technique = Connector.Technique.PORTAL
@export var start_room: StringName = &"room_01"
@export var rooms: Array[PackedScene] = []
@export var connectors: Array[PackedScene] = []
@export_multiline var notes: String = ""
