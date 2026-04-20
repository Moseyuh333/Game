extends Node
class_name Inventory

signal inventory_updated
signal item_added(item_data: Dictionary)
signal item_removed(item_id: String)
signal item_used(item_data: Dictionary)

var slots: Array = []  # Array of Dictionary item_data or null
var max_slots: int = 10

func _ready():
	slots.resize(max_slots)
	for i in range(max_slots):
		slots[i] = null

func add_item(item_data: Dictionary) -> bool:
	# Check if stackable? For now, non-stackable
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = item_data
			item_added.emit(item_data)
			inventory_updated.emit()
			return true
	# Inventory full
	print("Inventory full!")
	return false

func remove_item(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size():
		return {}
	var item = slots[slot_index]
	if item:
		slots[slot_index] = null
		item_removed.emit(item.id)
		inventory_updated.emit()
	return item

func use_item(slot_index: int, player):
	if slot_index < 0 or slot_index >= slots.size():
		return
	var item = slots[slot_index]
	if not item:
		return
	match item.type:
		"consumable":
			apply_consumable(item, player)
			# Remove consumable after use
			remove_item(slot_index)
			item_used.emit(item)
		"weapon", "armor":
			# Equip logic: swap with currently equipped item of same slot
			# For simplicity, just print
			print("Equipped: ", item.name)
			item_used.emit(item)
		_:
			print("Item type not usable: ", item.type)

func apply_consumable(item: Dictionary, player):
	match item.effect:
		"heal":
			GameManager.heal(item.value)
		"speed_multiply":
			# Apply buff to player speed
			if player and player.has_method("apply_speed_boost"):
				player.apply_speed_boost(item.value, item.duration)
		_:
			print("Unknown consumable effect: ", item.effect)

func get_item(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size():
		return {}
	return slots[slot_index] or {}

func is_full() -> bool:
	for slot in slots:
		if slot == null:
			return false
	return true
