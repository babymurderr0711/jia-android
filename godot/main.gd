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
var massage_selector_open := false
var massage_kind := ""
var massage_idle_clock := 0.0
var initiative_clock := 18.0
var massage_hand_position := Vector2(360, 610)
var massage_last_position := Vector2.ZERO
var interaction_pulse := 0.0
var hand_reach := 0.0
var joint_sway := 0.0
var save_clock := 0.0
var game_minutes := 1367
var game_clock_fraction := 0.0
var elapsed_game_seconds := 0.0
var outfit_index := 0
var rhythm_active := false
var rhythm_score := 0
var rhythm_attempts := 0
var rhythm_window := 0.0
var rhythm_phase_timer := 0.0
var rhythm_target_visible := false
var rhythm_target := Vector2(360, 520)
var rhythm_cooldown := 0.0
var pending_touch_zone := "body"
@onready var character_rig: JiaSkeletonRig = $CharacterRig
@onready var ambient_music: JiaAmbientMusic = $AmbientMusic
var settings_open := false
var shop_open := false
var dialogue_index := 0
var touch_cooldown := 0.0
const DIALOGUE_LINES := [
	"Как прошёл твой день? Я внимательно слушаю ♡",
	"Мне нравится, когда мы проводим время вместе",
	"Сегодня хочется немного помечтать и выпить чаю",
	"Расскажи, что тебя сейчас радует больше всего?",
	"Спасибо, что возвращаешься ко мне. Это важно ♡",
	"Давай выберем что-нибудь приятное на вечер"
]

func _ready() -> void:
	_load_game()
	var outfit_ids := ["home_black", "burgundy_lace", "midnight_blue", "warm_satin"]
	outfit_index = maxi(0, outfit_ids.find(JiaWorld.outfit_id))
	JiaWorld.event_started.connect(_on_world_event)
	_sync_world_state()
	ambient_music.set_enabled(JiaWorld.music_enabled)
	ambient_music.set_volume(JiaWorld.music_volume)
	ambient_music.sfx_enabled = JiaWorld.sfx_enabled
	character_rig.set_pose(pose_index)
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()
		JiaWorld.save_world()

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
	elapsed_game_seconds += delta
	if not rhythm_active:
		_sync_world_state()
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
	touch_cooldown = maxf(0.0, touch_cooldown - delta)
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
	initiative_clock -= delta
	if initiative_clock <= 0.0 and not shop_open and not settings_open and not massage_selector_open and interaction_target == "none" and not rhythm_active:
		initiative_clock = randf_range(24.0, 42.0)
		_initiative_action()
	if rhythm_active:
		rhythm_window -= delta
		rhythm_cooldown -= delta
		rhythm_phase_timer -= delta
		if rhythm_target_visible and rhythm_phase_timer <= 0.0:
			rhythm_attempts += 1
			rhythm_target_visible = false
			rhythm_phase_timer = 0.45
		elif not rhythm_target_visible and rhythm_phase_timer <= 0.0 and rhythm_attempts < 8:
			rhythm_target_visible = true
			rhythm_phase_timer = 0.85
			rhythm_target = Vector2(405.0 + randf_range(-85.0, 85.0), 505.0 + randf_range(-65.0, 65.0))
		if rhythm_attempts >= 8 or rhythm_window <= 0.0:
			rhythm_active = false
			rhythm_target_visible = false
			action_text = "Ритм завершён: %d из %d попаданий ♡" % [rhythm_score, rhythm_attempts]
			if rhythm_score >= 5:
				JiaWorld.mood = minf(100.0, JiaWorld.mood + 6.0)
				JiaWorld.affection = minf(100.0, JiaWorld.affection + 2.0)
				JiaWorld.coins += 10
			JiaWorld.save_world()
			_sync_world_state()
	interaction_pulse = maxf(0.0, interaction_pulse - delta)
	joint_sway = sin(time_passed * 1.35) * 0.035
	hand_reach = lerpf(hand_reach, 1.0 if dragging else 0.0, minf(1.0, delta * 5.0))
	queue_redraw()

