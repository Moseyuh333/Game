extends EnemyBase

var phase: int = 1
var slam_timer: float = 0.0
var spin_timer: float = 0.0
var is_stunned: bool = false

func _ready():
	enemy_type = "miniboss"
	is_boss = true
	sprite.modulate = Color(0.6, 0.0, 1.0)  # Purple
	super._ready()

func _physics_process(delta):
	if is_stunned:
		velocity = Vector2.ZERO
		return

	match current_state:
		"patrol":
			state_boss_phase1(delta)
		"chase":
			state_boss_phase1(delta)
		"attack":
			state_boss_attack(delta)

	move_and_slide()

func state_boss_phase1(delta):
	if not target or not target.is_alive():
		target = null
		current_state = "patrol"
		velocity = Vector2.ZERO
		return

	var dist = global_position.distance_to(target.global_position)
	if dist <= 40:
		current_state = "attack"
		state_timer = stats.slam_interval
		return

	# Charge toward player
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * stats.charge_speed

func state_boss_attack(delta):
	velocity = Vector2.ZERO
	state_timer -= delta
	if state_timer <= 0:
		# Perform slam attack (AoE)
		deal_aoe_damage(stats.aoe_radius, stats.attack)
		# Stun self for 1s after slam
		is_stunned = true
		await get_tree().create_timer(1.0).timeout
		is_stunned = false
		# Back to chase
		current_state = "chase"

func deal_aoe_damage(radius: float, damage: int):
	# Find all HurtBoxes in radius
	var bodies = $AoeDetectionArea.get_overlapping_areas() if has_node("AoeDetectionArea") else []
	for body in bodies:
		if body is HurtBox and body.owner_health > 0:
			var knockback = (body.global_position - global_position).normalized() * 300.0
			body.take_damage(damage, knockback)

func take_damage(amount: int, knockback_force: Vector2 = Vector2.ZERO):
	# Override to handle phase transition
	var actual = super.take_damage(amount, knockback_force)
	if actual > 0 and hurtbox.owner_health <= stats.phase2_threshold and phase == 1:
		phase = 2
		current_state = "chase"
		# Visual cue: sprite flash purple?
	return actual

func _on_hurtbox_died():
	# Drop boss loot
	drop_loot()
	emit_signal("died", "miniboss", true)
	queue_free()
