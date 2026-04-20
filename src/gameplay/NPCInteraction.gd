extends StaticBody2D
class_name NPC

@export var npc_name: String = "NPC"
@export var dialogue_start_node: String = "npc_01_start"

var interaction_area: Area2D = null

func _ready():
	add_to_group("npcs")
	# Find or create interaction area
	interaction_area = $InteractionArea
	if not interaction_area:
		interaction_area = Area2D.new()
		interaction_area.name = "InteractionArea"
		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		col.shape.radius = 60
		interaction_area.add_child(col)
		add_child(interaction_area)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	# Set sprite color based on name
	var sprite = $Sprite2D
	if sprite:
		if not sprite.texture:
			var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			match name:
				"ArchiveClerk":
					img.fill(Color(0.8, 0.6, 0.4))  # Beige
				"WanderingSoul":
					img.fill(Color(0.6, 0.6, 0.9))  # Light3D blue
				_:
					img.fill(Color(0.8, 0.8, 0.8))  # Light3D gray
			sprite.texture = ImageTexture.create_from_image(img)

var player_in_range: bool = false

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func _input(event):
	if event.is_action_pressed("interact") and player_in_range:
		start_dialogue()
		get_viewport().set_input_as_handled()

func start_dialogue():
	var dialogue = get_tree().get_first_node_in_group("dialogue")
	if dialogue and dialogue.has_method("start_dialogue"):
		dialogue.start_dialogue(dialogue_start_node)
	else:
		print("Dialogue UI not found")
