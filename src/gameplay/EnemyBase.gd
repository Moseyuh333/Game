extends CharacterBody2D
class_name EnemyBase

signal died(enemy_type: String, is_boss: bool)

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: HurtBox = $HurtBox
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

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
	hurtbox.died.connect(_on_hurtbox_died)
	patrol_center = global_position
	# Navigation setup
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

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
	if navigation_agent.is_navigation_finished():
		# Pick new random patrol point within radius
		var angle = randf() * TAU
		var dist = randf_range(0.0, stats.get("patrol_radius", 100.0))
		patrol_target = patrol_center + Vector2(cos(angle), sin(angle)) * dist
		navigation_agent.target_position = patrol_target
		state_timer = randf_range(1.0, 2.0)
		return

	if not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity = direction * stats.speed
	else:
		velocity = Vector2.ZERO

	# Check for player in chase range
	if target and target.is_alive():
		var dist = global_position.distance_to(target.global_position)
		if dist <= stats.get("chase_range", 150):
			current_state = "chase"
	else:
		# Acquire player if in range
		var player = get_node("/root/GameManager")  # or use a global reference
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

	# Chase
	var chase_speed = stats.get("chase_speed", stats.speed)
	navigation_agent.target_position = target.global_position
	var next_pos = navigation_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
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
	# Instance an ItemPickup scene (to be created)
	# Placeholder: just print for now
	print("Dropped item: ", item_id)
	# Later: var item = item_scene.instantiate()
	# item.item_id = item_id
	# item.global_position = global_position + Vector2(randf_range(-10,10), randf_range(-10,10))
	# get_parent().add_child(item)