func _draw() -> void:
	var s := get_viewport_rect().size
	var scale := minf(s.x / 720.0, s.y / 1280.0)
	draw_set_transform(Vector2((s.x - 720.0 * scale) * 0.5, (s.y - 1280.0 * scale) * 0.5), 0.0, Vector2.ONE * scale)
	_draw_room()
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

	# Warm, static bedroom dressing.
	draw_colored_polygon(PackedVector2Array([Vector2(18,140),Vector2(48,140),Vector2(48,540),Vector2(18,520)]), Color("#70405f"))
	draw_colored_polygon(PackedVector2Array([Vector2(158,140),Vector2(188,140),Vector2(188,520),Vector2(158,540)]), Color("#70405f"))
	draw_line(Vector2(48,150),Vector2(158,150),Color("#d18aaa"),5.0)
	draw_circle(Vector2(92,225),24,Color("#f6dfb0"))
	draw_circle(Vector2(101,216),22,INK)
	for star in [Vector2(58,190),Vector2(140,245),Vector2(65,330),Vector2(145,390)]:
		draw_line(star+Vector2(-5,0),star+Vector2(5,0),PALE,2.0)
		draw_line(star+Vector2(0,-5),star+Vector2(0,5),PALE,2.0)
	# Floating shelf and books.
	draw_rect(Rect2(510,445,165,12),Color("#9a5d78"))
	draw_rect(Rect2(525,405,22,40),Color("#d98ca8"))
	draw_rect(Rect2(551,416,18,29),Color("#c8a17d"))
	draw_rect(Rect2(574,395,26,50),Color("#6c718f"))
	draw_rect(Rect2(605,425,48,20),Color("#4a2d45"))
	# A potted plant beside the bed.
	draw_rect(Rect2(548,615,38,36),Color("#b87583"))
	draw_colored_polygon(PackedVector2Array([Vector2(567,615),Vector2(540,575),Vector2(555,586),Vector2(562,550),Vector2(575,585),Vector2(594,566),Vector2(580,615)]),Color("#78906a"))
	draw_line(Vector2(567,615),Vector2(562,566),Color("#48664c"),3.0)
	# Rug and floor lamp.
	draw_rect(Rect2(145,1160,430,75),Color("#75445f"))
	draw_rect(Rect2(160,1170,400,55),Color("#9a5b7d"))
	draw_line(Vector2(650,480),Vector2(650,720),Color("#b98b75"),7.0)
	draw_rect(Rect2(620,455,60,38),Color("#e8b9a2"))
	draw_circle(Vector2(650,494),8,Color("#f8d9a9"))

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
	var outfit_colors := [Color("#24111f"), Color("#5b1c38"), Color("#27344b"), Color("#6b4a35")]
	var outfit_color: Color = outfit_colors[outfit_index % outfit_colors.size()]
	draw_colored_polygon(PackedVector2Array([p + Vector2(-68, 65), p + Vector2(68, 65), p + Vector2(55, 175), p + Vector2(0, 150), p + Vector2(-55, 175)]), outfit_color)
	# Visible lower garment layer changes with the selected wardrobe set.
	var garment := PackedVector2Array()
	if outfit_index == 0:
		garment = PackedVector2Array([p + Vector2(-58, 205), p + Vector2(58, 205), p + Vector2(74, 270), p + Vector2(0, 292), p + Vector2(-74, 270)])
	elif outfit_index == 1:
		garment = PackedVector2Array([p + Vector2(-60, 205), p + Vector2(60, 205), p + Vector2(66, 260), p + Vector2(0, 278), p + Vector2(-66, 260)])
	elif outfit_index == 2:
		garment = PackedVector2Array([p + Vector2(-60, 205), p + Vector2(60, 205), p + Vector2(82, 250), p + Vector2(0, 268), p + Vector2(-82, 250)])
	else:
		garment = PackedVector2Array([p + Vector2(-68, 190), p + Vector2(68, 190), p + Vector2(76, 300), p + Vector2(0, 320), p + Vector2(-76, 300)])
	draw_colored_polygon(garment, outfit_color.darkened(0.12))
	draw_polyline(garment, INK, 4.0, true)
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
	draw_string(ThemeDB.fallback_font, Vector2(42, 101), "Ур. " + str(1 + int(closeness / 20.0)) + "   ♥ " + str(int(closeness)) + "% · " + JiaWorld.relationship_stage(), HORIZONTAL_ALIGNMENT_LEFT, 350, 16, PALE)
	_panel(Rect2(475, 18, 225, 105))
	draw_string(ThemeDB.fallback_font, Vector2(495, 63), _clock_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(495, 96), _day_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(656, 58), "⚙", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, PALE)
	# dialogue
	_panel(Rect2(22, 150, 340, 112), PALE)
	draw_string(ThemeDB.fallback_font, Vector2(42, 190), action_text.left(34), HORIZONTAL_ALIGNMENT_LEFT, 300, 20, INK)
	draw_string(ThemeDB.fallback_font, Vector2(42, 226), "JIA  ·  " + ("СОБЫТИЕ" if not JiaWorld.active_event.is_empty() else "ДОМА"), HORIZONTAL_ALIGNMENT_LEFT, 290, 13, Color("#9c557c"))
	# right actions
	var labels := ["Поза", "Массаж", "Чай", "Подарок", "Отдых"]
	for i in range(5):
		_button(Rect2(500, 380 + i * 88, 200, 68), labels[i])
	# stats
	_panel(Rect2(18, 980, 280, 250))
	_draw_stat("☺ Настроение", mood, 1018)
	_draw_stat("♥ Близость", closeness, 1062)
	_draw_stat("★ Энергия", energy, 1106)
	_draw_stat("🍓 Сытость", JiaWorld.hunger, 1150)
	_draw_stat("✧ Гигиена", JiaWorld.hygiene, 1194)
	# bottom nav
	var nav := ["Одежда", "Маникюр", "Педикюр", "Ритм ♡", "Магазин"]
	for i in range(5):
		_button(Rect2(18 + i * 140, 890, 130, 76), nav[i])
	if massage_selector_open:
		_panel(Rect2(325, 330, 375, 445))
		draw_string(ThemeDB.fallback_font, Vector2(350, 370), "Выбери массаж ♡", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, PALE)
		_button(Rect2(350, 390, 320, 64), "Стопы · мягкие круговые движения")
		_button(Rect2(350, 465, 320, 64), "Плечи и спина · разминание")
		_button(Rect2(350, 540, 320, 64), "Кисти рук · лёгкий массаж")
		_button(Rect2(350, 615, 320, 64), "Ноги · расслабляющие движения")
		_button(Rect2(350, 690, 320, 58), "Назад")
	if interaction_target != "none":
		_draw_massage_scene()
	if shop_open:
		_panel(Rect2(325, 285, 375, 475))
		draw_string(ThemeDB.fallback_font, Vector2(350, 330), "Маленький магазин ♡", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, PALE)
		draw_string(ThemeDB.fallback_font, Vector2(350, 365), "Чай %d · Перекус %d · Цветы %d" % [int(JiaWorld.inventory.get("tea", 0)), int(JiaWorld.inventory.get("snack", 0)), int(JiaWorld.inventory.get("gift_flower", 0))], HORIZONTAL_ALIGNMENT_LEFT, 340, 17, PALE)
		_button(Rect2(350, 395, 325, 58), "Забрать ежедневный бонус · +50")
		_button(Rect2(350, 465, 325, 58), "Купить чай · 8 монет")
		_button(Rect2(350, 535, 325, 58), "Купить перекус · 12 монет")
		_button(Rect2(350, 605, 325, 58), "Купить цветы · 30 монет")
		_button(Rect2(350, 675, 325, 58), "Закрыть магазин")
	if settings_open:
		_panel(Rect2(350, 350, 350, 390))
		draw_string(ThemeDB.fallback_font, Vector2(382, 398), "Настройки", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, PALE)
		_button(Rect2(380, 425, 290, 62), "Музыка: " + ("Вкл" if ambient_music.enabled else "Выкл"))
		_button(Rect2(380, 505, 135, 62), "Громкость −")
		_button(Rect2(535, 505, 135, 62), "Громкость +")
		draw_string(ThemeDB.fallback_font, Vector2(390, 602), "Уровень: %d%%" % int(ambient_music.volume_level * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PALE)
		_button(Rect2(380, 615, 290, 52), "Звуковые эффекты: " + ("Вкл" if ambient_music.sfx_enabled else "Выкл"))
		_button(Rect2(380, 685, 290, 42), "Закрыть")
	if pose_editor:
		_panel(Rect2(390, 170, 300, 190))
		draw_string(ThemeDB.fallback_font, Vector2(410, 205), "Редактор поз", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, PALE)
		_button(Rect2(405, 220, 125, 52), "Руки −")
		_button(Rect2(550, 220, 125, 52), "Руки +")
		_button(Rect2(405, 285, 125, 52), "Ноги −")
		_button(Rect2(550, 285, 125, 52), "Ноги +")
	if rhythm_active:
		_panel(Rect2(385, 170, 310, 190))
		draw_string(ThemeDB.fallback_font, Vector2(410, 205), "Поймай ритм: %d/8" % rhythm_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, PALE)
		draw_string(ThemeDB.fallback_font, Vector2(410, 240), "Попытка: %d/8" % mini(rhythm_attempts + 1, 8), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, PALE)
		if rhythm_target_visible:
			draw_circle(rhythm_target, 38, Color("#f18abd"))
			draw_circle(rhythm_target, 25, Color("#ffd0e7"))
			draw_string(ThemeDB.fallback_font, rhythm_target + Vector2(-10, 9), "♡", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, INK)
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
	# Layered frame gives every card a consistent dark, plum-and-rose visual hierarchy.
	draw_rect(r.grow(2.0), Color("#120d17"))
	draw_rect(r, Color("#59304d"))
	draw_rect(r.grow(-3.0), Color("#b56b91"))
	draw_rect(r.grow(-7.0), fill)
	draw_rect(Rect2(r.position.x + 12.0, r.position.y + 9.0, maxf(0.0, r.size.x - 24.0), 2.0), Color("#ffffff", 0.10))

func _button(r: Rect2, label: String) -> void:
	draw_rect(r.grow(2.0), Color("#130d17"))
	draw_rect(r, Color("#6b3657"))
	draw_rect(r.grow(-3.0), Color("#d77ca8"))
	draw_rect(r.grow(-7.0), Color("#f6b2d0"))
	# Scale long Russian labels down so they remain legible on narrow phone controls.
	var font_size := 20
	if label.length() > 20:
		font_size = 14
	elif label.length() > 14:
		font_size = 16
	elif label.length() > 10:
		font_size = 18
	var baseline := r.position.y + (r.size.y + float(font_size)) * 0.5 - 2.0
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8.0, baseline), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16.0, font_size, Color("#351b30"))

