extends Sprite2D
class_name ProceduralSprite

@export_enum("player", "grunt", "ranged", "boss", "heal", "speed", "armor", "fragment", "npc_clerk", "npc_soul", "portal")
var visual_kind: String = "player"

@export var pixel_size: Vector2i = Vector2i(72, 80)

const TRANSPARENT := Color(0, 0, 0, 0)

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	generate_texture()

func set_visual_kind(kind: String):
	visual_kind = kind
	if is_inside_tree():
		generate_texture()

func generate_texture():
	var img = Image.create(pixel_size.x, pixel_size.y, false, Image.FORMAT_RGBA8)
	img.fill(TRANSPARENT)
	match visual_kind:
		"player":
			_draw_bot(img, Color(0.38, 0.77, 1.0), Color(0.95, 0.97, 1.0), Color(0.08, 0.16, 0.23))
		"grunt":
			_draw_bot(img, Color(0.94, 0.22, 0.18), Color(1.0, 0.65, 0.4), Color(0.22, 0.05, 0.05))
		"ranged":
			_draw_bot(img, Color(1.0, 0.64, 0.12), Color(1.0, 0.9, 0.36), Color(0.25, 0.11, 0.02))
			_draw_barrel(img, Vector2i(45, 36), Color(0.18, 0.17, 0.16))
		"boss":
			_draw_boss(img)
		"heal":
			_draw_item(img, Color(0.2, 1.0, 0.45), Color(0.88, 1.0, 0.76))
		"speed":
			_draw_item(img, Color(0.16, 0.82, 1.0), Color(1.0, 0.95, 0.2))
		"armor":
			_draw_item(img, Color(0.62, 0.68, 0.72), Color(0.95, 0.98, 1.0))
		"fragment":
			_draw_crystal(img, Color(0.7, 0.96, 1.0), Color(0.35, 0.55, 1.0))
		"npc_clerk":
			_draw_bot(img, Color(0.76, 0.58, 0.38), Color(1.0, 0.86, 0.62), Color(0.19, 0.12, 0.08))
		"npc_soul":
			_draw_ghost(img)
		"portal":
			_draw_portal(img)
	texture = ImageTexture.create_from_image(img)

func _put(img: Image, x: int, y: int, color: Color):
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)

func _shade(color: Color, amount: float) -> Color:
	return Color(clamp(color.r * amount, 0.0, 1.0), clamp(color.g * amount, 0.0, 1.0), clamp(color.b * amount, 0.0, 1.0), color.a)

func _ellipse(img: Image, center: Vector2, radius: Vector2, color: Color):
	for y in range(int(center.y - radius.y), int(center.y + radius.y) + 1):
		for x in range(int(center.x - radius.x), int(center.x + radius.x) + 1):
			var nx = (x - center.x) / radius.x
			var ny = (y - center.y) / radius.y
			if nx * nx + ny * ny <= 1.0:
				_put(img, x, y, color)

func _rect(img: Image, rect: Rect2i, color: Color):
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_put(img, x, y, color)

func _diamond(img: Image, center: Vector2i, radius: Vector2i, top: Color, side: Color):
	for y in range(-radius.y, radius.y + 1):
		var width = int((1.0 - abs(float(y)) / radius.y) * radius.x)
		for x in range(-width, width + 1):
			_put(img, center.x + x, center.y + y, top if y <= 0 else side)

func _draw_shadow(img: Image, center: Vector2, radius: Vector2):
	_ellipse(img, center, radius, Color(0.0, 0.0, 0.0, 0.28))

