extends Control

# Set before adding to scene tree.
# Values: "grunt" | "shooter" | "speeder" | "kamikaze" | "tank" | "boss"
var enemy_type: String = "grunt"

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Scale denominators are the native pixel extents of each drawing type.
	# Boss: wheels ±32 wide → 76px, exhaust to +53 → 99px tall.
	# Tank: wheels ±24 wide → 68px.  Others fit the standard 52×88 box.
	var s: float
	match enemy_type:
		"boss": s = minf(size.x / 78.0, size.y / 102.0) * 0.88
		"tank": s = minf(size.x / 62.0, size.y / 88.0)  * 0.88
		_:      s = minf(size.x / 52.0, size.y / 88.0)  * 0.88
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.5), 0.0, Vector2(s, s))
	match enemy_type:
		"grunt":    _grunt()
		"shooter":  _shooter()
		"speeder":  _speeder()
		"kamikaze": _kamikaze()
		"tank":     _tank()
		"boss":     _boss()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ─── GRUNT — wide red muscle car ─────────────────────────────────────────────
func _grunt() -> void:
	var c  := Color(0.90, 0.20, 0.20)
	var dk := Color(0.38, 0.08, 0.08)
	var cr := Color(0.72, 0.72, 0.78)
	for wx in [-18, 18]:
		for wy in [-14, 14]:
			draw_circle(Vector2(wx, wy), 9.0, dk)
	draw_rect(Rect2(-18, -22, 36, 44), c)
	draw_rect(Rect2(-22,  -8,  6, 24), Color(c.r*0.65, c.g*0.65, c.b*0.65))
	draw_rect(Rect2( 16,  -8,  6, 24), Color(c.r*0.65, c.g*0.65, c.b*0.65))
	draw_rect(Rect2(-18, -27, 36,  5), cr)
	draw_rect(Rect2(-16, -25, 10,  4), Color(1.0, 0.96, 0.80))
	draw_rect(Rect2(  6, -25, 10,  4), Color(1.0, 0.96, 0.80))
	draw_rect(Rect2(-12, -16, 24, 12), Color(c.r*0.30, c.g*0.30, c.b*0.55, 0.80))
	draw_rect(Rect2( -5, -22, 10, 10), dk)
	draw_rect(Rect2(-11,  -4, 22, 14), dk)
	draw_rect(Rect2(-18,  20, 36,  5), cr)
	draw_rect(Rect2(-16,  21, 12,  3), Color(0.92, 0.08, 0.08))
	draw_rect(Rect2(  4,  21, 12,  3), Color(0.92, 0.08, 0.08))
	for wx in [-18, 18]:
		for wy in [-14, 14]:
			draw_circle(Vector2(wx, wy), 8.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 5.0, Color(0.70, 0.70, 0.75))
			draw_circle(Vector2(wx, wy), 2.5, Color(0.25, 0.25, 0.28))

# ─── SHOOTER — orange angular tech car ───────────────────────────────────────
func _shooter() -> void:
	var c  := Color(0.90, 0.50, 0.10)
	var dk := Color(c.r*0.40, c.g*0.40, c.b*0.40)
	draw_rect(Rect2(-11, -26, 22, 10), dk)
	draw_rect(Rect2( -7, -28, 14,  4), c)
	draw_rect(Rect2(-14, -18, 28, 42), c)
	draw_rect(Rect2(-18, -10,  5, 20), dk)
	draw_rect(Rect2( 13, -10,  5, 20), dk)
	draw_rect(Rect2(-10, -18, 20, 11), Color(c.r*0.20, c.g*0.30, c.b*0.60, 0.88))
	draw_rect(Rect2( -8, -17,  5,  3), Color(1.0, 1.0, 1.0, 0.25))
	draw_rect(Rect2( -5,  -7, 10,  8), dk)
	draw_circle(Vector2(0, -3), 3.5, Color(c.r*0.30, c.g*0.30, 0.05))
	draw_circle(Vector2(0, -3), 2.0, Color(1.0, 0.65, 0.10, 0.90))
	draw_rect(Rect2(-13, -25,  7,  3), Color(1.0, 0.95, 0.70))
	draw_rect(Rect2(  6, -25,  7,  3), Color(1.0, 0.95, 0.70))
	draw_rect(Rect2(-14,  22, 28,  5), dk)
	draw_rect(Rect2(-11,  23,  5,  3), Color(0.9, 0.1, 0.1))
	draw_rect(Rect2(  6,  23,  5,  3), Color(0.9, 0.1, 0.1))
	for wx in [-14, 14]:
		for wy in [-12, 14]:
			draw_circle(Vector2(wx, wy), 6.5, Color(0.11, 0.11, 0.14))
			draw_circle(Vector2(wx, wy), 4.0, Color(c.r*0.60, c.g*0.50, 0.15))
			draw_circle(Vector2(wx, wy), 1.8, Color(0.20, 0.20, 0.22))

