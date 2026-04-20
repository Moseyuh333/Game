extends CPUParticles2D
class_name DeathParticles

func _ready():
	emitting = true
	# Auto-free after particles finish
	var lifetime = 0.5  # slightly longer than particle lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _exit_tree():
	# Ensure cleanup
	queue_free()
