extends Node2D
class_name Level01

@onready var tilemap: TileMap = $TileMap
@onready var player_spawn: Node2D = $PlayerSpawn
@onready var boss_room_door: StaticBody2D = $BossRoomDoor if has_node("BossRoomDoor") else null
@onready var exit_portal: Area2D = $ExitPortal

var boss_defeated: bool = false

func _ready():
	build_level()
	spawn_player()
	spawn_enemies()
	spawn_items()
	spawn_npcs()
	setup_lighting()
	# Ensure door is environment collision
	if boss_room_door:
		boss_room_door.collision_layer = 4
	exit_portal.body_entered.connect(_on_exit_body_entered)

func build_level():
	# Create a simple tilemap with floor and walls
	var tile_size = 32
	var width = 60
	var height = 45

	# Ensure tilemap node exists
	if not tilemap:
		tilemap = TileMap.new()
		tilemap.name = "TileMap"
		add_child(tilemap)

	# Create a TileSet resource
	var tile_set = TileSet.new()
	tilemap.tile_set = tile_set

	# Add a source (single tile)
	var source = TileSetAtlasSource.new()
	var texture = ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	texture.image.fill(Color(0.4, 0.4, 0.4))  # Gray floor
	source.texture = texture
	source.texture_region_size = Vector2i(32, 32)
	source.margins = Vector2i(0, 0)
	source.create_tile(Vector2i(0, 0))
	tile_set.add_source(source, 0)

	# Wall tile (darker)
	var wall_source = TileSetAtlasSource.new()
	var wall_texture = ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	wall_texture.image.fill(Color(0.2, 0.2, 0.2))
	wall_source.texture = wall_texture
	wall_source.texture_region_size = Vector2i(32, 32)
	wall_source.create_tile(Vector2i(0, 0))
	tile_set.add_source(wall_source, 1)

	# Build a simple layout (0=floor, 1=wall)
	var map_data = []
	# Initialize all floor
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(0)
		map_data.append(row)

	# Carve rooms (rough rectangles)
	# Entrance room: (5,5)-(15,15)
	for y in range(5, 16):
		for x in range(5, 16):
			map_data[y][x] = 0

	# Exploration area: (20,5)-(55,25)
	for y in range(5, 26):
		for x in range(20, 56):
			map_data[y][x] = 0

	# NPC room: (20,30)-(35,42)
	for y in range(30, 43):
		for x in range(20, 36):
			map_data[y][x] = 0

	# Corridor: (5,30)-(15,42)
	for y in range(30, 43):
		for x in range(5, 16):
			map_data[y][x] = 0
	# Connect corridor to NPC room (door)
	for y in range(30, 36):
		for x in range(16, 20):
			map_data[y][x] = 0

	# Boss room: (40,30)-(55,42)
	for y in range(30, 43):
		for x in range(40, 56):
			map_data[y][x] = 0

	# Exit portal location (inside boss room)
	# Leave as floor

	# Place walls around rooms (simple)
	for y in range(height):
		for x in range(width):
			if map_data[y][x] == 0:
				# Check neighbors
				var is_wall_edge = false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var nx = x + dx
						var ny = y + dy
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							is_wall_edge = true
						elif map_data[ny][nx] != 0:
							is_wall_edge = true
				if is_wall_edge:
					map_data[y][x] = 1

	# Apply to tilemap
	for y in range(height):
		for x in range(width):
			var tile_id = map_data[y][x]
			tilemap.set_cell(0, Vector2i(x, y), tile_id, Vector2i(0, 0))

	# Add collision to wall layer
	tilemap.collision_enabled = true
	tilemap.collision_layer = 4  # Environment layer (layer 4)
	tilemap.collision_mask = 3   # Collide with Player (1) and Enemies (2)

