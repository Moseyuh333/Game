extends Area2D
class_name HurtBox

var owner_health: int = 30
var max_health: int = 30
var is_enemy: bool = true

signal died

func take_damage(amount: int, knockback_force: Vector2):
	var actual = max(0, amount)  # Simple for now; defense handled at enemy level
	owner_health -= actual
	# Apply knockback to the parent body
	var parent = get_parent()
	if parent and parent is CharacterBody2D:
		parent.velocity += knockback_force
	# Visual flash on enemy sprite
	if actual > 0:
		var parent_node = get_parent()
		if parent_node and parent_node.has_node("Sprite2D"):
			var spr = parent_node.get_node("Sprite2D")
			var original = spr.modulate
			spr.modulate = Color.WHITE
			get_tree().create_timer(0.1).timeout.connect(
				func():
					if is_instance_valid(spr):
						spr.modulate = original
			, CONNECT_ONE_SHOT)
	# Check death
	if owner_health <= 0:
		die()

func die():
	emit_signal("died")
	queue_free()