# ─── SPEEDER — narrow green race car ─────────────────────────────────────────
func _speeder() -> void:
	var c  := Color(0.20, 0.90, 0.40)
	var dk := Color(c.r*0.38, c.g*0.38, c.b*0.38)
	draw_rect(Rect2( -8, -28, 16,  6), dk)
	draw_rect(Rect2( -5, -32, 10,  6), c)
	draw_rect(Rect2(-12, -24, 24, 48), c)
	draw_rect(Rect2(-16,  -8,  5, 20), dk)
	draw_rect(Rect2( 11,  -8,  5, 20), dk)
	draw_rect(Rect2( -2, -32,  4, 56), Color(1.0, 1.0, 1.0, 0.55))
	draw_rect(Rect2( -7, -18, 14,  9), Color(c.r*0.25, c.g*0.45, c.b*0.70, 0.85))
	draw_rect(Rect2( -5, -17,  4,  3), Color(1.0, 1.0, 1.0, 0.30))
	draw_circle(Vector2(-7, -29), 3.0, Color(1.0, 0.98, 0.78))
	draw_circle(Vector2( 7, -29), 3.0, Color(1.0, 0.98, 0.78))
	draw_rect(Rect2(-14,  22, 28,  3), dk)
	draw_rect(Rect2(-16,  20, 32,  3), Color(0.18, 0.18, 0.22))
	for wx in [-12, 12]:
		for wy in [-14, 16]:
			draw_circle(Vector2(wx, wy), 6.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 3.5, Color(c.r*0.55, c.g*0.75, 0.12))

# ─── KAMIKAZE — battered homing car ──────────────────────────────────────────
func _kamikaze() -> void:
	var c    := Color(1.0, 0.20, 0.60)
	var dark := Color(0.30, 0.04, 0.15)
	var rust := Color(0.52, 0.18, 0.05)
	draw_rect(Rect2(-14, -22, 30, 46), c)
	draw_rect(Rect2(-16,  -6,  4, 20), rust)
	draw_rect(Rect2( 14,   0,  4, 14), dark)
	draw_rect(Rect2(-10, -16, 21, 12), Color(0.25, 0.35, 0.55, 0.70))
	draw_line(Vector2(-6, -16), Vector2(2, -4),  Color(0.0, 0.0, 0.0, 0.55), 1.0)
	draw_line(Vector2( 4, -16), Vector2(-2, -6), Color(0.0, 0.0, 0.0, 0.40), 1.0)
	draw_rect(Rect2( -8,  -4, 17, 13), dark)
	draw_rect(Rect2(-13, -26, 28,  5), rust)
	draw_circle(Vector2(-8, -24), 3.0, Color(1.0, 0.95, 0.75))
	draw_circle(Vector2( 8, -24), 3.0, Color(0.25, 0.18, 0.10))
	draw_line(Vector2(6, -26), Vector2(10, -22), Color(0.0, 0.0, 0.0, 0.80), 1.5)
	draw_circle(Vector2(0, 8), 10.0, Color(1.0, 0.40, 0.00, 0.30))
	draw_circle(Vector2(0, 8),  5.5, Color(1.0, 0.80, 0.10, 0.50))
	for wx in [-14, 14]:
		for wy in [-12, 14]:
			draw_circle(Vector2(wx, wy), 7.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 4.0, Color(0.55, 0.50, 0.12))

