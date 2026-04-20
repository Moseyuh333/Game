extends EnemyBase

var shoot_timer: float = 0.0

func _ready():
	enemy_type = "ranged"
	is_boss = false
	sprite.modulate = Color(1.0, 0.6, 0.0)  # Orange
	super._ready()

func _physics_process(delta):
	match current_state:
		"patrol":
			state_patrol(delta)
		"chase":
			state_ranged(delta)
		"flee":
			state_flee(delta)
		_:
			super._physics_process(delta)

func state_ranged(delta):
	# Keep distance from player and shoot
	if not target or not target.is_alive():
		target = null
		current_state = "patrol"
		return

	var dist = global_position.distance_to(target.global_position)
	if dist < stats.get("flee_range", 60):
		current_state = "flee"
		return

	# Shoot if in range
	if dist <= stats.get("shoot_range", 300):
		shoot_timer -= delta
		if shoot_timer <= 0:
			fire_projectile()
			shoot_timer = stats.shoot_interval
	else:
		# Move closer if too far
		var chase_dir = (target.global_position - global_position).normalized()
		velocity = chase_dir * stats.speed * 0.5
		return

	velocity = velocity.move_toward(Vector2.ZERO, stats.speed * delta)

func state_flee(delta):
	velocity = (global_position - target.global_position).normalized() * stats.speed
	# If far enough, go back to ranged state
	if target:
		var dist = global_position.distance_to(target.global_position)
		if dist > stats.get("flee_range", 60) + 20:
			current_state = "chase"

func fire_projectile():
	var proj_scene = load("res://src/gameplay/Projectile.tscn")
	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position
		proj.direction = (target.global_position - global_position).normalized()
		proj.speed = stats.projectile_speed
		proj.damage = stats.attack
		get_parent().add_child(proj)
