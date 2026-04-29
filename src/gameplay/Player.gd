extends CharacterBody2D
class_name Player

signal player_died

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_area: Area2D = $HitBoxArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D

var inventory: Inventory = null
var facing_direction: Vector2 = Vector2.RIGHT
var invincible: bool = false
var invincibility_timer: float = 0.0
var attack_timer: float = 0.0
var speed_multiplier: float = 1.0
var speed_boost_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var skill_cooldown_timer: float = 0.0

func _ready():
	ensure_input_actions()
	# Ensure GameManager is loaded
	if not GameManager:
		push_error("GameManager autoload not found!")
		return
	# Add to player group for UI lookup
	add_to_group("player")
	# Initialize inventory
	inventory = Inventory.new()
	update_sprite_color()
	# Set hitbox collision mask to Enemies layer (2)
	hitbox_area.collision_mask = 2
	# Set body collision: layer 1 (Player), mask 4 (Environment)
	collision_layer = 1
	collision_mask = 4
	# Center camera
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	# Connect death signal
	player_died.connect(_on_player_died)

func _process(delta):
	# Attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if skill_cooldown_timer > 0:
		skill_cooldown_timer -= delta
	if dash_timer > 0:
		dash_timer -= delta

	# Speed boost timer
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_multiplier = 1.0

	# Invincibility timer
	if invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			invincible = false
			sprite.modulate = Color.WHITE
		else:
			# Blink effect: toggle alpha every 0.05s
			var blink = (int(invincibility_timer * 20) % 2 == 0)
			sprite.modulate = Color(1, 1, 1, 0.5) if blink else Color.WHITE

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir.length() > 0:
		facing_direction = input_dir

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash(input_dir)

	if dash_timer > 0:
		velocity = dash_direction * GameManager.stats.get("dash_speed", 420)
	elif input_dir.length() > 0:
		velocity = input_dir * GameManager.stats.speed * speed_multiplier
	else:
		velocity = velocity.move_toward(Vector2.ZERO, GameManager.stats.speed * speed_multiplier * 8.0 * delta)

	move_and_slide()

	# Attack input
	if Input.is_action_just_pressed("attack") and attack_timer <= 0:
		perform_attack()
		attack_timer = GameManager.stats.get("attack_cooldown", 0.5)
	if Input.is_action_just_pressed("skill") and skill_cooldown_timer <= 0:
		perform_skill()

func perform_attack():
	var attack_range = GameManager.stats.get("attack_range", 60)
	hitbox_area.position = facing_direction * 30
	hitbox_area.rotation = facing_direction.angle()
	damage_enemies_in_arc(attack_range, deg_to_rad(GameManager.stats.get("attack_arc_degrees", 110)), GameManager.stats.attack)
	spawn_combat_ring(attack_range, Color(0.9, 0.95, 1.0, 0.55), 0.12)
	# Reset attack timer from data
	attack_timer = GameManager.stats.get("attack_cooldown", 0.5)

func start_dash(input_dir: Vector2):
	dash_direction = input_dir if input_dir.length() > 0 else facing_direction
	dash_timer = GameManager.stats.get("dash_duration", 0.16)
	dash_cooldown_timer = GameManager.stats.get("dash_cooldown", 0.75)
	invincible = true
	invincibility_timer = max(invincibility_timer, dash_timer)
	spawn_combat_ring(28, Color(0.35, 0.85, 1.0, 0.45), 0.18)

func perform_skill():
	var radius = GameManager.stats.get("skill_radius", 120)
	var damage = GameManager.stats.get("skill_damage", 25)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= radius and enemy.has_node("HurtBox"):
			var hurtbox = enemy.get_node("HurtBox")
			var knockback_dir = (enemy.global_position - global_position).normalized()
			hurtbox.take_damage(damage, knockback_dir * GameManager.stats.get("knockback_force", 200))
	skill_cooldown_timer = GameManager.stats.get("skill_cooldown", 4.0)
	spawn_combat_ring(radius, Color(0.3, 0.95, 1.0, 0.8), 0.32)

