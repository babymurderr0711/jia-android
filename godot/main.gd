extends Node2D

# Jia's Place — playable Godot prototype.
# Character is drawn from articulated body parts so pose and appearance
# changes update the same live model instead of swapping static portraits.

const BG := Color("#241827")
const WALL := Color("#392438")
const PINK := Color("#f18abd")
const PALE := Color("#ffd0e7")
const INK := Color("#170f1b")
const SKIN := Color("#e99a83")
const HAIR := Color("#a83f2d")
const DARK := Color("#21131e")

var mood := 78.0
var closeness := 64.0
var energy := 82.0
var coins := 100
var pose_index := 0
var pose_names := ["На коленях", "Стоя", "Сидя", "Отдыхает", "Со спины"]
var pose_offsets := [Vector2(0, 0), Vector2(0, -90), Vector2(0, 45), Vector2(0, 90), Vector2(0, 0)]
var pose_offset_current := Vector2.ZERO
var pose_offset_from := Vector2.ZERO
var pose_offset_to := Vector2.ZERO
var pose_blend := 1.0
var expression := "soft"
var expression_timer := 0.0
var manicure := 0
var pedicure := 0
var action_text := "Привет, мой ♡ Ты пришёл?~"
var action_timer := 0.0
var blink := 0.0
var blink_cooldown := 2.4
var time_passed := 0.0
var reaction := 0.0
var selected_tab := "Дом"
var massage_progress := 0.0
var dragging := false
var drag_origin := Vector2.ZERO
var pose_editor := false
var arm_pose := 0.0
var leg_pose := 0.0
var interaction_target := "none"
var interaction_pulse := 0.0
var hand_reach := 0.0
var joint_sway := 0.0
var save_clock := 0.0
var game_minutes := 1367
var game_clock_fraction := 0.0
var elapsed_game_seconds := 0.0

func _ready() -> void:
	_load_game()
	JiaWorld.event_started.connect(_on_world_event)
	_sync_world_state()
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()

func _save_game() -> void:
	var data := ConfigFile.new()
	data.set_value("player", "mood", mood)
	data.set_value("player", "closeness", closeness)
	data.set_value("player", "energy", energy)
	data.set_value("player", "coins", coins)
	data.set_value("player", "pose_index", pose_index)
	data.set_value("player", "manicure", manicure)
	data.set_value("player", "pedicure", pedicure)
	data.set_value("world", "game_minutes", game_minutes)
	data.save("user://jia_place_save.cfg")

func _load_game() -> void:
	var data := ConfigFile.new()
	if data.load("user://jia_place_save.cfg") != OK:
		return
	mood = float(data.get_value("player", "mood", mood))
	closeness = float(data.get_value("player", "closeness", closeness))
	energy = float(data.get_value("player", "energy", energy))
	coins = int(data.get_value("player", "coins", coins))
	pose_index = int(data.get_value("player", "pose_index", pose_index)) % pose_names.size()
	manicure = int(data.get_value("player", "manicure", manicure)) % 4
	pedicure = int(data.get_value("player", "pedicure", pedicure)) % 4
	game_minutes = int(data.get_value("world", "game_minutes", game_minutes))

func _process(delta: float) -> void:
	time_passed += delta
	_sync_world_state()
	elapsed_game_seconds += delta
	game_clock_fraction += delta * 2.0
	var minute_ticks := int(game_clock_fraction)
	if minute_ticks > 0:
		game_minutes = (game_minutes + minute_ticks) % 1440
		game_clock_fraction -= float(minute_ticks)
	save_clock += delta
	if save_clock >= 12.0:
		save_clock = 0.0
		_save_game()
	blink = maxf(0.0, blink - delta)
	blink_cooldown -= delta
	if blink_cooldown <= 0.0:
		blink = 0.18
		blink_cooldown = 2.8 + 1.7 * absf(sin(time_passed * 0.73))
	reaction = maxf(0.0, reaction - delta)
	if pose_blend < 1.0:
		pose_blend = minf(1.0, pose_blend + delta / 0.55)
		var eased := pose_blend * pose_blend * (3.0 - 2.0 * pose_blend)
		pose_offset_current = pose_offset_from.lerp(pose_offset_to, eased)
	if expression_timer > 0.0:
		expression_timer -= delta
		if expression_timer <= 0.0:
			expression = "soft"
	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			action_text = "Мне нравится, когда ты рядом ♡"
	if massage_progress > 0:
		massage_progress = maxf(0.0, massage_progress - delta * 0.035)
	interaction_pulse = maxf(0.0, interaction_pulse - delta)
	joint_sway = sin(time_passed * 1.35) * 0.035
	hand_reach = lerpf(hand_reach, 1.0 if dragging else 0.0, minf(1.0, delta * 5.0))
	queue_redraw()

