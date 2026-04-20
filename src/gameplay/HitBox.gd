extends Area2D
class_name HitBox

# This is the player's attack detection area
# It should be a child of the player and positioned in front

func _ready():
	monitoring = false  # Only active during attack
	monitorable = false

func activate():
	monitoring = true
	# Deactivate after a short window (0.1s)
	await get_tree().create_timer(0.1).timeout
	monitoring = false
