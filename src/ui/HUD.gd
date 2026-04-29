extends CanvasLayer
class_name HUD

@onready var hp_bar: ProgressBar = $HBoxContainer/HPBar
@onready var hotbar_grid: GridContainer = $HBoxContainer/HotbarGrid
@onready var notification_label: Label = $Notification

var inventory: Inventory

func _ready():
	add_to_group("hud")
	_style_hud()
	# Setup hotbar slots (5 slots)
	for i in range(5):
		var slot_btn = Button.new()
		slot_btn.name = "Hotbar_%d" % i
		slot_btn.text = "[%d]" % (i+1)
		slot_btn.custom_minimum_size = Vector2(64, 64)
		slot_btn.add_theme_stylebox_override("normal", _make_panel_style(Color(0.11, 0.13, 0.14), Color(0.42, 0.72, 0.78)))
		slot_btn.add_theme_stylebox_override("hover", _make_panel_style(Color(0.16, 0.2, 0.22), Color(0.76, 0.95, 1.0)))
		slot_btn.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
		slot_btn.pressed.connect(_on_hotbar_pressed.bind(i))
		hotbar_grid.add_child(slot_btn)
	notification_label.hide()

func _style_hud():
	hp_bar.add_theme_stylebox_override("background", _make_panel_style(Color(0.09, 0.06, 0.07), Color(0.35, 0.2, 0.2)))
	hp_bar.add_theme_stylebox_override("fill", _make_panel_style(Color(0.82, 0.12, 0.16), Color(1.0, 0.44, 0.36)))
	hp_bar.add_theme_color_override("font_color", Color(1.0, 0.88, 0.82))
	hp_bar.show_percentage = false
	notification_label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	notification_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	return style

func _process(delta):
	# Find player and get inventory
	var player = get_tree().get_first_node_in_group("player")  # Need to add player to group
	if not player:
		return
	var inventory = player.inventory
	if not inventory:
		return
	# Update HP bar
	hp_bar.max_value = GameManager.stats.max_hp
	hp_bar.value = GameManager.stats.current_hp
	hp_bar.tooltip_text = "HP: %d / %d" % [GameManager.stats.current_hp, GameManager.stats.max_hp]
	# Update hotbar visuals
	for i in range(5):
		var slot_btn = hotbar_grid.get_child(i)
		var item = inventory.get_item(i)
		if item:
			slot_btn.text = item.name
		else:
			slot_btn.text = "[%d]" % (i+1)

func _on_hotbar_pressed(index: int):
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return
	var item = player.inventory.get_item(index)
	if item:
		player.inventory.use_item(index, player)

func show_notification(message: String, duration: float = 2.0):
	notification_label.text = message
	notification_label.show()
	await get_tree().create_timer(duration).timeout
	notification_label.hide()
