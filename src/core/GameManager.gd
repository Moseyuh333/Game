extends Node
var stats: Dictionary = {
	"max_hp": 100,
	"current_hp": 100,
	"attack": 15,
	"defense": 5,
	"speed": 120
}

func _ready():
	load_stats()

func load_stats():
	var file = FileAccess.open("res://assets/data/player_stats.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		if data:
			stats = data
			stats.current_hp = stats.max_hp  # Ensure full health on load
		file.close()
	else:
		push_warning("Player stats file not found, using defaults")

func take_damage(amount: int):
	var actual = max(0, amount - stats.defense)
	stats.current_hp = max(0, stats.current_hp - actual)
	return actual

func heal(amount: int):
	stats.current_hp = min(stats.max_hp, stats.current_hp + amount)

func is_alive() -> bool:
	return stats.current_hp > 0
