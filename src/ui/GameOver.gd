extends CanvasLayer
class_name GameOver

@onready var restart_button: Button = $Panel/RestartButton

func _ready():
	add_to_group("game_over")
	hide()  # Hide initially
	restart_button.pressed.connect(_on_restart)

func _on_restart():
	# Reload the main scene (or level)
	get_tree().change_scene_to_file("res://src/core/Main.tscn")
