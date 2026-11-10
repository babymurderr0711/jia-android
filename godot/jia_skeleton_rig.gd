extends Node2D
class_name JiaSkeletonRig

# Procedural articulated fallback rig. The approved painted artwork will replace
# these vector surfaces once its hidden anatomy and cutout layers are integrated.
const SKIN := Color("#e99a83")
const HAIR := Color("#a83f2d")
const INK := Color("#21131e")
const CLOTH := Color("#24111f")

var skeleton: Skeleton2D
var bones: Dictionary = {}
var clock := 0.0
var pose := 0
var pose_blend_speed := 4.8
var gesture := "none"
var gesture_time := 0.0
var gesture_strength := 0.0
var secondary_motion := 0.0
var expression := "soft"
var manicure := 0
var pedicure := 0
var outfit_color := CLOTH
var wardrobe_style := 0
var outfit_surface: Polygon2D
var outfit_top_surface: Polygon2D
var nail_surfaces: Array[Polygon2D] = []
var eye_surfaces: Array[Polygon2D] = []
var cheek_surfaces: Array[Polygon2D] = []
var mouth_line: Line2D
var approved_art_sprite: Sprite2D
const NAIL_COLORS := [Color("#17121d"), Color("#e83e72"), Color("#f4c2d9"), Color("#9d1d45")]

func _ready() -> void:
	_build_skeleton()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	if gesture_time > 0.0:
		gesture_time = maxf(0.0, gesture_time - delta)
	gesture_strength = move_toward(gesture_strength, 1.0 if gesture_time > 0.0 else 0.0, delta * 2.8)
	secondary_motion = sin(clock * 1.7) * 0.025 + sin(clock * 0.83) * 0.012
	_animate_bones(delta)
	queue_redraw()

func set_pose(value: int) -> void:
	pose = posmod(value, 5)

func play_gesture(name: String, duration: float = 1.8) -> void:
	gesture = name
	gesture_time = maxf(0.25, duration)

func _gesture_offset(bone_name: String) -> float:
	var amount := gesture_strength
	match gesture:
		"wave":
			if bone_name == "Shoulder_R": return -0.72 * amount
			if bone_name == "Elbow_R": return -0.9 * amount + sin(clock * 12.0) * 0.16 * amount
			if bone_name == "Wrist_R": return sin(clock * 12.0) * 0.48 * amount
		"reach":
			if bone_name == "Shoulder_R": return -0.42 * amount
			if bone_name == "Elbow_R": return -0.55 * amount
		"shy":
			if bone_name == "Head": return -0.16 * amount
			if bone_name == "Shoulder_L": return 0.24 * amount
			if bone_name == "Shoulder_R": return -0.24 * amount
		"rest":
			if bone_name == "Head": return 0.08 * amount
	return 0.0

func set_appearance(outfit: Color, hands: int, feet: int, face: String, outfit_style: int = 0) -> void:
	outfit_color = outfit
	manicure = posmod(hands, 4)
	pedicure = posmod(feet, 4)
	expression = face
	wardrobe_style = posmod(outfit_style, 4)
	if is_instance_valid(outfit_surface):
		outfit_surface.color = outfit_color
		outfit_surface.polygon = _garment_shape()
	if is_instance_valid(outfit_top_surface):
		outfit_top_surface.color = outfit_color
		outfit_top_surface.polygon = _top_shape()
	for i in range(nail_surfaces.size()):
		nail_surfaces[i].color = NAIL_COLORS[manicure if i < 10 else pedicure]
	_update_face()

