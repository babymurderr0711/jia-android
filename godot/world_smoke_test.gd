extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, label: String) -> void:
	if not condition:
		push_error("WORLD TEST FAILED: " + label)
		quit(1)

func _run_tests() -> void:
	var world := load("res://world_simulation.gd").new()
	root.add_child(world)
	await process_frame
	world.hunger = 10.0
	world.energy = 50.0
	world.inventory["snack"] = 1
	_check(world.consume("snack"), "snack can be consumed")
	_check(world.hunger > 30.0, "snack restores hunger")
	var old_affection: float = world.affection
	world.touch_response("head")
	_check(world.affection > old_affection, "touch grows affection")
	world.set_outfit("midnight_blue")
	world.set_nails(2, 3)
	_check(world.outfit_id == "midnight_blue", "outfit selection persists in state")
	_check(world.nail_style == 2 and world.toe_style == 3, "nail styles update")
	var old_minutes: int = world.minutes
	world.rest(30)
	_check(world.minutes == posmod(old_minutes + 30, 1440), "rest advances in-game time")
	world.save_world()
	var clone := load("res://world_simulation.gd").new()
	root.add_child(clone)
	await process_frame
	_check(clone.outfit_id == "midnight_blue", "outfit survives save/load")
	_check(clone.nail_style == 2 and clone.toe_style == 3, "nail styles survive save/load")
	_check(clone.music_enabled == world.music_enabled, "music preference survives save/load")
	print("WORLD TESTS PASSED")
	quit(0)
