extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, label: String) -> void:
	if not condition:
		push_error("WORLD TEST FAILED: " + label)
		quit(1)

func _run_tests() -> void:
	var world: JiaWorldSimulation = load("res://world_simulation.gd").new() as JiaWorldSimulation
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
	_check(world.social_actions_today > 0, "social actions are tracked per day")
	_check(world.relationship_dialogue().size() >= 3, "relationship stage supplies dialogue variants")
	world.set_outfit("midnight_blue")
	world.set_nails(2, 3)
	_check(world.outfit_id == "midnight_blue", "outfit selection persists in state")
	_check(world.nail_style == 2 and world.toe_style == 3, "nail styles update")
	world.active_event = "tea_time"
	var old_coins: int = world.coins
	world.complete_event()
	_check(world.coins == old_coins + 5, "scheduled event grants its reward")
	_check(world.active_event.is_empty(), "scheduled event closes after completion")
	var old_minutes: int = world.minutes
	world.rest(30)
	_check(world.minutes == posmod(old_minutes + 30, 1440), "rest advances in-game time")
	world.save_world()
	var clone: JiaWorldSimulation = load("res://world_simulation.gd").new() as JiaWorldSimulation
	root.add_child(clone)
	await process_frame
	_check(clone.outfit_id == "midnight_blue", "outfit survives save/load")
	_check(clone.nail_style == 2 and clone.toe_style == 3, "nail styles survive save/load")
	_check(clone.relationship_dialogue().size() >= 3, "relationship dialogue remains available after load")
	_check(clone.music_enabled == world.music_enabled, "music preference survives save/load")
	var rig_scene: PackedScene = load("res://JiaSkeletonRig.tscn")
	var rig: JiaSkeletonRig = rig_scene.instantiate() as JiaSkeletonRig
	root.add_child(rig)
	await process_frame
	_check(rig.bones.size() >= 18, "skeleton contains full joint hierarchy")
	var art_sprites := rig.skeleton.find_children("JiaArt_*", "Sprite2D", true, false)
	_check(art_sprites.size() == 14, "all fourteen painted body cutouts attach to the rig")
	for sprite_node in art_sprites:
		var art_sprite := sprite_node as Sprite2D
		_check(art_sprite.texture != null, "painted cutout texture is loaded: " + art_sprite.name)
	_check((rig.bones["Shoulder_L"] as Bone2D).get_node_or_null("JiaArt_upper_arm_l") != null, "left upper arm follows shoulder bone")
	_check((rig.bones["Elbow_L"] as Bone2D).get_node_or_null("JiaArt_forearm_l") != null, "left forearm follows elbow bone")
	_check((rig.bones["Elbow_R"] as Bone2D).get_node_or_null("JiaArt_forearm_r") != null, "right forearm follows elbow bone")
	_check((rig.bones["Wrist_L"] as Bone2D).get_node_or_null("JiaArt_hand_l") != null, "left hand follows wrist bone")
	_check((rig.bones["Wrist_R"] as Bone2D).get_node_or_null("JiaArt_hand_r") != null, "right hand follows wrist bone")
	_check((rig.bones["Knee_L"] as Bone2D).get_node_or_null("JiaArt_shin_l") != null, "left shin follows knee bone")
	_check((rig.bones["Ankle_R"] as Bone2D).get_node_or_null("JiaArt_foot_r") != null, "right foot follows ankle bone")
	rig.set_pose(3)
	rig.set_appearance(Color("#5b1c38"), 2, 3, "shy", 1)
	await process_frame
	_check(rig.pose == 3, "skeleton accepts a pose transition")
	_check(absf((rig.bones["Root"] as Bone2D).rotation) > 0.001, "pose animates the root bone")
	rig.play_gesture("wave", 2.0)
	await create_timer(0.5).timeout
	_check(absf((rig.bones["Wrist_R"] as Bone2D).rotation) > 0.01, "wave gesture articulates the wrist bone")
	rig.play_gesture("nod", 1.0)
	await create_timer(0.25).timeout
	_check(absf((rig.bones["Head"] as Bone2D).rotation) < 0.5, "head nod stays within anatomical limits")
	rig.set_pose(4)
	await create_timer(0.35).timeout
	_check(absf((rig.bones["Head"] as Bone2D).rotation) < 0.5, "rear-view placeholder does not invert the head")
	_check(absf((rig.bones["Hair"] as Bone2D).rotation) < 0.15, "hair secondary motion remains subtle")
	for bone_name in rig.bones:
		var bone := rig.bones[bone_name] as Bone2D
		_check(is_finite(bone.rotation), "bone rotation remains finite: " + str(bone_name))
	print("WORLD AND RIG TESTS PASSED")
	quit(0)
