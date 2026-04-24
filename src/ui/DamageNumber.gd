extends Label
class_name DamageNumber

var velocity: Vector2 = Vector2(0, -50)
var lifetime: float = 1.0
var age: float = 0.0

func _ready():
	# Set label color directly
	modulate = Color(1, 1, 1, 1)

func _process(delta):
	position += velocity * delta
	age += delta
	var t = age / lifetime
	modulate.a = 1.0 - t
	if age >= lifetime:
		queue_free()
