extends Node
# Procedural audio — all sounds synthesised from maths at startup.
# No .wav/.ogg files required.

const SR: int = 22050   # sample rate

var _s: Dictionary = {}   # pre-built AudioStreamWAV objects
var _shoot_cd: float = 0.0
var _kill_cd:  float = 0.0
var sfx_volume: float = 0.80  # 0.0 – 1.0; set by Settings

func _ready() -> void:
	sfx_volume = GameState.sfx_volume
	_s["click"]       = _gen(0.07,  _fn_click)
	_s["shoot"]       = _gen(0.06,  _fn_shoot)
	_s["coin"]        = _gen(0.10,  _fn_coin)
	_s["boost"]       = _gen(0.22,  _fn_boost)
	_s["perk"]        = _gen(0.30,  _fn_perk)
	_s["damage"]      = _gen(0.14,  _fn_damage)
	_s["kill"]        = _gen(0.16,  _fn_kill)
	_s["explode"]     = _gen(0.32,  _fn_explode)
	_s["parry"]       = _gen(0.22,  _fn_parry)
	_s["death"]       = _gen(0.80,  _fn_death)
	_s["boss"]        = _gen(0.50,  _fn_boss)

func _process(delta: float) -> void:
	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	_kill_cd  = maxf(0.0, _kill_cd  - delta)

# ── Public API ────────────────────────────────────────────────────────────────
func play_click()  -> void: _play("click",  -5.0)
func play_coin()   -> void: _play("coin",   -7.0)
func play_boost()  -> void: _play("boost",  -4.0)
func play_perk()   -> void: _play("perk",   -4.0)
func play_damage() -> void: _play("damage", -2.0)
func play_death()  -> void: _play("death",  -1.0)
func play_boss()   -> void: _play("boss",   -2.0)

func play_shoot() -> void:
	if _shoot_cd > 0.0: return
	_shoot_cd = 0.11
	_play("shoot", -9.0)

func play_kill() -> void:
	if _kill_cd > 0.0: return
	_kill_cd = 0.10
	_play("kill", -7.0)

func play_parry() -> void: _play("parry", -2.0)

func play_explode() -> void:
	if _kill_cd > 0.0: return
	_play("explode", -3.0)

# ── Internal ──────────────────────────────────────────────────────────────────
func _play(key: String, vol_db: float) -> void:
	if not _s.has(key):
		return
	var ap := AudioStreamPlayer.new()
	ap.stream     = _s[key]
	# Apply sfx volume: sfx_volume=1.0 → no change; 0.0 → mute
	var vol_offset := linear_to_db(maxf(sfx_volume, 0.0001))
	ap.volume_db  = vol_db + vol_offset
	ap.process_mode = Node.PROCESS_MODE_ALWAYS
	ap.autoplay   = true
	ap.finished.connect(ap.queue_free)
	get_tree().root.add_child(ap)

# ── WAV builder ───────────────────────────────────────────────────────────────
# fn receives (t: float, e: float) → float in range ≈ [-1, 1]
#   t = time in seconds   e = linear envelope 1→0
func _gen(dur: float, fn: Callable) -> AudioStreamWAV:
	var n   := int(SR * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: float = float(i) / SR
		var e: float = 1.0 - float(i) / float(n)
		var raw: float = fn.call(t, e)
		var v: int = clamp(int(raw * 32767.0), -32768, 32767)
		var u: int = v & 0xFFFF
		data[i * 2]     = u & 0xFF
		data[i * 2 + 1] = (u >> 8) & 0xFF
	var s := AudioStreamWAV.new()
	s.format   = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SR
	s.stereo   = false
	s.data     = data
	return s

# ── Synthesis functions ───────────────────────────────────────────────────────
func _fn_click(t: float, e: float)  -> float:
	return sin(TAU * 860.0 * t) * pow(e, 2.0) * 0.55

func _fn_shoot(t: float, e: float)  -> float:
	return sin(TAU * (340.0 + 110.0 * e) * t) * e * 0.42

func _fn_coin(t: float, e: float)   -> float:
	return sin(TAU * (1100.0 + 330.0 * e) * t) * pow(e, 1.5) * 0.52

func _fn_boost(t: float, e: float)  -> float:
	return sin(TAU * (200.0 + 500.0 * (1.0 - e)) * t) * sin(PI * (1.0 - e)) * 0.56

func _fn_perk(t: float, e: float)   -> float:
	var freq: float = 660.0 if e > 0.5 else 880.0
	return sin(TAU * freq * t) * sin(PI * (1.0 - e)) * 0.54

func _fn_damage(t: float, e: float) -> float:
	return (sin(TAU * 95.0 * t) * 0.40 + (randf() * 2.0 - 1.0) * 0.60) * e * 0.72

func _fn_parry(t: float, e: float) -> float:
	# Metallic clang: sharp attack, high ring + low thud
	var clang: float = sin(TAU * (1800.0 - 600.0 * t) * t) * pow(e, 3.5) * 0.55
	var ring: float  = sin(TAU * 880.0 * t) * pow(e, 1.8) * 0.40
	return (clang + ring) * 0.75

func _fn_explode(t: float, e: float) -> float:
	var boom: float    = sin(TAU * (75.0 * pow(e, 2.2) + 18.0) * t) * 0.60
	var crackle: float = (randf() * 2.0 - 1.0) * pow(e, 0.35) * 0.50
	return (boom + crackle) * pow(e, 0.45) * 0.78

func _fn_kill(t: float, e: float)   -> float:
	var freq: float = 260.0 * pow(e, 1.5) + 30.0
	return (sin(TAU * freq * t) * 0.55 + (randf() * 2.0 - 1.0) * 0.45) * e * 0.62

func _fn_death(t: float, e: float)  -> float:
	var freq: float = 400.0 * pow(e, 2.5) + 20.0
	return (sin(TAU * freq * t) * 0.65 + (randf() * 2.0 - 1.0) * 0.35) * pow(e, 0.6) * 0.70

func _fn_boss(t: float, e: float)   -> float:
	return sin(TAU * (180.0 + 36.0 * sin(TAU * 6.0 * t)) * t) * sin(PI * (1.0 - e)) * 0.68