# ─── TANK — massive armoured vehicle ─────────────────────────────────────────
func _tank() -> void:
	var c      := Color(0.40, 0.40, 0.50)
	var dark   := Color(c.r*0.40, c.g*0.40, c.b*0.42)
	var plate  := Color(c.r*0.68, c.g*0.68, c.b*0.72)
	var chrome := Color(0.72, 0.72, 0.80)
	# Shield aura
	draw_rect(Rect2(-27, -36, 54, 72), Color(0.35, 0.65, 1.0, 0.14))
	draw_arc(Vector2(0, 0), 34, 0, TAU, 40, Color(0.50, 0.80, 1.0, 0.28), 1.5)
	# Wheels
	for wx in [-24.0, 24.0]:
		for wy in [-18.0, 18.0]:
			draw_circle(Vector2(wx, wy), 8.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 5.0, Color(0.55, 0.55, 0.60))
			draw_circle(Vector2(wx, wy), 2.5, Color(0.20, 0.20, 0.24))
	draw_rect(Rect2(-22, -28, 44, 56), c)
	draw_rect(Rect2(-26, -12,  5, 30), dark)
	draw_rect(Rect2( 21, -12,  5, 30), dark)
	draw_rect(Rect2(-22, -34, 44,  7), plate)
	draw_rect(Rect2(-18, -32, 36,  4), chrome)
	draw_rect(Rect2(-20, -28,  9,  4), Color(1.0, 0.95, 0.75))
	draw_rect(Rect2( 11, -28,  9,  4), Color(1.0, 0.95, 0.75))
	draw_rect(Rect2(-14, -20, 28,  8), Color(c.r*0.2, c.g*0.25, c.b*0.5, 0.88))
	draw_rect(Rect2( -8,  -6, 16, 12), dark)
	draw_circle(Vector2(0, -2), 5.0, dark)
	draw_rect(Rect2( -2, -10,  4,  9), dark)
	draw_rect(Rect2( -1, -12,  2,  4), chrome)
	draw_rect(Rect2(-22,  26, 44,  5), plate)
	draw_circle(Vector2(-15, 28), 3.0, Color(0.9, 0.08, 0.08))
	draw_circle(Vector2( 15, 28), 3.0, Color(0.9, 0.08, 0.08))

# ─── BOSS — imposing command vehicle ─────────────────────────────────────────
func _boss() -> void:
	var c      := Color(0.75, 0.12, 0.08)
	var dark   := Color(c.r*0.48, c.g*0.48, c.b*0.50)
	var plate  := Color(c.r*0.72, c.g*0.72, c.b*0.75)
	var chrome := Color(0.75, 0.76, 0.84)
	# Wheels
	for wx in [-32.0, 32.0]:
		for wy in [-24.0, 24.0]:
			draw_circle(Vector2(wx, wy), 10.0, Color(0.08, 0.08, 0.10))
			draw_circle(Vector2(wx, wy),  7.0, Color(c.r*0.50, c.g*0.50, c.b*0.55))
			draw_circle(Vector2(wx, wy),  3.5, Color(chrome.r, chrome.g, chrome.b))
	# Main hull
	draw_rect(Rect2(-24, -40, 48, 80), c)
	# Side wing plates
	draw_rect(Rect2(-38, -16, 15, 38), dark)
	draw_rect(Rect2( 23, -16, 15, 38), dark)
	# Front prow
	draw_rect(Rect2(-24, -46, 48,  7), plate)
	draw_rect(Rect2(-18, -44, 36,  4), chrome)
	# Grille
	draw_rect(Rect2(-18, -38, 36,  6), Color(0.06, 0.06, 0.08))
	# Headlights
	draw_rect(Rect2(-22, -44, 10,  4), Color(1.0, 0.96, 0.78))
	draw_rect(Rect2( 12, -44, 10,  4), Color(1.0, 0.96, 0.78))
	# Windshield slit
	draw_rect(Rect2(-18, -30, 36, 15), Color(c.r*0.18, c.g*0.22, c.b*0.52, 0.90))
	# Roof turret
	draw_rect(Rect2(-14,  -4, 28, 18), dark)
	draw_rect(Rect2( -7, -12, 14,  8), dark)
	draw_rect(Rect2( -6, -18,  4, 10), dark)
	draw_rect(Rect2(  2, -18,  4, 10), dark)
	draw_circle(Vector2(0, -4), 4.5, Color(1.00, 0.50, 0.10, 0.90))
	# Rear
	draw_rect(Rect2(-24,  38, 48,  5), plate)
	draw_circle(Vector2(-16, 40), 4.0, Color(0.95, 0.08, 0.06))
	draw_circle(Vector2( 16, 40), 4.0, Color(0.95, 0.08, 0.06))
	# Exhaust glow
	draw_circle(Vector2(-14, 48), 5.0, Color(1.0, 0.48, 0.02, 0.55))
	draw_circle(Vector2( 14, 48), 5.0, Color(1.0, 0.48, 0.02, 0.55))