func _draw_stat(label: String, value: float, y: float) -> void:
	var amount := clampf(value, 0.0, 100.0)
	draw_string(ThemeDB.fallback_font, Vector2(35, y), label, HORIZONTAL_ALIGNMENT_LEFT, 190, 16, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(35, y), str(int(amount)) + "%", HORIZONTAL_ALIGNMENT_RIGHT, 235, 14, Color("#f6c2dc"))
	draw_rect(Rect2(35, y + 8, 235, 10), Color("#160f19"))
	draw_rect(Rect2(35, y + 8, 235.0 * amount / 100.0, 10), Color("#e887b5"))
	draw_rect(Rect2(35, y + 8, 235, 1), Color("#ffffff", 0.12))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(_to_design(event.position))
	elif event is InputEventMouseButton and event.pressed:
		_handle_tap(_to_design(event.position))
	elif event is InputEventScreenDrag:
		dragging = true
		if interaction_target != "none":
			var point := _to_design(event.position)
			massage_hand_position = point
			var distance: float = event.relative.length()
			massage_progress = clampf(massage_progress + distance / 950.0, 0.0, 1.0)
			interaction_pulse = 0.5
			JiaWorld.mood = minf(100.0, JiaWorld.mood + 0.025)
			if massage_progress >= 0.95:
				_finish_massage()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and interaction_target != "none":
		massage_hand_position = _to_design(event.position)
		massage_progress = clampf(massage_progress + event.relative.length() / 950.0, 0.0, 1.0)
		interaction_pulse = 0.5
		if massage_progress >= 0.95:
			_finish_massage()

