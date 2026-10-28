extends Node2D

var _t: float = 0.0
const DURATION: float = 0.65
var color: Color = Color(1.0, 0.5, 0.0)

# Debris particles — seeded at _ready, updated each frame
var _debris: Array = []  # [{offset: Vector2, vel: Vector2, size: float}]

func _ready() -> void:
	for i in 14:
		var angle := float(i) / 14.0 * TAU + randf() * 0.45
		var spd   := randf_range(85.0, 295.0)
		_debris.append({
			"offset": Vector2.ZERO,
			"vel":    Vector2(cos(angle), sin(angle)) * spd,
			"size":   randf_range(2.5, 5.5),
		})

func _process(delta: float) -> void:
	_t += delta
	for d in _debris:
		d["offset"] += d["vel"] * delta
		d["vel"] *= pow(0.86, delta * 60.0)
	queue_redraw()
	if _t >= DURATION:
		queue_free()

func _draw() -> void:
	var p: float   = clamp(_t / DURATION, 0.0, 1.0)
	var inv := 1.0 - p

	# ── Outer shockwave ring (fast expand, fades first)
	var r_shock := p * 140.0
	var a_shock := maxf(0.0, 1.0 - p * 2.4) * 0.65
	if a_shock > 0.01:
		draw_arc(Vector2.ZERO, r_shock, 0.0, TAU, 56,
			Color(color.r, color.g * 0.5, 0.08, a_shock), 3.0)

	# ── Second ring (bright, narrower)
	var r2 := p * 85.0
	var a2 := maxf(0.0, 1.0 - p * 2.9) * 0.90
	if a2 > 0.01:
		draw_arc(Vector2.ZERO, r2, 0.0, TAU, 40,
			Color(1.0, 0.88, 0.30, a2), 5.5)

	# ── Inner fireball (peaks in first 1/3 then vanishes)
	var fb_p: float = clamp(p * 3.2, 0.0, 1.0)
	var fb_r := (1.0 - fb_p) * 60.0 + 6.0
	var fb_a := maxf(0.0, (1.0 - fb_p) * inv * 1.35)
	if fb_a > 0.01:
		draw_circle(Vector2.ZERO, fb_r,
			Color(1.0, 0.66, 0.10, fb_a))
		draw_circle(Vector2.ZERO, fb_r * 0.44,
			Color(1.0, 0.97, 0.78, minf(fb_a * 1.2, 1.0)))

	# ── Smoke puff (dark, slow expand, fades late)
	var sm_p: float = clamp((p - 0.10) / 0.90, 0.0, 1.0)
	var sm_a := sm_p * (1.0 - sm_p * sm_p) * 0.50
	if sm_a > 0.01:
		draw_circle(Vector2.ZERO, sm_p * 70.0,
			Color(0.04, 0.04, 0.07, sm_a))

	# ── Debris sparks
	for d in _debris:
		var da := maxf(0.0, inv * 2.0 - 1.0)
		if da < 0.02:
			continue
		draw_circle(d["offset"], d["size"] * (0.35 + inv * 0.65),
			Color(color.r, color.g * (0.35 + 0.35 * inv), 0.0, da))
