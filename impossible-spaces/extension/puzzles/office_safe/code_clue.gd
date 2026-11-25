extends Label3D
## Static stand-in for the P2 clue: a note showing the safe code. Owner: D (Dario).
## Plan: replaced on 7 Dec by a digit visible only through Ahmed's portal window.

@export var safe: OfficeSafe


func _ready() -> void:
	if safe == null:
		text = "SAFE\n? ? ? ?"
		return
	var digits := PackedStringArray()
	for ch in safe.code:
		digits.append(ch)
	text = "SAFE\n" + " ".join(digits)
