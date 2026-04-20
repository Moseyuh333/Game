extends Node
var dialogue_data: Dictionary = {}

func _ready():
	load_dialogue()

func load_dialogue():
	var file = FileAccess.open("res://assets/data/dialogue.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		dialogue_data = JSON.parse_string(text) || {}
		file.close()
	else:
		push_warning("Dialogue data file not found")

func get_node_data(node_id: String) -> Dictionary:
	return dialogue_data.get(node_id, {})
