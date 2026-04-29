extends Node2D
class_name ArenaDressing

func _ready():
	z_index = -5
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2(-64, -64), Vector2(2100, 1600)), Color(0.06, 0.07, 0.08, 1.0))
	for y in range(0, 46):
		for x in range(0, 61):
			var p = Vector2(x * 32, y * 32)
			var base = Color(0.18, 0.19, 0.19) if (x + y) % 2 == 0 else Color(0.14, 0.15, 0.16)
			var poly = PackedVector2Array([p + Vector2(16, 0), p + Vector2(32, 9), p + Vector2(16, 18), p + Vector2(0, 9)])
			draw_colored_polygon(poly, base)
			draw_polyline(poly + PackedVector2Array([poly[0]]), Color(0.04, 0.05, 0.05, 0.6), 1.0)
	for point in [Vector2(280, 380), Vector2(500, 150), Vector2(600, 380), Vector2(650, 380)]:
		draw_circle(point, 85, Color(0.38, 0.65, 0.9, 0.08))
