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
var expression := "soft"
var manicure := 0
var pedicure := 0
var outfit_color := CLOTH

func _ready() -> void:
	_build_skeleton()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	_animate_bones()
	queue_redraw()

func set_pose(value: int) -> void:
	pose = posmod(value, 5)

func set_appearance(outfit: Color, hands: int, feet: int, face: String) -> void:
	outfit_color = outfit
	manicure = posmod(hands, 4)
	pedicure = posmod(feet, 4)
	expression = face

func _build_skeleton() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	add_child(skeleton)
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
	_add_surface(pelvis, PackedVector2Array([Vector2(-48,0),Vector2(48,0),Vector2(58,72),Vector2(-58,72)]), outfit_color)
	_add_surface(neck, PackedVector2Array([Vector2(-16,-8),Vector2(16,-8),Vector2(16,30),Vector2(-16,30)]), SKIN)
	_add_surface(head, _ellipse(Vector2.ZERO, Vector2(48,58)), SKIN)
	_add_surface(head.get_node("Hair") as Bone2D, _ellipse(Vector2(0,-31),Vector2(51,29)), HAIR)
	for pair in [[l_shoulder,l_elbow],[l_elbow,l_elbow.get_node("Wrist_L")],[r_shoulder,r_elbow],[r_elbow,r_elbow.get_node("Wrist_R")]]:
		_add_bone_capsule(pair[0], pair[1], 18.0, SKIN)
	for pair in [[l_hip,l_knee],[l_knee,l_knee.get_node("Ankle_L")],[r_hip,r_knee],[r_knee,r_knee.get_node("Ankle_R")]]:
		_add_bone_capsule(pair[0], pair[1], 25.0, SKIN)
	_add_face(head)

func _bone(bone_name: String, parent: Node, offset: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = offset
	parent.add_child(bone)
	bones[bone_name] = bone
	return bone

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
	var mouth := Line2D.new()
	mouth.points = PackedVector2Array([Vector2(-8,22),Vector2(0,26),Vector2(8,22)])
	mouth.width = 2.5
	mouth.default_color = Color("#8b3946")
	head.add_child(mouth)

func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	return points

func _animate_bones() -> void:
	var breath := sin(clock * 1.55)
	bones["Torso"].rotation = breath * 0.018
	bones["Head"].rotation = sin(clock * 0.8) * 0.035
	bones["Hair"].rotation = sin(clock * 1.2) * 0.025
	bones["Shoulder_L"].rotation = sin(clock * 1.1) * 0.045
	bones["Shoulder_R"].rotation = -sin(clock * 1.1 + 0.4) * 0.045
	bones["Elbow_L"].rotation = sin(clock * 0.9 + 0.7) * 0.035
	bones["Elbow_R"].rotation = -sin(clock * 0.9) * 0.035
	bones["Knee_L"].rotation = sin(clock * 0.65) * 0.018
	bones["Knee_R"].rotation = -sin(clock * 0.65 + 0.3) * 0.018
	var pose_rotations := [
		{"Shoulder_L":0.0,"Shoulder_R":0.0,"Hip_L":0.0,"Hip_R":0.0},
		{"Shoulder_L":-0.28,"Shoulder_R":0.28,"Hip_L":-0.10,"Hip_R":0.10},
		{"Shoulder_L":-0.48,"Shoulder_R":0.48,"Hip_L":0.18,"Hip_R":-0.18},
		{"Shoulder_L":0.55,"Shoulder_R":-0.55,"Hip_L":0.25,"Hip_R":-0.25},
		{"Shoulder_L":0.15,"Shoulder_R":-0.15,"Hip_L":-0.08,"Hip_R":0.08}
	]
	for key in pose_rotations[pose]:
		var target: float = pose_rotations[pose][key]
		var bone: Bone2D = bones[key]
		bone.rotation = lerpf(bone.rotation, target, 0.035)
