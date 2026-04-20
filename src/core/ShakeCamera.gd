extends Camera2D
class_name ShakeCamera

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta):
	if shake_duration > 0:
		shake_duration -= delta
		var shake = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		offset = original_offset + shake
		if shake_duration <= 0:
			offset = original_offset
			shake_intensity = 0.0

func shake(duration: float, intensity: float):
	shake_duration = duration
	shake_intensity = intensity
