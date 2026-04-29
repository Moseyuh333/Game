extends SceneTree

const SCENES := [
	"res://src/core/Main.tscn",
	"res://src/gameplay/Level01.tscn",
	"res://src/gameplay/Player.tscn",
	"res://src/gameplay/Grunt.tscn",
	"res://src/gameplay/Ranged.tscn",
	"res://src/gameplay/MiniBoss.tscn",
	"res://src/gameplay/ItemPickup.tscn",
	"res://src/gameplay/Projectile.tscn",
	"res://src/gameplay/DeathParticles.tscn",
	"res://src/ui/HUD.tscn",
	"res://src/ui/DialogueBox.tscn",
	"res://src/ui/InventoryUI.tscn",
	"res://src/ui/GameOver.tscn",
	"res://src/ui/WinScreen.tscn",
	"res://src/ui/DamageNumber.tscn",
	"res://node_2d.tscn",
]

const SCRIPTS := [
	"res://src/core/FadeTransition.gd",
	"res://src/core/GameManager.gd",
	"res://src/core/SaveManager.gd",
	"res://src/core/ShakeCamera.gd",
	"res://src/gameplay/DeathParticles.gd",
	"res://src/gameplay/EnemyBase.gd",
	"res://src/gameplay/Grunt.gd",
	"res://src/gameplay/HitBox.gd",
	"res://src/gameplay/HurtBox.gd",
	"res://src/gameplay/Inventory.gd",
	"res://src/gameplay/ItemPickup.gd",
	"res://src/gameplay/Level01.gd",
	"res://src/gameplay/MiniBoss.gd",
	"res://src/gameplay/NPCInteraction.gd",
	"res://src/gameplay/Player.gd",
	"res://src/gameplay/Projectile.gd",
	"res://src/gameplay/Ranged.gd",
	"res://src/ui/DamageNumber.gd",
	"res://src/ui/DialogueBox.gd",
	"res://src/ui/DialogueManager.gd",
	"res://src/ui/GameOver.gd",
	"res://src/ui/HUD.gd",
	"res://src/ui/InventoryUI.gd",
	"res://src/ui/WinScreen.gd",
]

func _init():
	call_deferred("_run")

func _run():
	for script_path in SCRIPTS:
		if load(script_path) == null:
			push_error("Failed to load script: %s" % script_path)
			quit(1)
			return
	for scene_path in SCENES:
		var scene = load(scene_path)
		if scene == null:
			push_error("Failed to load scene: %s" % scene_path)
			quit(1)
			return
		var instance = scene.instantiate()
		if instance == null:
			push_error("Failed to instantiate scene: %s" % scene_path)
			quit(1)
			return
		root.add_child(instance)
		await process_frame
		instance.queue_free()
		await process_frame
	print("Scene smoke test passed: %d scripts and %d scenes loaded." % [SCRIPTS.size(), SCENES.size()])
	quit(0)
