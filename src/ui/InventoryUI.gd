extends CanvasLayer
class_name InventoryUI

@onready var grid: GridContainer = $Panel/GridContainer
@onready var panel: Panel = $Panel

var inventory: Inventory = null
var is_open: bool = false

func _ready():
	add_to_group("inventory_ui")
	panel.visible = false
	# Build grid slots (10 slots)
	for i in range(10):
		var slot_btn = Button.new()
		slot_btn.name = "Slot_%d" % i
		slot_btn.custom_minimum_size = Vector2(64, 64)
		slot_btn.text = "[%d]" % (i+1)
		slot_btn.pressed.connect(_on_slot_pressed.bind(i))
		grid.add_child(slot_btn)

func _input(event):
	if event.is_action_pressed("inventory") and not is_open:
		open()
	elif event.is_action_pressed("inventory") and is_open:
		close()

func open():
	is_open = true
	panel.visible = true
	refresh()

func close():
	is_open = false
	panel.visible = false

func _on_slot_pressed(index: int):
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return
	var item = player.inventory.get_item(index)
	if item:
		player.inventory.use_item(index, player)
		refresh()

func refresh():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return
	inventory = player.inventory
	for i in range(10):
		var slot_btn = grid.get_child(i)
		var item = inventory.get_item(i)
		if item:
			slot_btn.text = item.name
		else:
			slot_btn.text = "[%d]" % (i+1)