func _to_design(pos: Vector2) -> Vector2:
	var s := get_viewport_rect().size
	var scale := minf(s.x / 720.0, s.y / 1280.0)
	return (pos - Vector2((s.x - 720.0 * scale) * 0.5, (s.y - 1280.0 * scale) * 0.5)) / scale

func _handle_tap(pos: Vector2) -> void:
	if pos.x >= 640 and pos.y >= 18 and pos.y <= 120:
		settings_open = not settings_open
		return
	if settings_open:
		if Rect2(380, 425, 290, 62).has_point(pos):
			ambient_music.set_enabled(not ambient_music.enabled)
			JiaWorld.music_enabled = ambient_music.enabled
			JiaWorld.save_world()
		elif Rect2(380, 505, 135, 62).has_point(pos):
			ambient_music.set_volume(ambient_music.volume_level - 0.1)
			JiaWorld.music_volume = ambient_music.volume_level
			JiaWorld.save_world()
		elif Rect2(535, 505, 135, 62).has_point(pos):
			ambient_music.set_volume(ambient_music.volume_level + 0.1)
			JiaWorld.music_volume = ambient_music.volume_level
			JiaWorld.save_world()
		elif Rect2(380, 615, 290, 52).has_point(pos):
			ambient_music.sfx_enabled = not ambient_music.sfx_enabled
			JiaWorld.sfx_enabled = ambient_music.sfx_enabled
			JiaWorld.save_world()
		elif Rect2(380, 685, 290, 42).has_point(pos):
			settings_open = false
		return
	if massage_selector_open:
		if Rect2(350, 390, 320, 64).has_point(pos):
			_begin_massage("feet")
		elif Rect2(350, 465, 320, 64).has_point(pos):
			_begin_massage("shoulders")
		elif Rect2(350, 540, 320, 64).has_point(pos):
			_begin_massage("hands")
		elif Rect2(350, 615, 320, 64).has_point(pos):
			_begin_massage("legs")
		elif Rect2(350, 690, 320, 58).has_point(pos):
			massage_selector_open = false
		queue_redraw()
		return
	if interaction_target != "none":
		if Rect2(520, 820, 175, 55).has_point(pos):
			interaction_target = "none"
			massage_progress = 0.0
			massage_kind = ""
			return
		return
	if shop_open:
		if Rect2(350, 395, 325, 58).has_point(pos):
			if JiaWorld.claim_daily_reward():
				action_text = "Ежедневный бонус получен: +50 монет, чай и перекус! ♡"
				_sync_world_state()
			else:
				action_text = "Сегодня бонус уже забран. Возвращайся завтра ♡"
		elif Rect2(350, 465, 325, 58).has_point(pos):
			_buy_item("tea")
		elif Rect2(350, 535, 325, 58).has_point(pos):
			_buy_item("snack")
		elif Rect2(350, 605, 325, 58).has_point(pos):
			_buy_item("gift_flower")
		elif Rect2(350, 675, 325, 58).has_point(pos):
			shop_open = false
		queue_redraw()
		return
	if pos.y > 890 and pos.y < 980:
		var idx := clampi(int((pos.x - 18.0) / 140.0), 0, 4)
		if idx == 4:
			shop_open = true
			queue_redraw()
			return
		match idx:
			0: _change_outfit()
			1: _change_manicure()
			2: _change_pedicure()
			3: _start_rhythm_game()
	elif pos.x > 495 and pos.y >= 380 and pos.y < 820:
		var idx := int((pos.y - 380) / 88)
		match idx:
			0: _next_pose()
			1: massage_selector_open = true
			2:
				if JiaWorld.consume("tea"):
					action_text = "Чай согрел меня. Спасибо ♡"
					_sync_world_state()
				else:
					action_text = "Чай закончился — нужно пополнить запасы"
			3: _gift()
			4: _rest()
	elif pose_editor and pos.x >= 390 and pos.y >= 215 and pos.y < 355:
		if pos.y < 280:
			arm_pose = clampf(arm_pose + (-0.15 if pos.x < 540 else 0.15), -1.0, 1.0)
		else:
			leg_pose = clampf(leg_pose + (-0.15 if pos.x < 540 else 0.15), -1.0, 1.0)
		action_text = "Подбираем положение суставов ♡"
	elif pos.x >= 18 and pos.x <= 298 and pos.y >= 1130 and pos.y < 1180:
		if JiaWorld.consume("snack"):
			action_text = "Перекусила — теперь больше сил ♡"
			_sync_world_state()
		else:
			action_text = "Перекусы закончились"
	elif pos.x >= 18 and pos.x <= 298 and pos.y >= 1180 and pos.y < 1235:
		JiaWorld.freshen_up()
		_sync_world_state()
		action_text = "Освежилась и чувствую себя лучше ♡"
	elif rhythm_active:
		if rhythm_target_visible:
			rhythm_attempts += 1
			rhythm_target_visible = false
			rhythm_phase_timer = 0.45
			if pos.distance_to(rhythm_target) <= 48.0:
				rhythm_score += 1
				action_text = "Точно в такт! ♡"
			else:
				action_text = "Чуть мимо — лови следующий удар"
	elif pos.x > 190 and pos.x < 490 and pos.y > 360 and pos.y < 850:
		if pos.y < 650:
			pending_touch_zone = "head"
		elif pos.x < 265 or pos.x > 435:
			pending_touch_zone = "hand"
		else:
			pending_touch_zone = "body"
		_interact_with_jia()
	elif pos.x >= 22 and pos.x <= 362 and pos.y >= 150 and pos.y <= 262:
		if not JiaWorld.active_event.is_empty():
			JiaWorld.complete_event()
			_sync_world_state()
			action_text = "Событие завершено! +5 монет ♡"
		else:
			_talk()
	elif pos.x > 250 and pos.y < 300:
		_greet()