func _build_skeleton() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	var root := _bone("Root", skeleton, Vector2.ZERO)
	var pelvis := _bone("Pelvis", root, Vector2(0, 125))
	var torso := _bone("Torso", pelvis, Vector2(0, -105))
	var neck := _bone("Neck", torso, Vector2(0, -100))
	var head := _bone("Head", neck, Vector2(0, -35))
	_bone("Hair", head, Vector2.ZERO)
	var l_shoulder := _bone("Shoulder_L", torso, Vector2(-48, -65))
	var l_elbow := _bone("Elbow_L", l_shoulder, Vector2(-54, 70))
	_bone("Wrist_L", l_elbow, Vector2(-35, 75))
	var r_shoulder := _bone("Shoulder_R", torso, Vector2(48, -65))
	var r_elbow := _bone("Elbow_R", r_shoulder, Vector2(54, 70))
	_bone("Wrist_R", r_elbow, Vector2(35, 75))
	var l_hip := _bone("Hip_L", pelvis, Vector2(-35, 20))
	var l_knee := _bone("Knee_L", l_hip, Vector2(-28, 115))
	_bone("Ankle_L", l_knee, Vector2(-12, 105))
	var r_hip := _bone("Hip_R", pelvis, Vector2(35, 20))
	var r_knee := _bone("Knee_R", r_hip, Vector2(28, 115))
	_bone("Ankle_R", r_knee, Vector2(12, 105))
	_add_surface(torso, PackedVector2Array([Vector2(-52,-10),Vector2(52,-10),Vector2(68,112),Vector2(42,145),Vector2(-42,145),Vector2(-68,112)]), SKIN)
	outfit_top_surface = Polygon2D.new()
	outfit_top_surface.polygon = _top_shape()
	outfit_top_surface.color = outfit_color
	torso.add_child(outfit_top_surface)
	outfit_surface = Polygon2D.new()
	outfit_surface.polygon = _garment_shape()
	outfit_surface.color = outfit_color
	pelvis.add_child(outfit_surface)
	_add_surface(neck, PackedVector2Array([Vector2(-16,-8),Vector2(16,-8),Vector2(16,30),Vector2(-16,30)]), SKIN)
	_add_surface(head, _ellipse(Vector2.ZERO, Vector2(48,58)), SKIN)
	_add_surface(head.get_node("Hair") as Bone2D, _ellipse(Vector2(0,-31),Vector2(51,29)), HAIR)
	var fringe := Polygon2D.new()
	fringe.polygon = PackedVector2Array([Vector2(-44,-38),Vector2(-25,-56),Vector2(-4,-40),Vector2(8,-58),Vector2(32,-35),Vector2(42,-18),Vector2(8,-22),Vector2(-12,-12),Vector2(-35,-20)])
	fringe.color = Color("#c65a3b")
	head.add_child(fringe)
	for x in [-17.0, 17.0]:
		var brow := Line2D.new()
		brow.points = PackedVector2Array([Vector2(x-7,-17),Vector2(x,-20),Vector2(x+7,-17)])
		brow.width = 3.0
		brow.default_color = Color("#5a2a28")
		head.add_child(brow)
	for i in range(5):
		var freckle := Polygon2D.new()
		freckle.polygon = _ellipse(Vector2(-24.0 + float(i)*12.0,14.0 + float(i%2)*4.0),Vector2(1.5,1.5))
		freckle.color = Color("#a85c4d")
		head.add_child(freckle)
	for pair in [[l_shoulder,l_elbow],[l_elbow,l_elbow.get_node("Wrist_L")],[r_shoulder,r_elbow],[r_elbow,r_elbow.get_node("Wrist_R")]]:
		_add_bone_capsule(pair[0], pair[1], 18.0, SKIN)
	for pair in [[l_hip,l_knee],[l_knee,l_knee.get_node("Ankle_L")],[r_hip,r_knee],[r_knee,r_knee.get_node("Ankle_R")]]:
		_add_bone_capsule(pair[0], pair[1], 25.0, SKIN)
	_add_face(head)
	_add_hand_shape(bones["Wrist_L"])
	_add_hand_shape(bones["Wrist_R"])
	_add_foot_shape(bones["Ankle_L"])
	_add_foot_shape(bones["Ankle_R"])
	_add_nails(bones["Wrist_L"])
	_add_nails(bones["Wrist_R"])
	_add_nails(bones["Ankle_L"], true)
	_add_nails(bones["Ankle_R"], true)
	# Set explicit rest poses and lengths before Skeleton2D enters the scene tree.
	# Leaf bones receive a minimal display length; all joint lengths follow their child.
	for bone_name in bones:
		var current: Bone2D = bones[bone_name]
		current.set_autocalculate_length_and_angle(false)
		var child_bone: Bone2D
		for child in current.get_children():
			if child is Bone2D:
				child_bone = child
				break
		if child_bone != null:
			current.set_length(child_bone.position.length())
			current.set_bone_angle(child_bone.position.angle())
		else:
			current.set_length(1.0)
		current.rest = current.transform

	add_child(skeleton)
	_install_art_cutouts()


