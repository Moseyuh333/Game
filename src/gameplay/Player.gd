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
var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var speed_multiplier: float = 1.0
var speed_boost_timer: float = 0.0

func _ready():
	# Ensure GameManager is loaded
	if not GameManager:
		push_error("GameManager autoload not found!")
		return
	# Add to player group for UI lookup
	add_to_group("player")
	# Initialize inventory
	inventory = Inventory.new()
	update_sprite_color()
	# Center camera
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	# Connect death signal
	player_died.connect(_on_player_died)

func _process(delta):
	# Attack cooldown
	if attack_timer > 0:
		attack_timer -= delta

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
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		velocity = input_dir * GameManager.stats.speed * speed_multiplier
		facing_direction = input_dir
	else:
		velocity = velocity.move_toward(Vector2.ZERO, GameManager.stats.speed * speed_multiplier * delta)

	move_and_slide()

	# Attack input
	if Input.is_action_just_pressed("attack") and attack_timer <= 0:
		perform_attack()
		attack_timer = attack_cooldown

func perform_attack():
	var attack_range = 60.0
	var attack_arc = deg_to_rad(90)  # 90 degree cone in facing direction
	var attack_origin = global_position + facing_direction * 20  # Slight forward offset

	# Visual: rotate hitbox area to face direction
	hitbox_area.rotation = facing_direction.angle()
	hitbox_area.position = attack_origin - global_position

	# Temporarily enable hitbox to detect enemies
	# We'll use a oneshot check
	var bodies = hitbox_area.get_overlapping_areas()
	for body in bodies:
		if body is Area2D and body.has_method("take_damage"):
			body.take_damage(GameManager.stats.attack, facing_direction * 200.0)

func take_damage(amount: int):
	if invincible:
		return 0
	var actual = GameManager.take_damage(amount)
	if actual > 0:
		invincible = true
		invincibility_timer = 0.5
		# Optional: screen shake handled by GameManager or Camera
	return actual

func apply_speed_boost(multiplier: float, duration: float):
	speed_multiplier = multiplier
	speed_boost_timer = duration

func update_sprite_color():
	# Blue color for player
	var c = Color(0.2, 0.5, 1.0, 1.0)
	sprite.modulate = c
	# Set sprite to a simple rectangle
	sprite.texture = null
	sprite.custom_colors = {}
	# We'll use a ColorRect for the player visual in the scene

func _die():
	if not GameManager.is_alive():
		player_died.emit()
		# Show game over screen
		var game_over = get_tree().get_first_node_in_group("game_over")
		if game_over:
			game_over.show()
		else:
			# Fallback: just quit
			get_tree().quit()
		queue_free()

func _on_health_changed():
	if not GameManager.is_alive():
		_die()

func _on_player_died():
	# Additional cleanup if needed
	pass
