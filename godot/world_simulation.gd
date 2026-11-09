extends Node
class_name JiaWorldSimulation

signal minute_changed(minutes: int)
signal event_started(event_id: String, title: String, line: String)
signal need_changed(need: String, value: float)

const SAVE_PATH := "user://jia_world.cfg"
const DAY_MINUTES := 1440
const MIN_NEED := 0.0
const MAX_NEED := 100.0

var minutes := 8 * 60
var day := 1
var mood := 78.0
var energy := 82.0
var hunger := 76.0
var hygiene := 88.0
var comfort := 80.0
var affection := 64.0
var coins := 100
var outfit_id := "home_black"
var nail_style := 0
var toe_style := 0
var inventory: Dictionary = {"tea": 2, "snack": 3, "gift_flower": 1}
var completed_events: Array[String] = []
var active_event := ""
var _minute_accumulator := 0.0
var _autosave := 0.0

const EVENTS := [
	{"id":"morning_hello","from":420,"to":600,"title":"Доброе утро","line":"Я только проснулась. Посидишь со мной немного?","need":"social"},
	{"id":"tea_time","from":840,"to":1020,"title":"Время чая","line":"Я приготовила чай. Может, устроим небольшой перерыв?","need":"comfort"},
	{"id":"evening_chat","from":1080,"to":1320,"title":"Вечерний разговор","line":"День почти закончился. Расскажешь, как ты?","need":"social"}
]

func _ready() -> void:
	load_world()

func _process(delta: float) -> void:
	_minute_accumulator += delta * 2.0
	var ticks := int(_minute_accumulator)
	if ticks > 0:
		_minute_accumulator -= float(ticks)
		for _i in range(ticks):
			advance_minute()
	_autosave += delta
	if _autosave >= 20.0:
		_autosave = 0.0
		save_world()

func advance_minute() -> void:
	minutes += 1
	if minutes >= DAY_MINUTES:
		minutes = 0
		day += 1
	# Needs evolve slowly and depend on time of day.
	hunger = clampf(hunger - 0.012, MIN_NEED, MAX_NEED)
	energy = clampf(energy - (0.008 if minutes < 420 or minutes > 1320 else 0.003), MIN_NEED, MAX_NEED)
	hygiene = clampf(hygiene - 0.002, MIN_NEED, MAX_NEED)
	if hunger < 25.0:
		mood = clampf(mood - 0.008, 0.0, 100.0)
	if energy < 18.0:
		mood = clampf(mood - 0.012, 0.0, 100.0)
	minute_changed.emit(minutes)
	_check_schedule()

func _check_schedule() -> void:
	if not active_event.is_empty():
		return
	for event in EVENTS:
		if minutes >= int(event.from) and minutes < int(event.to):
			var event_id: String = event.id
			if not completed_events.has(event_id + "_" + str(day)):
				active_event = event_id
				event_started.emit(event_id, str(event.title), str(event.line))
				return

func complete_event() -> void:
	if active_event.is_empty():
		return
	completed_events.append(active_event + "_" + str(day))
	active_event = ""
	coins += 5
	save_world()

func consume(item_id: String) -> bool:
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	inventory[item_id] = int(inventory[item_id]) - 1
	match item_id:
		"tea":
			comfort = clampf(comfort + 18.0, 0.0, 100.0)
			mood = clampf(mood + 5.0, 0.0, 100.0)
		"snack":
			hunger = clampf(hunger + 25.0, 0.0, 100.0)
			energy = clampf(energy + 4.0, 0.0, 100.0)
		"gift_flower":
			affection = clampf(affection + 8.0, 0.0, 100.0)
			mood = clampf(mood + 12.0, 0.0, 100.0)
	need_changed.emit(item_id, float(inventory[item_id]))
	save_world()
	return true

func rest(duration_minutes: int = 120) -> void:
	energy = clampf(energy + float(duration_minutes) * 0.22, 0.0, 100.0)
	mood = clampf(mood + 8.0, 0.0, 100.0)
	hygiene = clampf(hygiene - 2.0, 0.0, 100.0)

func touch_response(zone: String) -> Dictionary:
	var result := {"line":"Мне приятно, что ты рядом ♡","expression":"happy","affection":1.0,"mood":1.0}
	match zone:
		"head":
			result = {"line":"*слегка наклоняет голову* Так нежно…","expression":"shy","affection":1.5,"mood":2.0}
		"hand":
			result = {"line":"Дай подержу твою руку ♡","expression":"soft","affection":1.2,"mood":1.0}
		"foot":
			result = {"line":"Хи-хи, щекотно!","expression":"surprised","affection":0.8,"mood":1.5}
		"body":
			result = {"line":"Я расслабилась. Спасибо ♡","expression":"happy","affection":1.0,"mood":2.0}
	affection = clampf(affection + float(result.affection), 0.0, 100.0)
	mood = clampf(mood + float(result.mood), 0.0, 100.0)
	energy = clampf(energy - 0.5, 0.0, 100.0)
	return result

func set_outfit(value: String) -> void:
	outfit_id = value
	save_world()

func set_nails(hands: int, feet: int) -> void:
	nail_style = posmod(hands, 6)
	toe_style = posmod(feet, 6)
	save_world()

func save_world() -> void:
	var cfg := ConfigFile.new()
	for key in ["minutes","day","mood","energy","hunger","hygiene","comfort","affection","coins","outfit_id","nail_style","toe_style","inventory","completed_events"]:
		cfg.set_value("world", key, get(key))
	cfg.save(SAVE_PATH)

func load_world() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in ["minutes","day","mood","energy","hunger","hygiene","comfort","affection","coins","outfit_id","nail_style","toe_style","inventory"]:
		if cfg.has_section_key("world", key):
			set(key, cfg.get_value("world", key))
	if cfg.has_section_key("world", "completed_events"):
		completed_events.clear()
		for event_id in cfg.get_value("world", "completed_events", []):
			completed_events.append(str(event_id))
	minutes = posmod(int(minutes), DAY_MINUTES)
	day = maxi(1, int(day))
