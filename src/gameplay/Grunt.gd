extends EnemyBase

func _ready():
	enemy_type = "grunt"
	is_boss = false
	sprite.modulate = Color(1.0, 0.2, 0.2)  # Red
	super._ready()