func _interact_with_jia() -> void:
	if touch_cooldown > 0.0:
		return
	touch_cooldown = 0.55
	var response: Dictionary = JiaWorld.touch_response(pending_touch_zone)
	action_text = str(response.line)
	expression = str(response.expression)
	if energy < 12.0:
		action_text = "Я немного устала… Давай отдохнём? ♡"
		expression = "sleepy"
		return
	JiaWorld.energy = maxf(0.0, JiaWorld.energy - 1.0)
	JiaWorld.mood = minf(100.0, JiaWorld.mood + 1.5)
	JiaWorld.affection = minf(100.0, JiaWorld.affection + 1.0)
	_sync_world_state()
	_react(1.5)

func _next_pose() -> void:
	pose_index = (pose_index + 1) % pose_names.size()
	character_rig.set_pose(pose_index)
	character_rig.play_gesture("shy", 1.2)
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
	JiaWorld.set_nails(manicure, pedicure)
	action_text = ["Мне нравятся мои чёрные ноготки!", "Смотри, новый розовый маникюр ♡", "Нежный перламутр — красиво!", "Бордовый? Очень в моём стиле!"][manicure]
	_react(3.0)

func _change_pedicure() -> void:
	pedicure = (pedicure + 1) % 4
	JiaWorld.set_nails(manicure, pedicure)
	action_text = "Посмотри, я обновила педикюр! ♡"
	_react(3.0)