func _draw() -> void:
	var s := get_viewport_rect().size
	var scale := minf(s.x / 720.0, s.y / 1280.0)
	draw_set_transform(Vector2((s.x - 720.0 * scale) * 0.5, (s.y - 1280.0 * scale) * 0.5), 0.0, Vector2.ONE * scale)
	_draw_room()
	_draw_character()
	_draw_ui()

func _draw_room() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), BG)
	draw_rect(Rect2(0, 0, 720, 800), WALL)
	# pixel-art window and night city
	draw_rect(Rect2(18, 140, 170, 390), INK)
	for i in range(5):
		for j in range(7):
			if (i * 3 + j) % 4 != 0:
				draw_rect(Rect2(30 + i * 30, 160 + j * 48, 10, 20), Color("#ffb16f"))
	draw_rect(Rect2(0, 790, 720, 490), Color("#392538"))
	for y in range(820, 1280, 34):
		draw_line(Vector2(0, y), Vector2(720, y), Color("#56364d"), 2)
	for x in range(0, 720, 55):
		draw_line(Vector2(x, 800), Vector2(x + 80, 1280), Color("#4b3045"), 2)
	# bed and pillows
	draw_rect(Rect2(85, 825, 570, 340), Color("#493044"))
	draw_rect(Rect2(105, 835, 540, 70), Color("#6b405e"))
	draw_rect(Rect2(105, 920, 540, 245), Color("#58394f"))
	# wall poster
	draw_rect(Rect2(520, 180, 150, 220), Color("#1b1420"))
	draw_rect(Rect2(530, 190, 130, 200), Color("#362037"))
	draw_string(ThemeDB.fallback_font, Vector2(545, 260), "GOOD", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(545, 292), "GIRL", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(570, 345), "♡", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, PINK)
	# bedside table
	draw_rect(Rect2(535, 650, 150, 155), Color("#5c3a50"))
	draw_rect(Rect2(525, 640, 170, 20), Color("#a75b85"))
	draw_circle(Vector2(610, 610), 28, PALE)
	draw_circle(Vector2(600, 602), 5, PINK)
	draw_circle(Vector2(620, 602), 5, PINK)

