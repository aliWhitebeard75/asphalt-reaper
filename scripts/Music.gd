extends Node
# Procedural background music — pure synthesis, no audio files needed.
# Each environment group has its own melody, tempo, and harmony.

const MIX_RATE: float = 11025.0   # halved from 22050 — cuts synthesis CPU cost 50%

# ── Theme definitions ─────────────────────────────────────────────────────────
# root: base Hz, bpm: tempo, seq: array of semitone offsets (melody sequence)
const THEMES: Array = [
	# 0 City — minor-funk driving groove
	{"root": 110.0, "bpm": 132, "seq": [0, 7, 3, 10, 7, 0, 5, 3, 12, 7, 5, 0]},
	# 1 Desert — sparse pentatonic, laid-back
	{"root": 98.0,  "bpm": 88,  "seq": [0, 0, 5, 5, 7, 3, 7, 0, 5, 0]},
	# 2 Ice — slow ethereal major
	{"root": 130.8, "bpm": 72,  "seq": [12, 9, 7, 9, 4, 0, 4, 7, 9, 12, 7, 4]},
	# 3 Fire/Volcano — aggressive phrygian
	{"root": 92.5,  "bpm": 168, "seq": [0, 1, 5, 7, 8, 7, 5, 1, 0, 0, 5, 8]},
	# 4 Cyber/Neon — electronic arpeggio
	{"root": 116.5, "bpm": 175, "seq": [0, 7, 12, 15, 7, 3, 10, 12, 7, 3, 15, 10]},
	# 5 Space/Void — slow ambient drift
	{"root": 87.3,  "bpm": 60,  "seq": [0, 0, 12, 12, 7, 19, 7, 12, 0, 7, 19, 0]},
]

# Map each of the 25 environments (+ main-menu slot 25) to a theme
const ENV_TO_THEME: Array = [
	0, 1, 4, 2, 3, 5, 0, 1, 4, 5,   # envs 0-9
	4, 3, 2, 1, 2, 0, 4, 3, 5, 0,   # envs 10-19
	3, 4, 5, 0, 5,                    # envs 20-24
	4,                                # 25 = main menu (cyber theme)
]

# ── State ─────────────────────────────────────────────────────────────────────
var _player: AudioStreamPlayer = null
var _pb:     AudioStreamGeneratorPlayback = null

var music_volume: float = 0.7   # 0.0 – 1.0; set via set_volume()
var _theme:      int   = 0
var _si:         int   = 0      # absolute sample counter (for wave phase)
var _seq_pos:    int   = 0      # position in note sequence
var _freq:       float = 110.0  # current note frequency (Hz)
var _note_start: int   = 0
var _note_end:   int   = 0

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Sync volume from saved settings
	music_volume = GameState.music_volume

	_player = AudioStreamPlayer.new()
	add_child(_player)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate     = MIX_RATE
	gen.buffer_length = 0.25
	_player.stream   = gen
	_player.volume_db = _to_db(music_volume)
	_player.play()
	# get_stream_playback() may return null if the player hasn't processed a
	# frame yet — _process() will re-acquire it automatically in that case
	_pb = _player.get_stream_playback()
	_advance_note()

# ── Public API ────────────────────────────────────────────────────────────────
func set_environment(env_idx: int) -> void:
	var new_theme: int = int(ENV_TO_THEME[clampi(env_idx, 0, ENV_TO_THEME.size() - 1)])
	if new_theme == _theme:
		return
	_theme   = new_theme
	_seq_pos = 0
	_advance_note()

func set_menu_theme() -> void:
	set_environment(25)          # index 25 = main-menu slot

func set_volume(vol: float) -> void:
	music_volume = clamp(vol, 0.0, 1.0)
	if _player:
		_player.volume_db = _to_db(music_volume)

# ── Internal ──────────────────────────────────────────────────────────────────
func _to_db(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))

func _advance_note() -> void:
	var th: Dictionary  = THEMES[_theme]
	var seq: Array      = th["seq"]
	var st: int         = int(seq[_seq_pos % seq.size()])
	_freq               = float(th["root"]) * pow(2.0, st / 12.0)
	var bsamp: int      = int(MIX_RATE * 60.0 / float(th["bpm"]))
	_note_start         = _si
	_note_end           = _si + bsamp
	_seq_pos            = (_seq_pos + 1) % seq.size()

func _process(_delta: float) -> void:
	# Re-acquire playback handle if it wasn't available in _ready()
	if not _pb and _player and _player.playing:
		_pb = _player.get_stream_playback()
	if not _pb:
		return
	# Cap per-frame work: never fill more than ~46 ms worth of audio in one call
	# (prevents a single spike when the buffer runs dry on slow Android audio drivers)
	var frames: int = mini(_pb.get_frames_available(), int(MIX_RATE * 0.046))
	for _i in frames:
		if _si >= _note_end:
			_advance_note()
		var s: float = _synth()
		_pb.push_frame(Vector2(s, s))
		_si += 1

func _synth() -> float:
	var t: float   = float(_si) / MIX_RATE
	# Melody + bass octave + fifth overtone
	var s: float   = sin(TAU * _freq * t) * 0.45
	s             += sin(TAU * _freq * 0.5 * t) * 0.22
	s             += sin(TAU * _freq * 1.5 * t) * 0.10
	# Per-note envelope: fast attack, soft decay before note end
	var dur: float = float(_note_end - _note_start) / MIX_RATE
	var pos: float = float(_si - _note_start) / MIX_RATE
	var atk: float = clampf(pos * 30.0, 0.0, 1.0)
	var rel: float = clampf((dur - pos) * 7.0, 0.0, 1.0)
	return s * atk * rel * 0.55 * music_volume