func _install_art_cutouts() -> void:
	# Keep the live Bone2D hierarchy, replacing only the temporary vector artwork.
	for node in skeleton.find_children("*", "Polygon2D", true, false):
		(node as CanvasItem).visible = false
	for node in skeleton.find_children("*", "Line2D", true, false):
		(node as CanvasItem).visible = false
	var origins: Dictionary = {
		"Head": Vector2(0,-115),
		"Torso": Vector2(0,20),
		"Shoulder_L": Vector2(-48,-45),
		"Elbow_L": Vector2(-102,25),
		"Wrist_L": Vector2(-137,100),
		"Shoulder_R": Vector2(48,-45),
		"Elbow_R": Vector2(102,25),
		"Wrist_R": Vector2(137,100),
		"Hip_L": Vector2(-35,145),
		"Hip_R": Vector2(35,145),
		"Knee_L": Vector2(-63,260),
		"Knee_R": Vector2(63,260),
		"Ankle_L": Vector2(-75,365),
		"Ankle_R": Vector2(75,365)
	}
	var pieces: Array[Dictionary] = [
		{"name":"head","bone":"Head","pivot":Vector2(180,220)},
		{"name":"torso","bone":"Torso","pivot":Vector2(180,260)},
		{"name":"upper_arm_l","bone":"Shoulder_L","pivot":Vector2(80,250)},
		{"name":"forearm_l","bone":"Elbow_L","pivot":Vector2(50,420)},
		{"name":"upper_arm_r","bone":"Shoulder_R","pivot":Vector2(290,250)},
		{"name":"forearm_r","bone":"Elbow_R","pivot":Vector2(330,420)},
		{"name":"thigh_l","bone":"Hip_L","pivot":Vector2(125,520)},
		{"name":"thigh_r","bone":"Hip_R","pivot":Vector2(245,520)},
		{"name":"shin_l","bone":"Knee_L","pivot":Vector2(125,820)},
		{"name":"shin_r","bone":"Knee_R","pivot":Vector2(245,820)},
		{"name":"foot_l","bone":"Ankle_L","pivot":Vector2(125,1190)},
		{"name":"foot_r","bone":"Ankle_R","pivot":Vector2(245,1190)}
	]
	for piece in pieces:
		var texture := load("res://assets/jia_%s.png" % piece.name) as Texture2D
		if texture == null:
			push_warning("Missing Jia cutout: %s" % piece.name)
			continue
		var bone_name: String = piece.bone
		var pivot: Vector2 = piece.pivot
		var root_point := Vector2(-79.8,-160.0) + pivot * 0.42
		var sprite := Sprite2D.new()
		sprite.name = "JiaArt_%s" % piece.name
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = -pivot
		sprite.position = (root_point - origins[bone_name]) / 0.42
		sprite.scale = Vector2(0.42,0.42)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 30
		(bones[bone_name] as Bone2D).add_child(sprite)