func _draw_character() -> void:
	var breath := sin(time_passed * 1.65)
	var bob := sin(time_passed * 2.2) * 2.5
	var p: Vector2 = Vector2(350, 675) + pose_offset_current + Vector2(0, bob)
	var sway := sin(time_passed * 0.9) * 5.0
	var arm_swing := sin(time_passed * 1.45) * 7.0
	var head_float := sin(time_passed * 1.25 + 0.5) * 2.2
	p.y += head_float
	# Joint-driven limbs: shoulder -> elbow -> wrist and hip -> knee -> ankle.
	# Each segment is solved separately so elbows and knees bend instead of stretching.
	var left_shoulder := p + Vector2(-45, 115)
	var right_shoulder := p + Vector2(45, 115)
	var left_elbow := p + Vector2(-95 + sin(time_passed * 1.45) * 5.0, 195 + arm_pose * 24.0)
	var right_elbow := p + Vector2(95 - arm_swing * 0.45, 195 - arm_pose * 18.0)
	var left_wrist := p + Vector2(-155 + arm_swing + hand_reach * 38.0, 275 + arm_swing * 0.35 - hand_reach * 28.0)
	var right_wrist := p + Vector2(155 - arm_swing, 275 - arm_swing * 0.35)
	if pose_index == 1:
		left_elbow = p + Vector2(-78, 175)
		right_elbow = p + Vector2(78, 175)
		left_wrist = p + Vector2(-105, 270)
		right_wrist = p + Vector2(105, 270)
	elif pose_index == 2 or pose_index == 3:
		left_elbow = p + Vector2(-115, 175)
		right_elbow = p + Vector2(115, 175)
		left_wrist = p + Vector2(-150, 220)
		right_wrist = p + Vector2(150, 220)
	_draw_limb(left_shoulder, left_elbow, 34)
	_draw_limb(left_elbow, left_wrist, 27)
	_draw_limb(right_shoulder, right_elbow, 34)
	_draw_limb(right_elbow, right_wrist, 27)
	# Legs are split at the knees; the pose editor changes the knee bend.
	var left_hip := p + Vector2(-55, 250)
	var right_hip := p + Vector2(55, 250)
	var left_knee := p + Vector2(-90 + leg_pose * 28.0, 315)
	var right_knee := p + Vector2(90 - leg_pose * 28.0, 315)
	var left_ankle := p + Vector2(-15, 375)
	var right_ankle := p + Vector2(15, 375)
	_draw_limb(left_hip, left_knee, 48)
	_draw_limb(left_knee, left_ankle, 43)
	_draw_limb(right_hip, right_knee, 48)
	_draw_limb(right_knee, right_ankle, 43)
	# torso
	var body := PackedVector2Array([p + Vector2(-75, 30), p + Vector2(75, 30), p + Vector2(105, 210 + breath * 2.0), p + Vector2(60, 285 + breath * 1.5), p + Vector2(-60, 285 + breath * 1.5), p + Vector2(-105, 210 + breath * 2.0)])
	draw_colored_polygon(body, SKIN)
	draw_polyline(body, INK, 7, true)
	# dark lace top
	draw_colored_polygon(PackedVector2Array([p + Vector2(-68, 65), p + Vector2(68, 65), p + Vector2(55, 175), p + Vector2(0, 150), p + Vector2(-55, 175)]), Color("#24111f"))
	draw_line(p + Vector2(-55, 70), p + Vector2(-90, 0), INK, 6)
	draw_line(p + Vector2(55, 70), p + Vector2(90, 0), INK, 6)
	# neck and face
	draw_rect(Rect2(p.x - 30, p.y - 35, 60, 65), SKIN)
	draw_circle(p, 83, SKIN)
	draw_arc(p, 83, 0, TAU, 48, Color("#b85f59"), 3)
	# hair cap and side locks
	draw_colored_polygon(PackedVector2Array([p + Vector2(-78, -15), p + Vector2(-65, -90), p + Vector2(-15, -115), p + Vector2(48, -95), p + Vector2(82, -25), p + Vector2(72, 45), p + Vector2(55, 15), p + Vector2(-55, 18)]), HAIR)
	draw_polyline(PackedVector2Array([p + Vector2(-78, -15), p + Vector2(-65, -90), p + Vector2(-15, -115), p + Vector2(48, -95), p + Vector2(82, -25)]), INK, 7, true)
	# fringe and softly swaying side locks
	var fringe_shift := sin(time_passed * 1.05) * 2.5
	draw_colored_polygon(PackedVector2Array([p + Vector2(-55, -60), p + Vector2(-8, -90), p + Vector2(5 + fringe_shift, -38), p + Vector2(35 + fringe_shift, -78), p + Vector2(58, -22), p + Vector2(15, -8), p + Vector2(-30, -12)]), Color("#c65a3b"))
	draw_line(p + Vector2(-73, -5), p + Vector2(-78 + sway * 0.35, 66), HAIR, 15, true)
	draw_line(p + Vector2(72, -8), p + Vector2(78 + sway * 0.35, 62), HAIR, 15, true)
	# eyes, freckles, mouth
	if blink > 0 or expression == "sleepy":
		draw_line(p + Vector2(-43, -5), p + Vector2(-12, -5), INK, 5)
		draw_line(p + Vector2(15, -5), p + Vector2(45, -5), INK, 5)
		if expression == "sleepy":
			draw_arc(p + Vector2(-27, -9), 17, PI + 0.15, TAU - 0.15, 16, INK, 3)
			draw_arc(p + Vector2(28, -9), 17, PI + 0.15, TAU - 0.15, 16, INK, 3)
	else:
		_draw_ellipse(p + Vector2(-28, -4), Vector2(18, 10), Color("#f3d3b9"))
		_draw_ellipse(p + Vector2(28, -4), Vector2(18, 10), Color("#f3d3b9"))
		var gaze := Vector2(sin(time_passed * 0.42) * 2.0, sin(time_passed * 0.7) * 1.0)
		draw_circle(p + Vector2(-25, -4) + gaze, 6, Color("#6a7549"))
		draw_circle(p + Vector2(30, -4) + gaze, 6, Color("#6a7549"))
		draw_circle(p + Vector2(-25, -4) + gaze, 3, INK)
		draw_circle(p + Vector2(30, -4) + gaze, 3, INK)
	for i in range(5):
		draw_circle(p + Vector2(-35 + i * 13, 17 + (i % 2) * 5), 2, Color("#a85c4d"))
	if expression == "surprised":
		draw_circle(p + Vector2(0, 28), 7, Color("#8b3946"))
	elif expression == "shy":
		draw_arc(p + Vector2(0, 28), 10, 0.15, PI - 0.15, 18, Color("#8b3946"), 3)
	else:
		var smile := 13.0 + (5.0 if reaction > 0.0 or expression == "happy" else 0.0)
		draw_arc(p + Vector2(0, 27), smile, 0.15, PI - 0.15, 18, Color("#8b3946"), 4)
	if expression == "shy" or reaction > 0.0:
		draw_circle(p + Vector2(-52, 19), 7, Color("#e77c83", 0.42))
		draw_circle(p + Vector2(52, 19), 7, Color("#e77c83", 0.42))
	# hands and manicure details
	_draw_hand(left_wrist, manicure)
	_draw_hand(right_wrist, manicure)
	# feet and pedicure accents
	_draw_foot(left_ankle, pedicure)
	_draw_foot(right_ankle, pedicure)
	if interaction_target != "none":
		draw_arc(p + Vector2(0, 180), 92 + sin(time_passed * 7.0) * 5.0, 0.0, TAU, 48, Color("#ff9fc8", 0.8), 4.0)
	# floating heart / reaction
	var heart_y := -105 + sin(time_passed * 2.0) * 5.0
	if reaction > 0.0:
		heart_y -= 10.0 + sin(time_passed * 8.0) * 3.0
	draw_string(ThemeDB.fallback_font, p + Vector2(135, heart_y), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, PINK)

