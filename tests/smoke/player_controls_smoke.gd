extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var player_script = load("res://src/gameplay/Player.gd")
	if player_script == null:
		push_error("Failed to load Player.gd.")
		quit(1)
		return
	var player = player_script.new()
	player.ensure_input_actions()

	if not _expect_vector("move_right", Vector2.RIGHT):
		return
	if not _expect_vector("move_left", Vector2.LEFT):
		return
	if not _expect_vector("move_down", Vector2.DOWN):
		return
	if not _expect_vector("move_up", Vector2.UP):
		return

	for action_name in ["dash", "skill", "attack", "interact", "inventory"]:
		if not InputMap.has_action(action_name):
			push_error("Missing action: %s" % action_name)
			quit(1)
			return

	player.free()
	print("Player controls smoke test passed.")
	quit(0)

func _expect_vector(action_name: String, expected: Vector2) -> bool:
	_release_actions()
	Input.action_press(action_name)
	var actual = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	Input.action_release(action_name)
	if actual != expected:
		push_error("%s produced %s, expected %s" % [action_name, actual, expected])
		quit(1)
		return false
	return true

func _release_actions():
	for action_name in ["move_right", "move_left", "move_down", "move_up", "attack", "dash", "skill"]:
		Input.action_release(action_name)
