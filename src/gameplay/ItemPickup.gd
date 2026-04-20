extends Area2D
class_name ItemPickup

@export var item_id: String = ""
@export var item_data: Dictionary = {}

var floating_offset: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	# Load item data
	if item_id != "":
		var items = load_items_json()
		item_data = items.get(item_id, {})
	# Bobbing animation
	floating_offset = randf() * TAU

func load_items_json() -> Dictionary:
	var file = FileAccess.open("res://assets/data/items.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var data = JSON.parse_string(text) || {}
		file.close()
		return data
	return {}

func _process(delta):
	floating_offset += delta * 2.0
	position.y += sin(floating_offset) * 0.5

func _on_body_entered(body):
	if body.name == "Player":
		# Give item to player
		if item_data:
			if item_data.type == "consumable":
				apply_consumable_effect(body, item_data)
			else:
				# Add to inventory
				if body.inventory:
					if body.inventory.add_item(item_data):
						# Show notification via HUD if available
						var hud = get_tree().get_first_node_in_group("hud")
						if hud and hud.has_method("show_notification"):
							hud.show_notification("Collected: %s" % item_data.name)
				else:
					print("Player has no inventory")
		queue_free()

func apply_consumable_effect(player, item_data: Dictionary):
	match item_data.effect:
		"heal":
			GameManager.heal(item_data.value)
		"speed_multiply":
			if player.has_method("apply_speed_boost"):
				player.apply_speed_boost(item_data.value, item_data.duration)
		_:
			print("Unknown consumable effect: ", item_data.effect)