func damage_enemies_in_arc(attack_range: float, arc_radians: float, damage: int):
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_node("HurtBox"):
			continue
		var to_enemy = enemy.global_position - global_position
		var distance = to_enemy.length()
		if distance > attack_range:
			continue
		if distance > 0.01 and abs(facing_direction.angle_to(to_enemy.normalized())) > arc_radians * 0.5:
			continue
		var knockback = facing_direction * GameManager.stats.get("knockback_force", 200)
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, knockback)
		else:
			enemy.get_node("HurtBox").take_damage(damage, knockback)

func spawn_combat_ring(radius: float, color: Color, duration: float):
	var ring = Line2D.new()
	ring.width = 3.0
	ring.default_color = color
	ring.closed = true
	ring.z_index = 20
	for i in range(33):
		var angle = TAU * float(i) / 32.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * radius)
	add_child(ring)
	var tween = create_tween()
	ring.scale = Vector2(0.25, 0.25)
	tween.parallel().tween_property(ring, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(ring.queue_free, CONNECT_ONE_SHOT)

func ensure_input_actions():
	reset_input_action("move_up")
	reset_input_action("move_down")
	reset_input_action("move_left")
	reset_input_action("move_right")
	reset_input_action("attack")
	reset_input_action("interact")
	reset_input_action("inventory")
	reset_input_action("dash")
	reset_input_action("skill")
	add_key_action("move_up", [KEY_W, KEY_UP])
	add_key_action("move_down", [KEY_S, KEY_DOWN])
	add_key_action("move_left", [KEY_A, KEY_LEFT])
	add_key_action("move_right", [KEY_D, KEY_RIGHT])
	add_key_action("attack", [KEY_SPACE])
	add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	add_key_action("interact", [KEY_E])
	add_key_action("inventory", [KEY_I])
	add_key_action("dash", [KEY_SHIFT])
	add_key_action("skill", [KEY_Q])

func reset_input_action(action_name: String):
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputMap.add_action(action_name)

func add_key_action(action_name: String, keys: Array):
	for key in keys:
		var event = InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)

func add_mouse_action(action_name: String, button_index: MouseButton):
	var event = InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)

func take_damage(amount: int):
	if invincible:
		return 0
	var actual = GameManager.take_damage(amount)
	if actual > 0:
		invincible = true
		invincibility_timer = GameManager.stats.get("invincibility_duration", 0.5)
		# Trigger screen shake
		if camera and camera.has_method("shake"):
			camera.shake(0.2, 5.0)
		if not GameManager.is_alive():
			_die()
	return actual

func is_alive() -> bool:
	return GameManager.is_alive()

func apply_speed_boost(multiplier: float, duration: float):
	speed_multiplier = multiplier
	speed_boost_timer = duration

func update_sprite_color():
	if sprite and sprite.has_method("set_visual_kind"):
		sprite.set_visual_kind("player")
		sprite.modulate = Color.WHITE
		return
	# Create a simple 16x16 blue square texture if not already set
	if not sprite.texture:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.2, 0.5, 1.0, 1.0))
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
	else:
		sprite.modulate = Color(0.2, 0.5, 1.0, 1.0)

func _die():
	if not GameManager.is_alive():
		player_died.emit()
		# Fade out then show game over
		var fade = get_tree().get_first_node_in_group("fade_transition")
		if fade and fade.has_method("fade_out"):
			fade.fade_out(0.5, Callable(func():
				var game_over = get_tree().get_first_node_in_group("game_over")
				if game_over:
					game_over.show()
			))
		else:
			var game_over = get_tree().get_first_node_in_group("game_over")
			if game_over:
				game_over.show()
		queue_free()

func _on_player_died():
	# Additional cleanup if needed
	pass