func _start_massage() -> void:
	massage_selector_open = true
	queue_redraw()

func _begin_massage(kind: String) -> void:
	massage_selector_open = false
	massage_kind = kind
	massage_progress = 0.0
	interaction_target = kind
	dragging = false
	massage_hand_position = Vector2(360, 610)
	massage_last_position = massage_hand_position
	character_rig.play_gesture("reach", 2.0)
	expression = "soft"
	expression_timer = 30.0
	var lines := {"feet":"Проводи пальцем по стопам мягкими кругами ♡","shoulders":"Веди пальцем вдоль плеч и спины ♡","hands":"Мягко проведи по кистям и пальцам ♡","legs":"Проводи вверх и вниз по ногам ♡"}
	action_text = lines[kind]
	queue_redraw()

func _finish_massage() -> void:
	interaction_target = "none"
	dragging = false
	JiaWorld.mood = minf(100.0, JiaWorld.mood + 9.0)
	JiaWorld.energy = minf(100.0, JiaWorld.energy + 5.0)
	JiaWorld.affection = minf(100.0, JiaWorld.affection + 3.0)
	JiaWorld.comfort = minf(100.0, JiaWorld.comfort + 12.0)
	massage_progress = 0.0
	character_rig.play_gesture("shy", 2.2)
	expression = "shy"
	expression_timer = 3.0
	action_text = "М-м… так хорошо. Спасибо за заботу ♡"
	_sync_world_state()
	JiaWorld.save_world()

