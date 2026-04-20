extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 150.0
var damage: int = 10
var lifetime: float = 3.0
var age: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		body.take_damage(damage)
		queue_free()
	# Could also hit walls/enemies? For now only player
