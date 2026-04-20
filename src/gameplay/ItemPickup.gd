extends Area2D
class_name ItemPickup

@export var item_id: String = ""
@export var item_data: Dictionary = {}

var floating_offset: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	# Set collision layer for items
	collision_layer = 3  # Items layer
	collision_mask = 1   # Player layer
	# Load item data
	if item_id != "":
		var items = load_items_json()
		item_data = items.get(item_id, {})
		# Set sprite color based on item type
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			if not sprite.texture:
				var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
				match item_data.get("type", ""):
					"consumable":
						img.fill(Color(0, 1, 0))  # Green
					"weapon":
						img.fill(Color(1, 1, 0))  # Yellow
					"armor":
						img.fill(Color(0.5, 0.5, 0.5))  # Gray
					"key":
						img.fill(Color(1, 1, 1))  # White
					_:
						img.fill(Color(1, 1, 1))
				sprite.texture = ImageTexture.create_from_image(img)
	# Bobbing animation
	floating_offset = randf() * TAU

func load_items_json() -> Dictionary:
	var file = FileAccess.open("res://assets/data/items.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		if data == null:
			data = {}
		file.close()
		return data
	return {}

func _process(delta):
	floating_offset += delta * 2.0
	position.y += sin(floating_offset) * 0.5

func _on_body_entered(body):
	if body.is_in_group("player"):
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
