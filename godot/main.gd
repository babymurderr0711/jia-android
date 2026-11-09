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
var manicure := 0
var pedicure := 0
var action_text := "Привет, мой ♡ Ты пришёл?~"
var action_timer := 0.0
var blink := 0.0
var time_passed := 0.0
var selected_tab := "Дом"
var massage_progress := 0.0
var dragging := false
var drag_origin := Vector2.ZERO

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	blink = maxf(0.0, blink - delta)
	if int(time_passed) % 5 == 0 and fposmod(time_passed, 5.0) < delta:
		blink = 0.16
	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			action_text = "Мне нравится, когда ты рядом ♡"
	if massage_progress > 0:
		massage_progress = maxf(0.0, massage_progress - delta * 0.08)
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
	var bob := sin(time_passed * 2.2) * 3.0
	var p: Vector2 = Vector2(350, 675) + pose_offsets[pose_index] + Vector2(0, bob)
	var sway := sin(time_passed * 1.1) * 7.0
	# pose-dependent silhouette; articulated limbs and joints are redrawn every frame
	if pose_index == 1:
		_draw_limb(p + Vector2(-35, 40), p + Vector2(-95, 185), 25)
		_draw_limb(p + Vector2(35, 40), p + Vector2(95, 185), 25)
		_draw_limb(p + Vector2(-30, 185), p + Vector2(-40, 365), 34)
		_draw_limb(p + Vector2(30, 185), p + Vector2(40, 365), 34)
	elif pose_index == 2:
		_draw_limb(p + Vector2(-35, 50), p + Vector2(-150, 180), 30)
		_draw_limb(p + Vector2(35, 50), p + Vector2(150, 180), 30)
		_draw_limb(p + Vector2(-25, 190), p + Vector2(-150, 250), 42)
		_draw_limb(p + Vector2(25, 190), p + Vector2(150, 250), 42)
	else:
		_draw_limb(p + Vector2(-45, 115), p + Vector2(-155, 275), 42)
		_draw_limb(p + Vector2(45, 115), p + Vector2(155, 275), 42)
		_draw_limb(p + Vector2(-90, 250), p + Vector2(-15, 375), 54)
		_draw_limb(p + Vector2(90, 250), p + Vector2(15, 375), 54)
	# torso
	var body := PackedVector2Array([p + Vector2(-75, 30), p + Vector2(75, 30), p + Vector2(105, 210), p + Vector2(60, 285), p + Vector2(-60, 285), p + Vector2(-105, 210)])
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
	# fringe
	draw_colored_polygon(PackedVector2Array([p + Vector2(-55, -60), p + Vector2(-8, -90), p + Vector2(5, -38), p + Vector2(35, -78), p + Vector2(58, -22), p + Vector2(15, -8), p + Vector2(-30, -12)]), Color("#c65a3b"))
	# eyes, freckles, mouth
	if blink > 0:
		draw_line(p + Vector2(-43, -5), p + Vector2(-12, -5), INK, 5)
		draw_line(p + Vector2(15, -5), p + Vector2(45, -5), INK, 5)
	else:
		_draw_ellipse(p + Vector2(-28, -4), Vector2(18, 10), Color("#f3d3b9"))
		draw_ellipse(p + Vector2(28, -4), Vector2(18, 10), Color("#f3d3b9"))
		draw_circle(p + Vector2(-25, -4), 6, Color("#6a7549"))
		draw_circle(p + Vector2(30, -4), 6, Color("#6a7549"))
		draw_circle(p + Vector2(-25, -4), 3, INK)
		draw_circle(p + Vector2(30, -4), 3, INK)
	for i in range(5):
		draw_circle(p + Vector2(-35 + i * 13, 17 + (i % 2) * 5), 2, Color("#a85c4d"))
	draw_arc(p + Vector2(0, 29), 12, 0.2, PI - 0.2, 16, Color("#8b3946"), 4)
	# hands and manicure details
	_draw_hand(p + Vector2(-155, 275), manicure)
	_draw_hand(p + Vector2(155, 275), manicure)
	# feet and pedicure accents
	_draw_foot(p + Vector2(-15, 375), pedicure)
	_draw_foot(p + Vector2(15, 375), pedicure)
	# floating heart / reaction
	draw_string(ThemeDB.fallback_font, p + Vector2(135, -105 + sin(time_passed * 2) * 5), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, PINK)

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
	draw_ellipse(pos, Vector2(28, 13), SKIN)
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
	draw_string(ThemeDB.fallback_font, Vector2(495, 63), "22:47 ☾", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, PALE)
	draw_string(ThemeDB.fallback_font, Vector2(495, 96), "Пн, 10 ноября", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, PALE)
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
	var nav := ["Поза", "Ногти", "Педикюр", "Массаж"]
	for i in range(4):
		_button(Rect2(18 + i * 176, 890, 164, 76), nav[i])
	draw_string(ThemeDB.fallback_font, Vector2(540, 1225), "Монеты: " + str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PALE)

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
		massage_progress = clampf(massage_progress + event.relative.length() / 450.0, 0.0, 1.0)
		mood = minf(100.0, mood + 0.03)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		massage_progress = clampf(massage_progress + event.relative.length() / 450.0, 0.0, 1.0)

func _to_design(pos: Vector2) -> Vector2:
	var s := get_viewport_rect().size
	var scale := minf(s.x / 720.0, s.y / 1280.0)
	return (pos - Vector2((s.x - 720.0 * scale) * 0.5, (s.y - 1280.0 * scale) * 0.5)) / scale

func _handle_tap(pos: Vector2) -> void:
	if pos.y > 890 and pos.y < 980:
		var idx := clampi(int(pos.x / 176.0), 0, 3)
		match idx:
			0: _next_pose()
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
	elif pos.x > 250 and pos.y < 300:
		_greet()

func _next_pose() -> void:
	pose_index = (pose_index + 1) % pose_names.size()
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
	massage_progress = 0.1
	action_text = "Проведи пальцем, чтобы сделать массаж ♡"
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
	_react(2.0)

func _react(amount: float) -> void:
	mood = minf(100.0, mood + amount)
	closeness = minf(100.0, closeness + 0.5)
	action_timer = 5.0
	queue_redraw()
