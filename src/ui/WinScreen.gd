extends CanvasLayer
class_name WinScreen

@onready var label: Label = $Panel/Label
@onready var quit_button: Button = $Panel/QuitButton

func _ready():
	label.text = "The Clerk's Ascent — Complete!\nYou have reached the Central Archive."
	quit_button.pressed.connect(_on_quit)

func _on_quit():
	get_tree().quit()
