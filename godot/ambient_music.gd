extends AudioStreamPlayer
class_name JiaAmbientMusic

var enabled := true
var volume_level := 0.35
var sample_cursor := 0
var song_time := 0.0
const SAMPLE_RATE := 22050.0
const CHORDS := [
	[130.81, 164.81, 196.00],
	[110.00, 146.83, 174.61],
	[123.47, 155.56, 185.00],
	[98.00, 130.81, 164.81]
]

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 1.0
	stream = generator
	volume_db = linear_to_db(volume_level)
	play()

func set_enabled(value: bool) -> void:
	enabled = value
	volume_db = linear_to_db(volume_level) if enabled else -80.0

func set_volume(value: float) -> void:
	volume_level = clampf(value, 0.0, 0.8)
	if enabled:
		volume_db = linear_to_db(maxf(0.001, volume_level))

func _process(delta: float) -> void:
	song_time += delta
	var playback := get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := playback.get_frames_available()
	for i in range(frames):
		var seconds := float(sample_cursor) / SAMPLE_RATE
		var chord_index := int(song_time / 8.0) % CHORDS.size()
		var chord: Array = CHORDS[chord_index]
		var fade := minf(1.0, seconds / 2.0)
		var wave := 0.0
		for note in chord:
			var frequency := float(note)
			wave += sin(TAU * frequency * seconds) * 0.33
			wave += sin(TAU * frequency * 2.0 * seconds) * 0.08
		var pulse := 0.75 + 0.25 * sin(TAU * song_time / 8.0)
		var sample := wave * 0.012 * fade * pulse
		playback.push_frame(Vector2(sample, sample))
		sample_cursor += 1