func _initiative_action() -> void:
	var choices := ["talk", "wave", "sleepy", "shy", "nod", "look", "laugh"]
	match choices[randi() % choices.size()]:
		"talk":
			action_text = ["Эй, побудь со мной немного? ♡","Мне хочется рассказать тебе кое-что","Как ты там? Я слушаю"][randi() % 3]
			expression = "happy"
			character_rig.play_gesture("reach", 1.8)
		"wave":
			action_text = "Пс-с… привет ещё раз! ♡"
			expression = "shy"
			character_rig.play_gesture("wave", 2.0)
		"sleepy":
			action_text = "Немного зеваю… но рада, что ты здесь ♡"
			expression = "sleepy"
			character_rig.play_gesture("rest", 2.5)
		"shy":
			action_text = "Поймала твой взгляд и улыбнулась ♡"
			expression = "shy"
			character_rig.play_gesture("shy", 1.8)
		"nod":
			action_text = "Угу, я тебя внимательно слушаю ♡"
			expression = "happy"
			character_rig.play_gesture("nod", 1.2)
		"look":
			action_text = "На секунду задумалась и отвела взгляд…"
			expression = "soft"
			character_rig.play_gesture("look", 1.8)
		"laugh":
			action_text = "Хи-хи, ну ты меня рассмешил! ♡"
			expression = "happy"
			character_rig.play_gesture("laugh", 1.6)
	expression_timer = 3.5
	action_timer = 6.0
	queue_redraw()

func _draw_massage_scene() -> void:
	_panel(Rect2(28, 285, 455, 475))
	var title: String = str({"feet":"Массаж стоп","shoulders":"Массаж плеч и спины","hands":"Массаж рук","legs":"Массаж ног"}.get(massage_kind, "Массаж"))
	draw_string(ThemeDB.fallback_font, Vector2(52, 330), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(52, 366), "Веди пальцем по отмеченной области", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, PALE)
	var region := Rect2(90, 405, 320, 245)
	draw_rect(region, Color("#4b3048"), true, 18.0)
	var center := region.get_center()
	match massage_kind:
		"feet":
			_draw_ellipse(center + Vector2(-55, 0), Vector2(35, 82), SKIN)
			_draw_ellipse(center + Vector2(55, 0), Vector2(35, 82), SKIN)
		"shoulders":
			draw_circle(center + Vector2(0,-35), 34, SKIN)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-100,-30),center+Vector2(100,-30),center+Vector2(75,90),center+Vector2(-75,90)]), SKIN)
			draw_arc(center+Vector2(0,10), 90, PI, TAU, 32, PALE, 4.0)
		"hands":
			for side in [-1,1]:
				draw_line(center+Vector2(side*65,55),center+Vector2(side*65,-30),SKIN,24,true)
				for f in range(5): draw_line(center+Vector2(side*65+(f-2)*8,-25),center+Vector2(side*65+(f-2)*11,-90),SKIN,7,true)
		"legs":
			draw_line(center+Vector2(-55,-95),center+Vector2(-65,95),SKIN,36,true)
			draw_line(center+Vector2(55,-95),center+Vector2(65,95),SKIN,36,true)
	var hand := massage_hand_position + Vector2(sin(time_passed*8.0)*4.0, cos(time_passed*8.0)*4.0)
	draw_circle(hand, 17, Color("#f4c2d9"))
	draw_circle(hand, 8, PINK)
	draw_rect(Rect2(52, 680, 400, 16), Color("#241827"), true, 8.0)
	draw_rect(Rect2(52, 680, 400.0*massage_progress, 16), PINK, true, 8.0)
	_button(Rect2(520, 820, 175, 55), "Закончить")