func _draw_bot(img: Image, body: Color, light: Color, dark: Color):
	_draw_shadow(img, Vector2(36, 68), Vector2(22, 7))
	_rect(img, Rect2i(25, 47, 8, 17), _shade(body, 0.6))
	_rect(img, Rect2i(40, 47, 8, 17), _shade(body, 0.55))
	_rect(img, Rect2i(18, 34, 10, 18), _shade(body, 0.75))
	_rect(img, Rect2i(45, 34, 10, 18), _shade(body, 0.7))
	_ellipse(img, Vector2(36, 38), Vector2(18, 22), _shade(body, 0.82))
	_ellipse(img, Vector2(31, 31), Vector2(13, 15), body)
	_ellipse(img, Vector2(36, 21), Vector2(18, 14), _shade(body, 1.12))
	_rect(img, Rect2i(24, 19, 25, 8), light)
	_rect(img, Rect2i(27, 21, 7, 4), dark)
	_rect(img, Rect2i(40, 21, 7, 4), dark)
	_rect(img, Rect2i(35, 9, 2, 8), dark)
	_ellipse(img, Vector2(36, 8), Vector2(4, 4), light)

func _draw_barrel(img: Image, start: Vector2i, color: Color):
	_rect(img, Rect2i(start.x, start.y, 18, 5), color)
	_rect(img, Rect2i(start.x + 12, start.y - 2, 8, 9), _shade(color, 1.35))

func _draw_boss(img: Image):
	var body = Color(0.55, 0.16, 0.92)
	var light = Color(0.98, 0.64, 1.0)
	var dark = Color(0.14, 0.03, 0.2)
	_draw_shadow(img, Vector2(36, 68), Vector2(29, 9))
	_ellipse(img, Vector2(36, 40), Vector2(24, 27), _shade(body, 0.78))
	_ellipse(img, Vector2(36, 26), Vector2(21, 17), body)
	_rect(img, Rect2i(17, 38, 11, 23), _shade(body, 0.55))
	_rect(img, Rect2i(45, 38, 11, 23), _shade(body, 0.52))
	_rect(img, Rect2i(26, 52, 9, 15), _shade(body, 0.45))
	_rect(img, Rect2i(39, 52, 9, 15), _shade(body, 0.45))
	_rect(img, Rect2i(23, 24, 27, 9), light)
	_rect(img, Rect2i(27, 26, 6, 5), dark)
	_rect(img, Rect2i(41, 26, 6, 5), dark)
	_diamond(img, Vector2i(36, 12), Vector2i(7, 10), Color(1.0, 0.88, 0.34), Color(0.85, 0.34, 0.92))

func _draw_item(img: Image, base: Color, light: Color):
	_draw_shadow(img, Vector2(36, 62), Vector2(13, 5))
	_diamond(img, Vector2i(36, 36), Vector2i(18, 22), light, base)
	_rect(img, Rect2i(30, 31, 13, 7), Color(1, 1, 1, 0.55))

func _draw_crystal(img: Image, light: Color, side: Color):
	_draw_shadow(img, Vector2(36, 63), Vector2(12, 5))
	_diamond(img, Vector2i(36, 34), Vector2i(15, 26), light, side)
	_diamond(img, Vector2i(36, 31), Vector2i(6, 18), Color(1, 1, 1, 0.75), Color(0.46, 0.78, 1.0))

func _draw_ghost(img: Image):
	_draw_shadow(img, Vector2(36, 66), Vector2(16, 5))
	_ellipse(img, Vector2(36, 33), Vector2(18, 23), Color(0.55, 0.65, 1.0, 0.78))
	_rect(img, Rect2i(21, 35, 30, 23), Color(0.55, 0.65, 1.0, 0.65))
	_rect(img, Rect2i(29, 27, 5, 5), Color(0.08, 0.1, 0.25, 0.9))
	_rect(img, Rect2i(40, 27, 5, 5), Color(0.08, 0.1, 0.25, 0.9))

func _draw_portal(img: Image):
	for r in range(27, 5, -1):
		var t = float(r) / 27.0
		_ellipse(img, Vector2(36, 38), Vector2(r * 0.75, r), Color(0.15 + t * 0.55, 0.85, 1.0, 0.15 + (1.0 - t) * 0.45))
	_ellipse(img, Vector2(36, 38), Vector2(8, 17), Color(1.0, 1.0, 1.0, 0.68))
