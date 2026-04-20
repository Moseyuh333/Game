extends ColorRect
class_name FadeTransition

var _tween: Tween = null

func _ready():
	add_to_group("fade_transition")
	# Cover entire screen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	color = Color(0, 0, 0, 1)
	# Start with fade-in from black to transparent
	fade_in(0.5)

func fade_in(duration: float = 0.5):
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color:a", 0.0, duration).from(1.0)

func fade_out(duration: float = 0.5, then: Callable = null):
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color:a", 1.0, duration)
	if then:
		_tween.finished.connect(then, CONNECT_ONE_SHOT)
