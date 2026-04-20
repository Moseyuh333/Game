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
	if has_method("apply_knockback"):
		apply_knockback(knockback_force)
	else:
		# Knockback parent (enemy)
		var parent = get_parent()
		if parent and parent is CharacterBody2D:
			parent.velocity += knockback_force
	# Visual flash (implement later)
	if owner_health <= 0:
		die()

func die():
	emit_signal("died")
	queue_free()