func _buy_item(item_id: String) -> void:
	if JiaWorld.purchase_item(item_id):
		action_text = {"tea":"Чай пополнил запасы ♡","snack":"Перекус теперь в инвентаре!","gift_flower":"Цветы куплены — можно порадовать Джию ♡"}[item_id]
		_sync_world_state()
	else:
		action_text = "Пока не хватает монет на эту покупку"

func _gift() -> void:
	character_rig.play_gesture("shy", 1.8)
	if JiaWorld.consume("gift_flower"):
		_sync_world_state()
		action_text = "Ой, подарок для меня? Спасибо! ♡"
	else:
		action_text = "Цветы закончились. Заглянем в магазин позже? ♡"

func _greet() -> void:
	character_rig.play_gesture("wave", 2.2)
	action_text = "Я скучала! Расскажешь, как прошёл день? ♡"
	expression = "shy"
	expression_timer = 2.5
	_react(2.0)

func _react(amount: float) -> void:
	reaction = 2.2
	ambient_music.play_chime()
	expression = "happy"
	expression_timer = 2.0
	JiaWorld.mood = minf(100.0, JiaWorld.mood + amount)
	JiaWorld.affection = minf(100.0, JiaWorld.affection + 0.5)
	_sync_world_state()
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
	var wardrobe_colors := [Color("#24111f"), Color("#5b1c38"), Color("#27344b"), Color("#6b4a35")]
	character_rig.set_appearance(wardrobe_colors[outfit_index % wardrobe_colors.size()], manicure, pedicure, expression, outfit_index)

func _on_world_event(_event_id: String, title: String, line: String) -> void:
	action_text = title + ": " + line
	expression = "happy"
	expression_timer = 4.0
	action_timer = 8.0
	queue_redraw()

func _change_outfit() -> void:
	outfit_index = (outfit_index + 1) % 4
	var outfit_ids := ["home_black", "burgundy_lace", "midnight_blue", "warm_satin"]
	JiaWorld.set_outfit(outfit_ids[outfit_index])
	action_text = ["Чёрный домашний образ ♡", "Бордовый комплект — нравится?", "Тёмно-синий вечерний образ", "Мягкий тёплый оттенок"][outfit_index]
	_react(1.5)

func _start_rhythm_game() -> void:
	rhythm_active = true
	rhythm_score = 0
	rhythm_attempts = 0
	rhythm_window = 15.0
	rhythm_phase_timer = 0.85
	rhythm_target_visible = true
	rhythm_cooldown = 0.0
	rhythm_target = Vector2(410.0, 500.0)
	action_text = "Нажимай на сердечко, когда оно появляется! 12 секунд ♡"

func _talk() -> void:
	if closeness >= 85.0:
		action_text = ["Я чувствую, что могу тебе доверять ♡", "Останься ещё на минутку? Мне хорошо рядом", "Давай сегодня устроим наш маленький вечер"][dialogue_index % 3]
	elif closeness >= 60.0:
		action_text = ["Мне нравится, как мы сближаемся ♡", "Расскажи мне что-нибудь хорошее", "Может, выберем мне новый образ?"][dialogue_index % 3]
	else:
		action_text = DIALOGUE_LINES[dialogue_index % DIALOGUE_LINES.size()]
	dialogue_index += 1
	JiaWorld.affection = minf(100.0, JiaWorld.affection + 0.7)
	JiaWorld.mood = minf(100.0, JiaWorld.mood + 0.5)
	expression = "shy" if dialogue_index % 3 == 0 else "happy"
	expression_timer = 2.8
	_sync_world_state()
	_react(0.0)

func _rest() -> void:
	character_rig.play_gesture("rest", 2.5)
	JiaWorld.rest(120)
	_sync_world_state()
	expression = "sleepy"
	expression_timer = 4.0
	action_text = "Я немного отдохнула. Теперь снова полна сил ♡"
	_react(2.0)
