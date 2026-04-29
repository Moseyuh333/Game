extends CPUParticles2D
class_name DeathParticles

func _ready():
	one_shot = true
	emitting = true
	finished.connect(queue_free, CONNECT_ONE_SHOT)
