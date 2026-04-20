extends CharacterBody2D
class_name EnemyBase

signal died(enemy_type: String, is_boss: bool)

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: HurtBox = $HurtBox

var enemy_type: String = "base"
var is_boss: bool = false

var stats: Dictionary = {}
var current_state: String = "patrol"
var state_timer: float = 0.0
var patrol_center: Vector2 = Vector2.ZERO
var patrol_target: Vector2 = Vector2.ZERO
var target: Node2D = null

func _ready():
	# Load stats based on enemy_type
	load_enemy_stats()
	hurtbox.owner_health = stats.max_hp
	hurtbox.max_health = stats.max_hp
	hurtbox.is_enemy = true
	hurtbox.collision_layer = 2  # Enemies layer
	hurtbox.died.connect(_on_hurtbox_died)
	patrol_center = global_position
	# Set body collision: layer 2 (Enemies), mask 4 (Environment)
	collision_layer = 2
	collision_mask = 4

func load_enemy_stats():
	var file = FileAccess.open("res://assets/data/enemies.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		if data and data.has(enemy_type):
			stats = data[enemy_type]
		file.close()
	else:
		push_warning("Enemy stats not found, using defaults")
		stats = { "max_hp": 30, "attack": 5, "defense": 0, "speed": 50 }

func _physics_process(delta):
	match current_state:
		"patrol":
			state_patrol(delta)
		"chase":
			state_chase(delta)
		"attack":
			state_attack(delta)
		"flee":
			state_flee(delta)

	move_and_slide()

func state_patrol(delta):
	# Move toward patrol_target
	var to_target = patrol_target - global_position
	if to_target.length() < 5.0:
		# Pick new random patrol point within radius
		var angle = randf() * TAU
		var dist = randf_range(0.0, stats.get("patrol_radius", 100.0))
		patrol_target = patrol_center + Vector2(cos(angle), sin(angle)) * dist
		state_timer = randf_range(1.0, 2.0)
		velocity = Vector2.ZERO
		return

	var direction = to_target.normalized()
	velocity = direction * stats.speed

	# Check for player in chase range
	if target and target.is_alive():
		var dist = global_position.distance_to(target.global_position)
		if dist <= stats.get("chase_range", 150):
			current_state = "chase"
	else:
		# Acquire player if in range
		var player = get_tree().get_first_node_in_group("player")
		if player and player.is_alive():
			var dist = global_position.distance_to(player.global_position)
			if dist <= stats.get("chase_range", 150):
				target = player
				current_state = "chase"

func state_chase(delta):
	if not target or not target.is_alive():
		target = null
		current_state = "patrol"
		return

	var dist = global_position.distance_to(target.global_position)
	# If in attack range, switch to attack
	if dist <= 40:  # Melee attack range
		current_state = "attack"
		state_timer = stats.get("attack_interval", 1.0)
		return

	# Chase directly (move_and_slide will handle collisions)
	var direction = (target.global_position - global_position).normalized()
	var chase_speed = stats.get("chase_speed", stats.speed)
	velocity = direction * chase_speed

func state_attack(delta):
	velocity = Vector2.ZERO
	state_timer -= delta
	if state_timer <= 0:
		# Deal damage to player
		if target and target.is_alive():
			var dmg = max(1, stats.attack - GameManager.stats.defense)
			target.take_damage(dmg)
		# Return to chase
		current_state = "chase"

func state_flee(delta):
	# Ranged enemy: keep distance from player
	if not target or not target.is_alive():
		current_state = "patrol"
		return
	var dist = global_position.distance_to(target.global_position)
	if dist >= stats.get("shoot_range", 200):
		current_state = "chase"  # Actually, just shoot from distance
		return
	# Move away
	var flee_dir = (global_position - target.global_position).normalized()
	velocity = flee_dir * stats.speed

func _on_hurtbox_died():
	# Spawn death particles
	var particle_scene = load("res://src/gameplay/DeathParticles.tscn")
	if particle_scene:
		var particles = particle_scene.instantiate()
		particles.global_position = global_position
		# Match particle color to enemy sprite color
		if sprite:
			particles.color = sprite.modulate
		get_parent().add_child(particles)
	# Drop loot
	drop_loot()
	# Emit died signal
	emit_signal("died", enemy_type, is_boss)
	queue_free()

func drop_loot():
	var drop_table = stats.get("drop_table", [])
	if drop_table.size() == 0:
		return
	# Pick one drop randomly by weight
	var total_weight = 0
	for drop in drop_table:
		total_weight += drop.weight
	var roll = randf() * total_weight
	var cumulative = 0
	for drop in drop_table:
		cumulative += drop.weight
		if roll <= cumulative:
			spawn_item(drop.item_id)
			break

func spawn_item(item_id: String):
	var item_scene = load("res://src/gameplay/ItemPickup.tscn")
	if item_scene:
		var item = item_scene.instantiate()
		item.item_id = item_id
		item.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(item)
