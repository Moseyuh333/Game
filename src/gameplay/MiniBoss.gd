extends EnemyBase

var phase: int = 1
var slam_timer: float = 0.0
var spin_timer: float = 0.0
var is_stunned: bool = false

func _ready():
	enemy_type = "miniboss"
	is_boss = true
	sprite.modulate = Color.WHITE
	if sprite.has_method("set_visual_kind"):
		sprite.set_visual_kind("boss")
	if not sprite.texture:
		var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
		img.fill(sprite.modulate)
		sprite.texture = ImageTexture.create_from_image(img)
	super._ready()
	# Setup AOE detection area
	var aoe_area = $AoeDetectionArea
	if aoe_area:
		aoe_area.collision_mask = 1  # Player layer
		aoe_area.monitoring = true

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
		var player = get_tree().get_first_node_in_group("player")
		if player and player.is_alive():
			target = player
			current_state = "chase"
		else:
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
	var bodies = $AoeDetectionArea.get_overlapping_bodies() if has_node("AoeDetectionArea") else []
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
	var hurtboxes = $AoeDetectionArea.get_overlapping_areas() if has_node("AoeDetectionArea") else []
	for body in hurtboxes:
		if body is HurtBox and body.owner_health > 0:
			var knockback = (body.global_position - global_position).normalized() * 300.0
			body.take_damage(damage, knockback)

func take_damage(amount: int, knockback_force: Vector2 = Vector2.ZERO):
	# Handle phase transition
	var actual = max(0, amount - stats.defense)
	if hurtbox:
		hurtbox.owner_health -= actual
		# Apply knockback directly
		if self is CharacterBody2D:
			velocity += knockback_force
		# Visual flash
		if actual > 0 and sprite:
			var original = sprite.modulate
			sprite.modulate = Color.WHITE
			get_tree().create_timer(0.1).timeout.connect(
				func():
					if is_instance_valid(sprite):
						sprite.modulate = original
			, CONNECT_ONE_SHOT)
		# Check death
		if hurtbox.owner_health <= 0:
			_on_hurtbox_died()
		# Check phase transition
		if actual > 0 and hurtbox.owner_health <= stats.phase2_threshold and phase == 1:
			phase = 2
			current_state = "chase"
	return actual

func _on_hurtbox_died():
	# Drop boss loot
	drop_loot()
	emit_signal("died", "miniboss", true)
	queue_free()