func spawn_player():
	var player_scene = load("res://src/gameplay/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.global_position = player_spawn.global_position if player_spawn else Vector2(256, 256)
		add_child(player)
	else:
		# Fallback: create player manually from script
		var player = preload("res://src/gameplay/Player.gd").new()
		player.name = "Player"
		player.global_position = player_spawn.global_position if player_spawn else Vector2(256, 256)
		add_child(player)

	# Set player as target for enemies? Enemies will find via autoload

func spawn_enemies():
	# Grunts in exploration area (around 400, 250)
	var grunt_scene = load("res://src/gameplay/Grunt.tscn")
	for i in range(4):
		var grunt = grunt_scene.instantiate()
		grunt.name = "Grunt%d" % i
		grunt.global_position = Vector2(400 + randf_range(-50, 50), 250 + randf_range(-50, 50))
		add_child(grunt)

	# Ranged in corridor (around 150, 380)
	var ranged_scene = load("res://src/gameplay/Ranged.tscn")
	for i in range(2):
		var ranged = ranged_scene.instantiate()
		ranged.name = "Ranged%d" % i
		ranged.global_position = Vector2(150 + randf_range(-20, 20), 380 + randf_range(-30, 30))
		add_child(ranged)

	# MiniBoss in boss room (around 600, 380)
	var boss_scene = load("res://src/gameplay/MiniBoss.tscn")
	var boss = boss_scene.instantiate()
	boss.name = "MiniBoss"
	boss.global_position = Vector2(600, 380)
	boss.died.connect(_on_boss_died)
	add_child(boss)

func spawn_items():
	# Place items from item list
	var item_positions = [
		Vector2(350, 200),  # exploration: heal potion
		Vector2(450, 300),  # speed boost
		Vector2(150, 420),  # corridor: plating
	]
	var item_types = ["heal_potion", "speed_boost", "plating"]
	for i in range(item_positions.size()):
		var pickup = Area2D.new()
		pickup.name = "ItemPickup_%s" % item_types[i]
		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		col.shape.radius = 16
		pickup.add_child(col)
		var sprite = Sprite2D.new()
		sprite.modulate = Color.GREEN if item_types[i] == "heal_potion" else Color.CYAN
		sprite.texture = null
		sprite.custom_colors = {}
		# Simple rect
		sprite.modulate = Color(0,1,0) if i==0 else (Color(0,1,1) if i==1 else Color(0.5))
		pickup.add_child(sprite)
		pickup.set_script(load("res://src/gameplay/ItemPickup.gd"))
		pickup.item_id = item_types[i]
		pickup.global_position = item_positions[i]
		add_child(pickup)

	# Soul fragments (5 total)
	for i in range(5):
		var fragment = Area2D.new()
		fragment.name = "SoulFragment%d" % i
		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		col.shape.radius = 12
		fragment.add_child(col)
		var sprite = Sprite2D.new()
		sprite.modulate = Color(1, 1, 1)
		fragment.add_child(sprite)
		fragment.set_script(load("res://src/gameplay/ItemPickup.gd"))
		fragment.item_id = "soul_fragment"
		# Position near enemies: 2 near grunts, 2 near ranged, 1 near boss
		var positions = [Vector2(380,230), Vector2(420,270), Vector2(130,360), Vector2(170,400), Vector2(580,360)]
		fragment.global_position = positions[i]
		add_child(fragment)

func spawn_npcs():
	# Archive Clerk in NPC room (around 280, 380)
	var npc1 = StaticBody2D.new()
	npc1.name = "ArchiveClerk"
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.8, 0.6, 0.4)
	npc1.add_child(sprite)
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 16
	npc1.add_child(col)
	# Interaction area
	var interact_area = Area2D.new()
	interact_area.name = "InteractionArea"
	var col2 = CollisionShape2D.new()
	col2.shape = CircleShape2D.new()
	col2.shape.radius = 60
	interact_area.add_child(col2)
	npc1.add_child(interact_area)
	# Add NPC interaction script
	npc1.set_script(load("res://src/gameplay/NPCInteraction.gd"))
	npc1.npc_name = "Archive Clerk"
	npc1.dialogue_start_node = "npc_01_start"
	npc1.global_position = Vector2(280, 380)
	add_child(npc1)

	# Wandering Soul in exploration area (around 500, 150)
	var npc2 = StaticBody2D.new()
	npc2.name = "WanderingSoul"
	var sprite2 = Sprite2D.new()
	sprite2.modulate = Color(0.6, 0.6, 0.9)
	npc2.add_child(sprite2)
	var col3 = CollisionShape2D.new()
	col3.shape = CircleShape2D.new()
	col3.shape.radius = 16
	npc2.add_child(col3)
	var interact_area2 = Area2D.new()
	interact_area2.name = "InteractionArea"
	var col4 = CollisionShape2D.new()
	col4.shape = CircleShape2D.new()
	col4.shape.radius = 60
	interact_area2.add_child(col4)
	npc2.add_child(interact_area2)
	# Add NPC interaction script
	npc2.set_script(load("res://src/gameplay/NPCInteraction.gd"))
	npc2.npc_name = "Wandering Soul"
	npc2.dialogue_start_node = "npc_02_start"
	npc2.global_position = Vector2(500, 150)
	add_child(npc2)

func setup_lighting():
	# Player light is attached to player, not here
	# Boss room: dark overlay
	var dark = ColorRect.new()
	dark.name = "BossDarkness"
	dark.size = Vector2(600, 400)
	dark.position = Vector2(380, 200)
	dark.color = Color(0, 0, 0, 0.7)
	dark.z_index = -1
	add_child(dark)
	# Will fade when boss dies

func _on_boss_died(type: String, is_boss_flag: bool):
	if is_boss_flag:
		boss_defeated = true
		# Open exit door
		if boss_room_door:
			boss_room_door.queue_free()
		# Fade out darkness
		var dark = $BossDarkness
		if dark:
			var tween = create_tween()
			tween.tween_property(dark, "color:a", 0.0, 2.0)

func _on_exit_body_entered(body):
	if body.name == "Player" and boss_defeated:
		# Show win screen (existing node in Main)
		var win = get_tree().get_first_node_in_group("win_screen")
		if win:
			win.show()
		else:
			# Fallback: load separate scene
			get_tree().change_scene_to(load("res://src/ui/WinScreen.tscn"))