func _draw_limb(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, INK, width + 8, true)
	draw_line(a, b, SKIN, width, true)
	draw_circle(a, width * 0.5, SKIN)
	draw_circle(b, width * 0.5, SKIN)

func _draw_hand(pos: Vector2, style: int) -> void:
	draw_circle(pos, 17, SKIN)
	for i in range(4):
		var tip := pos + Vector2(-12 + i * 8, 22 + (i % 2) * 3)
		draw_line(pos + Vector2(-10 + i * 7, 5), tip, SKIN, 7, true)
		draw_line(tip - Vector2(0, 5), tip, [Color("#17121d"), Color("#e83e72"), Color("#f4c2d9"), Color("#9d1d45")][style], 4, true)

func _draw_foot(pos: Vector2, style: int) -> void:
	_draw_ellipse(pos, Vector2(28, 13), SKIN)
	for i in range(5):
		draw_circle(pos + Vector2(-18 + i * 8, -5 - (i % 2) * 2), 4, [Color("#17121d"), Color("#e83e72"), Color("#f4c2d9"), Color("#9d1d45")][style])

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)

func _draw_ui() -> void:
	# Header
	_panel(Rect2(18, 18, 405, 105))
	draw_string(ThemeDB.fallback_font, Vector2(42, 63), "Jia ♡", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(42, 101), "Lv. 1   ♥ " + str(int(closeness)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PALE)
	_panel(Rect2(475, 18, 225, 105))
	draw_string(ThemeDB.fallback_font, Vector2(495, 63), _clock_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(495, 96), _day_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, PALE)
	# dialogue
	_panel(Rect2(22, 150, 340, 112), PALE)
	draw_string(ThemeDB.fallback_font, Vector2(42, 193), action_text.left(27), HORIZONTAL_ALIGNMENT_LEFT, 300, 23, INK)
	# right actions
	var labels := ["Позировать", "Массаж", "Красота", "Подарок"]
	for i in range(4):
		_button(Rect2(500, 400 + i * 92, 200, 72), labels[i])
	# stats
	_panel(Rect2(18, 1000, 280, 230))
	_draw_stat("☺ Настроение", mood, 1040)
	_draw_stat("♥ Близость", closeness, 1105)
	_draw_stat("★ Энергия", energy, 1170)
	# bottom nav
	var nav := ["Редактор", "Ногти", "Педикюр", "Массаж"]
	for i in range(4):
		_button(Rect2(18 + i * 176, 890, 164, 76), nav[i])
	if pose_editor:
		_panel(Rect2(390, 170, 300, 190))
		draw_string(ThemeDB.fallback_font, Vector2(410, 205), "Редактор поз", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, PALE)
		_button(Rect2(405, 220, 125, 52), "Руки −")
		_button(Rect2(550, 220, 125, 52), "Руки +")
		_button(Rect2(405, 285, 125, 52), "Ноги −")
		_button(Rect2(550, 285, 125, 52), "Ноги +")
	if interaction_target != "none":
		_panel(Rect2(315, 1040, 380, 115))
		draw_string(ThemeDB.fallback_font, Vector2(338, 1080), "Массаж: " + str(int(massage_progress * 100.0)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, PALE)
		draw_rect(Rect2(338, 1095, 330, 18), INK)
		draw_rect(Rect2(338, 1095, 330 * massage_progress, 18), PINK)
	draw_string(ThemeDB.fallback_font, Vector2(540, 1225), "Монеты: " + str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PALE)

func _clock_label() -> String:
	var hour := int(JiaWorld.minutes / 60)
	var minute := JiaWorld.minutes % 60
	return "%02d:%02d ☾" % [hour, minute]

func _day_label() -> String:
	var day_number := 1 + int(elapsed_game_seconds / 900.0)
	return "День %d · Jia's Place" % JiaWorld.day

func _panel(r: Rect2, fill: Color = Color("#281827")) -> void:
	draw_rect(r, INK)
	draw_rect(r.grow(-5), Color("#9c557c"))
	draw_rect(r.grow(-9), fill)

func _button(r: Rect2, label: String) -> void:
	draw_rect(r, INK)
	draw_rect(r.grow(-4), Color("#a34c7d"))
	draw_rect(r.grow(-8), Color("#f18abd"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.position.y + 44), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 24, 21, INK)

func _draw_stat(label: String, value: float, y: float) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(35, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PALE)
	draw_rect(Rect2(35, y + 12, 235, 14), INK)
	draw_rect(Rect2(35, y + 12, 235.0 * value / 100.0, 14), PINK)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(_to_design(event.position))
	elif event is InputEventMouseButton and event.pressed:
		_handle_tap(_to_design(event.position))
	elif event is InputEventScreenDrag:
		dragging = true
		if interaction_target != "none":
			massage_progress = clampf(massage_progress + event.relative.length() / 700.0, 0.0, 1.0)
			interaction_pulse = 0.5
			mood = minf(100.0, mood + 0.03)
			if massage_progress >= 0.95:
				interaction_target = "none"
				dragging = false
				action_text = "Мне стало легче, спасибо ♡"
				_react(4.0)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and interaction_target != "none":
		massage_progress = clampf(massage_progress + event.relative.length() / 700.0, 0.0, 1.0)
		interaction_pulse = 0.5
		if massage_progress >= 0.95:
			interaction_target = "none"
			action_text = "Вот теперь совсем хорошо ♡"
			_react(4.0)

func _to_design(pos: Vector2) -> Vector2:
	var s := get_viewport_rect().size
	var scale := minf(s.x / 720.0, s.y / 1280.0)
	return (pos - Vector2((s.x - 720.0 * scale) * 0.5, (s.y - 1280.0 * scale) * 0.5)) / scale

func _handle_tap(pos: Vector2) -> void:
	if pos.y > 890 and pos.y < 980:
		var idx := clampi(int(pos.x / 176.0), 0, 3)
		match idx:
			0: pose_editor = not pose_editor
			1: _change_manicure()
			2: _change_pedicure()
			3: _start_massage()
	elif pos.x > 495 and pos.y >= 400 and pos.y < 768:
		var idx := int((pos.y - 400) / 92)
		match idx:
			0: _next_pose()
			1: _start_massage()
			2: _change_manicure()
			3: _gift()
	elif pose_editor and pos.x >= 390 and pos.y >= 215 and pos.y < 355:
		if pos.y < 280:
			arm_pose = clampf(arm_pose + (-0.15 if pos.x < 540 else 0.15), -1.0, 1.0)
		else:
			leg_pose = clampf(leg_pose + (-0.15 if pos.x < 540 else 0.15), -1.0, 1.0)
		action_text = "Подбираем положение суставов ♡"
	elif pos.x > 190 and pos.x < 490 and pos.y > 360 and pos.y < 850:
		_interact_with_jia()
	elif pos.x > 250 and pos.y < 300:
		_greet()

func _interact_with_jia() -> void:
	var response: Dictionary = JiaWorld.touch_response("body")
	action_text = str(response.line)
	expression = str(response.expression)
	if energy < 12.0:
		action_text = "Я немного устала… Давай отдохнём? ♡"
		expression = "sleepy"
		return
	energy = maxf(0.0, energy - 1.0)
	mood = minf(100.0, mood + 1.5)
	closeness = minf(100.0, closeness + 1.0)
	_sync_world_state()
	_react(1.5)

func _next_pose() -> void:
	pose_index = (pose_index + 1) % pose_names.size()
	pose_editor = false
	arm_pose = 0.0
	leg_pose = 0.0
	pose_offset_from = pose_offset_current
	pose_offset_to = pose_offsets[pose_index]
	pose_blend = 0.0
	expression = "happy"
	expression_timer = 2.0
	action_text = "Я устроилась: " + pose_names[pose_index] + " ♡"
	_react(2.0)

func _change_manicure() -> void:
	manicure = (manicure + 1) % 4
	action_text = ["Мне нравятся мои чёрные ноготки!", "Смотри, новый розовый маникюр ♡", "Нежный перламутр — красиво!", "Бордовый? Очень в моём стиле!"][manicure]
	_react(3.0)

func _change_pedicure() -> void:
	pedicure = (pedicure + 1) % 4
	action_text = "Посмотри, я обновила педикюр! ♡"
	_react(3.0)

func _start_massage() -> void:
	expression = "soft"
	expression_timer = 3.0
	massage_progress = 0.0
	interaction_target = "body"
	dragging = false
	action_text = "Проводи пальцем по контуру, чтобы сделать массаж ♡"
	energy = minf(100.0, energy + 1.0)
	mood = minf(100.0, mood + 4.0)
	closeness = minf(100.0, closeness + 1.0)

func _gift() -> void:
	if coins >= 20:
		coins -= 20
		mood = minf(100.0, mood + 10.0)
		closeness = minf(100.0, closeness + 5.0)
		action_text = "Ой, подарок для меня? Спасибо! ♡"
	else:
		action_text = "Давай накопим ещё монеток? ♡"

func _greet() -> void:
	action_text = "Я скучала! Расскажешь, как прошёл день? ♡"
	expression = "shy"
	expression_timer = 2.5
	_react(2.0)

func _react(amount: float) -> void:
	reaction = 2.2
	expression = "happy"
	expression_timer = 2.0
	mood = minf(100.0, mood + amount)
	closeness = minf(100.0, closeness + 0.5)
	action_timer = 5.0
	queue_redraw()

func _sync_world_state() -> void:
	mood = JiaWorld.mood
	closeness = JiaWorld.affection
	energy = JiaWorld.energy
	coins = JiaWorld.coins
	game_minutes = JiaWorld.minutes
	manicure = JiaWorld.nail_style % 4
	pedicure = JiaWorld.toe_style % 4

func _on_world_event(_event_id: String, title: String, line: String) -> void:
	action_text = title + ": " + line
	expression = "happy"
	expression_timer = 4.0
	action_timer = 8.0
	queue_redraw()
