extends EnemyBase

func _ready():
	enemy_type = "grunt"
	is_boss = false
	sprite.modulate = Color.WHITE
	if sprite.has_method("set_visual_kind"):
		sprite.set_visual_kind("grunt")
	# Create placeholder texture
	if not sprite.texture:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(sprite.modulate)
		sprite.texture = ImageTexture.create_from_image(img)
	super._ready()
