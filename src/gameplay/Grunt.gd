extends EnemyBase

func _ready():
	enemy_type = "grunt"
	is_boss = false
	sprite.modulate = Color(1.0, 0.2, 0.2)  # Red
	# Create placeholder texture
	if not sprite.texture:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(sprite.modulate)
		sprite.texture = ImageTexture.create_from_image(img)
	super._ready()