func _bone(bone_name: String, parent: Node, offset: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = offset
	bone.rest = bone.transform
	parent.add_child(bone)
	bones[bone_name] = bone
	return bone

func _top_shape() -> PackedVector2Array:
	match wardrobe_style:
		1:
			return PackedVector2Array([Vector2(-51,4),Vector2(-38,-5),Vector2(0,16),Vector2(38,-5),Vector2(51,4),Vector2(42,92),Vector2(0,78),Vector2(-42,92)])
		2:
			return PackedVector2Array([Vector2(-51,0),Vector2(-38,-6),Vector2(0,12),Vector2(38,-6),Vector2(51,0),Vector2(50,112),Vector2(-50,112)])
		3:
			return PackedVector2Array([Vector2(-51,0),Vector2(-38,-6),Vector2(0,12),Vector2(38,-6),Vector2(51,0),Vector2(58,145),Vector2(-58,145)])
		_:
			return PackedVector2Array([Vector2(-51,4),Vector2(-38,-5),Vector2(0,16),Vector2(38,-5),Vector2(51,4),Vector2(42,80),Vector2(0,66),Vector2(-42,80)])

func _garment_shape() -> PackedVector2Array:
	match wardrobe_style:
		1:
			return PackedVector2Array([Vector2(-48,0),Vector2(48,0),Vector2(58,84),Vector2(0,95),Vector2(-58,84)])
		2:
			return PackedVector2Array([Vector2(-48,0),Vector2(48,0),Vector2(52,62),Vector2(0,72),Vector2(-52,62)])
		3:
			return PackedVector2Array([Vector2(-48,0),Vector2(48,0),Vector2(68,110),Vector2(0,125),Vector2(-68,110)])
		_:
			return PackedVector2Array([Vector2(-48,0),Vector2(48,0),Vector2(58,72),Vector2(-58,72)])

func _add_surface(parent: Node, points: PackedVector2Array, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)

func _add_bone_capsule(parent: Bone2D, child: Bone2D, width: float, color: Color) -> void:
	var length := child.position.length()
	var direction := child.position.normalized()
	var normal := Vector2(-direction.y, direction.x) * width
	var points := PackedVector2Array([normal, child.position + normal, child.position - normal, -normal])
	_add_surface(parent, points, color)
	var outline := Line2D.new()
	outline.points = PackedVector2Array([normal, child.position + normal, child.position - normal, -normal])
	outline.width = 3.0
	outline.default_color = INK
	parent.add_child(outline)

func _add_face(head: Bone2D) -> void:
	for x in [-17.0, 17.0]:
		var eye := Polygon2D.new()
		eye.polygon = _ellipse(Vector2(x,-4),Vector2(5,8))
		eye.color = Color("#6a7549")
		head.add_child(eye)
		eye_surfaces.append(eye)
		var brow := Line2D.new()
		brow.points = PackedVector2Array([Vector2(x-7,-17),Vector2(x,-20),Vector2(x+7,-17)])
		brow.width = 3.0
		brow.default_color = Color("#5a2a28")
		head.add_child(brow)
	for x in [-1.0, 1.0]:
		var cheek := Polygon2D.new()
		cheek.polygon = _ellipse(Vector2(x * 30.0,15.0),Vector2(8,4))
		cheek.color = Color("#e77c83",0.0)
		head.add_child(cheek)
		cheek_surfaces.append(cheek)
	mouth_line = Line2D.new()
	mouth_line.points = PackedVector2Array([Vector2(-8,22),Vector2(0,26),Vector2(8,22)])
	mouth_line.width = 2.5
	mouth_line.default_color = Color("#8b3946")
	head.add_child(mouth_line)
	_update_face()

func _update_face() -> void:
	var blink_wave := absf(sin(clock * 0.73 + 0.35))
	var blink := 1.0 - smoothstep(0.965, 0.995, blink_wave)
	for i in range(eye_surfaces.size()):
		var x := -17.0 if i == 0 else 17.0
		var eye_height := 2.0 if expression == "sleepy" else lerpf(8.0, 0.7, blink)
		eye_surfaces[i].polygon = _ellipse(Vector2(x,-4),Vector2(5,eye_height))
	for cheek in cheek_surfaces:
		cheek.color = Color("#e77c83",0.48 if expression == "shy" else 0.0)
	if is_instance_valid(mouth_line):
		match expression:
			"surprised":
				mouth_line.points = PackedVector2Array([Vector2(-4,22),Vector2(0,26),Vector2(4,22)])
				mouth_line.width = 4.0
			"sleepy":
				mouth_line.points = PackedVector2Array([Vector2(-6,25),Vector2(0,25),Vector2(6,25)])
				mouth_line.width = 2.0
			"shy":
				mouth_line.points = PackedVector2Array([Vector2(-8,23),Vector2(0,28),Vector2(8,23)])
				mouth_line.width = 3.0
			_:
				mouth_line.points = PackedVector2Array([Vector2(-8,22),Vector2(0,26),Vector2(8,22)])
				mouth_line.width = 2.5

func _add_hand_shape(parent: Bone2D) -> void:
	_add_surface(parent, _ellipse(Vector2(0,14),Vector2(13,16)), SKIN)
	var lengths := [19.0, 26.0, 29.0, 25.0, 18.0]
	for i in range(5):
		var x := -11.0 + float(i) * 5.5
		var length: float = lengths[i]
		var finger := PackedVector2Array([Vector2(x-2,20),Vector2(x+2,20),Vector2(x+2,length+20),Vector2(x-2,length+20)])
		_add_surface(parent, finger, SKIN)
	_add_surface(parent, PackedVector2Array([Vector2(-10,12),Vector2(-15,8),Vector2(-22,19),Vector2(-18,23)]), SKIN)

func _add_foot_shape(parent: Bone2D) -> void:
	_add_surface(parent, _ellipse(Vector2(14,12),Vector2(31,13)), SKIN)
	_add_surface(parent, PackedVector2Array([Vector2(-3,5),Vector2(15,2),Vector2(34,7),Vector2(37,15),Vector2(13,22),Vector2(-4,17)]), SKIN)

func _add_nails(parent: Bone2D, toes: bool = false) -> void:
	var count := 5
	for i in range(count):
		var nail := Polygon2D.new()
		var x := float(i - 2) * (5.0 if toes else 5.5)
		var y := 7.0 if toes else 43.0
		nail.polygon = _ellipse(Vector2(x, y), Vector2(2.2, 3.8) if toes else Vector2(2.8, 4.8))
		nail.color = NAIL_COLORS[pedicure if toes else manicure]
		parent.add_child(nail)
		nail_surfaces.append(nail)

func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	return points

func _animate_bones(delta: float) -> void:
	_update_face()
	var breath := sin(clock * 1.55)
	var idle_sway := sin(clock * 0.72)
	var pose_targets := [
		{"Root":0.0,"Torso":-0.04,"Head":0.0,"Shoulder_L":-0.18,"Shoulder_R":0.18,"Elbow_L":-0.12,"Elbow_R":0.12,"Hip_L":-0.58,"Hip_R":0.58,"Knee_L":1.05,"Knee_R":-1.05},
		{"Root":0.0,"Torso":0.0,"Head":0.0,"Shoulder_L":-0.28,"Shoulder_R":0.28,"Elbow_L":0.08,"Elbow_R":-0.08,"Hip_L":0.0,"Hip_R":0.0,"Knee_L":0.0,"Knee_R":0.0},
		{"Root":0.0,"Torso":-0.08,"Head":0.03,"Shoulder_L":-0.48,"Shoulder_R":0.48,"Elbow_L":0.25,"Elbow_R":-0.25,"Hip_L":-1.05,"Hip_R":1.05,"Knee_L":1.45,"Knee_R":-1.45},
		{"Root":1.35,"Torso":0.08,"Head":-0.04,"Shoulder_L":0.5,"Shoulder_R":-0.5,"Elbow_L":0.35,"Elbow_R":-0.35,"Hip_L":0.25,"Hip_R":-0.25,"Knee_L":0.45,"Knee_R":-0.45},
		{"Root":0.0,"Torso":0.0,"Head":PI,"Shoulder_L":0.15,"Shoulder_R":-0.15,"Elbow_L":0.0,"Elbow_R":0.0,"Hip_L":-0.08,"Hip_R":0.08,"Knee_L":0.0,"Knee_R":0.0}
	]
	var targets: Dictionary = pose_targets[pose]
	for key in targets:
		var target: float = targets[key]
		if key == "Torso":
			target += breath * 0.018 + secondary_motion
		elif key == "Head":
			target += idle_sway * 0.025
		elif key == "Shoulder_L":
			target += sin(clock * 1.1) * 0.025
		elif key == "Shoulder_R":
			target -= sin(clock * 1.1 + 0.4) * 0.025
		target += _gesture_offset(str(key))
		var bone: Bone2D = bones[key]
		var blend := 1.0 - exp(-pose_blend_speed * delta)
		bone.rotation = lerp_angle(bone.rotation, target, blend)
