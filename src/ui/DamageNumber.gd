extends Label
class_name DamageNumber

var velocity: Vector2 = Vector2(0, -50)
var lifetime: float = 1.0
var age: float = 0.0

func _ready():
	# Set initial style
	theme_override_colors = {
		"font_color": Color(1, 1, 1, 1),
		"font_shadow_color": Color(0, 0, 0, 1)
	}
	# Start at bottom of node? Actually we'll set position from caller

func _process(delta):
	position += velocity * delta
	age += delta
	var t = age / lifetime
	modulate.a = 1.0 - t
	if age >= lifetime:
		queue_free()
