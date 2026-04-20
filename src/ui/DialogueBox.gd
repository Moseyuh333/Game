extends CanvasLayer
class_name DialogueBox

@onready var panel: Panel = $Panel
@onready var npc_name_label: Label = $Panel/NPCName
@onready var text_label: RichTextLabel = $Panel/Text
@onready var choices_container: VBoxContainer = $Panel/Choices

var current_node_id: String = ""
var is_active: bool = false
var typewriter_speed: float = 0.03
var typewriter_timer: float = 0.0
var full_text: String = ""
var displayed_text: String = ""

func _ready():
	add_to_group("dialogue")
	add_to_group("ui")  # Also add to UI group for convenience
	panel.visible = false
	choices_container.hide()

func _process(delta):
	if is_active and displayed_text.length() < full_text.length():
		typewriter_timer -= delta
		if typewriter_timer <= 0:
			displayed_text += full_text[displayed_text.length()]
			text_label.text = displayed_text
			typewriter_timer = typewriter_speed

func start_dialogue(node_id: String):
	var node_data = DialogueManager.get_node_data(node_id)
	if node_data.is_empty():
		print("Dialogue node not found: ", node_id)
		return
	current_node_id = node_id
	is_active = true
	panel.visible = true
	npc_name_label.text = node_data.npc
	full_text = node_data.text
	displayed_text = ""
	text_label.text = ""
	# Wait for full typewriter then show choices
	await get_tree().create_timer(full_text.length() * typewriter_speed).timeout
	show_choices(node_data.choices)

func show_choices(choices: Array):
	choices_container.show()
	for child in choices_container.get_children():
		child.queue_free()
	for choice in choices:
		var btn = Button.new()
		btn.text = choice.label
		btn.pressed.connect(_on_choice_selected.bind(choice.next))
		choices_container.add_child(btn)

func _on_choice_selected(next_node_id: String):
	# Hide choices
	choices_container.hide()
	for child in choices_container.get_children():
		child.queue_free()
	# Continue
	if next_node_id == "end":
		end_dialogue()
	else:
		start_dialogue(next_node_id)

func end_dialogue():
	is_active = false
	panel.visible = false
	# Signal to game that dialogue closed (for combat lock etc.)
	# Maybe emit a signal
	# DialogueClosed.emit()
