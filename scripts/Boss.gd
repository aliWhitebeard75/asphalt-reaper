extends "res://scripts/BaseEnemy.gd"

# Set by Main.gd before the boss enters the tree
var boss_number: int = 1

var phase: int = 1
var weave_timer: float = 0.0
var weave_lane: int = 1
var drone_timer: float = 4.0

signal phase_changed(new_phase: int)
signal boss_attack_fired(attack_type: int)

# ─── Attack cycling ───────────────────────────────────────────────────────────
# attack types: 0=spread, 1=lane_barrage, 2=radial_burst
var current_attack: int = 0
var attack_cycle_timer: float = 1.0   # first shot has a slight delay

# ─── Charge dash ──────────────────────────────────────────────────────────────
var is_charging: bool = false
var charge_timer_val: float = 0.0
var charge_cooldown: float = 3.5   # first charge comes early

# ─── Identity ─────────────────────────────────────────────────────────────────
func get_boss_name() -> String:
	match boss_number:
		1: return "ROAD TITAN"
		2: return "SAND COLOSSUS"
		3: return "NEON PHANTOM"
		4: return "ICE CRUSHER"
		5: return "MAGMA TYRANT"
		6: return "FOREST PREDATOR"
		7: return "IRON SENTINEL"
		8:  return "TIDAL FORCE"
		9:  return "SHADOW LEVIATHAN"
		10: return "APEX VOIDREAPER"
		11: return "NEON RAVAGER"
		12: return "CRIMSON WARLORD"
		13: return "CRYSTAL GOLEM"
		14: return "TOXIC COLOSSUS"
		15: return "ARCTIC ANNIHILATOR"
		16: return "STORM HERALD"
		17: return "CIRCUIT BREAKER"
		18: return "MAGMA BEHEMOTH"
		19: return "SKY MARAUDER"
		20: return "WRAITH KING"
		21: return "BLOOD REAPER"
		22: return "QUANTUM DESTROYER"
		23: return "DARK SOVEREIGN"
		24: return "CHROME TITAN"
		_:  return "VOID SOVEREIGN"

# ─── Shape & attack type helpers ─────────────────────────────────────────────
# 5 distinct boss archetypes, cycling every 5 bosses
func _get_shape_type() -> int:
	return (boss_number - 1) % 5

func _get_attack_pool() -> Array:
	var s := _get_shape_type()
	match phase:
		1: return [0]        # all bosses open with basic spread
		2:
			match s:
				0: return [0, 1]   # Armored:     spread + barrage
				1: return [0, 3]   # Racer:       spread + rapid volley
				2: return [0, 4]   # Hex:         spread + lateral sweep
				3: return [0, 5]   # Juggernaut:  spread + cluster bomb
				_: return [0, 6]   # Phantom:     spread + homing
		_:  # phase 3 — full aggression
			match s:
				0: return [0, 1, 2]   # Armored:    spread/barrage/radial
				1: return [3, 0, 1]   # Racer:      volley/spread/barrage
				2: return [4, 2, 0]   # Hex:        sweep/radial/spread
				3: return [5, 1, 0]   # Juggernaut: bomb/barrage/spread
				_: return [6, 0, 2]   # Phantom:    homing/spread/radial

# ─── Stats ────────────────────────────────────────────────────────────────────
func setup() -> void:
	is_boss = true
	_sprite_type = "boss"
	match boss_number:
		1:  # City Highway
			health = 3200.0;  max_health = 3200.0;  speed = 55.0;  mass = 4.0; coin_value = 25
			color = Color(0.75, 0.12, 0.08)
		2:  # Desert Road
			health = 3600.0;  max_health = 3600.0;  speed = 65.0;  mass = 4.5; coin_value = 28
			color = Color(0.85, 0.65, 0.20)
		3:  # Night City
			health = 3000.0;  max_health = 3000.0;  speed = 120.0; mass = 2.5; coin_value = 30
			color = Color(0.00, 0.88, 1.00)
		4:  # Ice Road
			health = 4400.0;  max_health = 4400.0;  speed = 45.0;  mass = 5.5; coin_value = 32
			color = Color(0.55, 0.80, 1.00)
		5:  # Volcano Pass
			health = 4200.0;  max_health = 4200.0;  speed = 78.0;  mass = 4.2; coin_value = 35
			color = Color(0.95, 0.40, 0.05)
		6:  # Forest Track
			health = 3600.0;  max_health = 3600.0;  speed = 108.0; mass = 3.0; coin_value = 38
			color = Color(0.15, 0.58, 0.12)
		7:  # Industrial Zone
			health = 5400.0;  max_health = 5400.0;  speed = 40.0;  mass = 6.0; coin_value = 40
			color = Color(0.55, 0.56, 0.60)
		8:  # Coastal Road
			health = 4400.0;  max_health = 4400.0;  speed = 92.0;  mass = 3.5; coin_value = 42
			color = Color(0.05, 0.58, 0.78)
		9:  # Underground Tunnel
			health = 5200.0;  max_health = 5200.0;  speed = 88.0;  mass = 4.5; coin_value = 45
			color = Color(0.28, 0.05, 0.52)
		10: # Space Highway
			health = 6600.0;  max_health = 6600.0;  speed = 82.0;  mass = 5.0; coin_value = 50
			color = Color(0.05, 0.05, 0.08)
		11: # Neon Wasteland
			health = 7000.0;  max_health = 7000.0;  speed = 95.0;  mass = 4.0; coin_value = 55
			color = Color(1.00, 0.10, 0.80)
		12: # Crimson Badlands
			health = 7600.0;  max_health = 7600.0;  speed = 60.0;  mass = 5.2; coin_value = 58
			color = Color(0.85, 0.08, 0.06)
		13: # Crystal Caverns
			health = 7200.0;  max_health = 7200.0;  speed = 130.0; mass = 2.8; coin_value = 60
			color = Color(0.80, 0.95, 1.00)
		14: # Toxic Swamp
			health = 8400.0;  max_health = 8400.0;  speed = 52.0;  mass = 6.0; coin_value = 62
			color = Color(0.35, 0.90, 0.10)
		15: # Arctic Tundra
			health = 8000.0;  max_health = 8000.0;  speed = 88.0;  mass = 4.5; coin_value = 65
			color = Color(0.75, 0.90, 1.00)
		16: # Storm Corridor
			health = 8800.0;  max_health = 8800.0;  speed = 76.0;  mass = 4.2; coin_value = 68
			color = Color(0.60, 0.65, 0.80)
		17: # Cyberpunk Slums
			health = 9200.0;  max_health = 9200.0;  speed = 105.0; mass = 3.5; coin_value = 70
			color = Color(0.00, 0.95, 0.55)
		18: # Lava Fields
			health = 10000.0; max_health = 10000.0; speed = 58.0;  mass = 6.5; coin_value = 72
			color = Color(0.98, 0.30, 0.02)
		19: # Sky Bridge
			health = 8800.0;  max_health = 8800.0;  speed = 118.0; mass = 3.2; coin_value = 75
			color = Color(0.45, 0.75, 1.00)
		20: # Haunted Highway
			health = 10400.0; max_health = 10400.0; speed = 92.0;  mass = 5.0; coin_value = 78
			color = Color(0.28, 0.82, 0.42)
		21: # Blood Moon Pass
			health = 11000.0; max_health = 11000.0; speed = 72.0;  mass = 5.5; coin_value = 80
			color = Color(0.92, 0.05, 0.08)
		22: # Quantum Grid
			health = 11600.0; max_health = 11600.0; speed = 112.0; mass = 3.8; coin_value = 82
			color = Color(0.62, 0.18, 1.00)
		23: # Shadow Realm
			health = 12000.0; max_health = 12000.0; speed = 68.0;  mass = 6.2; coin_value = 85
			color = Color(0.22, 0.00, 0.38)
		24: # Chrome City
			health = 11400.0; max_health = 11400.0; speed = 138.0; mass = 3.0; coin_value = 88
			color = Color(0.82, 0.85, 0.92)
		_:  # Void Corridor (boss 25+ — all subsequent cycles)
			health = 13000.0; max_health = 13000.0; speed = 96.0;  mass = 5.5; coin_value = 92
			color = Color(0.00, 0.02, 0.06)

# ─── AI ───────────────────────────────────────────────────────────────────────
func ai_update(delta: float, player_pos: Vector2) -> void:
	# ── Phase transition ──────────────────────────────────────────────────────
	var hp_ratio = health / max_health
	var new_phase = 1
	if   hp_ratio <= 0.25: new_phase = 3
	elif hp_ratio <= 0.55: new_phase = 2
	if new_phase != phase:
		phase = new_phase
		emit_signal("phase_changed", phase)
		# Ensure charge doesn't fire the instant we enter a new phase
		charge_cooldown = max(charge_cooldown, 4.0)

	# ── Attack cycling ────────────────────────────────────────────────────────
	attack_cycle_timer -= delta
	# Each shape archetype has its own pacing
	const SHAPE_PERIODS: Array = [2.2, 1.5, 1.9, 2.8, 1.7]
	var cycle_period: float = max(0.5, SHAPE_PERIODS[_get_shape_type()] - float(phase - 1) * 0.45 - float(boss_number - 1) * 0.04)
	if attack_cycle_timer <= 0.0 and position.distance_to(player_pos) < 520.0:
		attack_cycle_timer = cycle_period + randf() * 0.2
		var pool: Array = _get_attack_pool()
		current_attack = pool[randi() % pool.size()]
		emit_signal("boss_attack_fired", current_attack)

	# ── Charge dash (phase 2+) ────────────────────────────────────────────────
	charge_cooldown -= delta
	charge_timer_val -= delta
	if phase >= 2 and charge_cooldown <= 0.0 and not is_charging:
		is_charging = true
		charge_timer_val = 0.55 + float(phase - 2) * 0.15
		charge_cooldown = max(3.5, 7.5 - float(phase) * 1.2) + randf() * 1.5

	if charge_timer_val <= 0.0 and is_charging:
		is_charging = false

	# ── Weave between lanes ───────────────────────────────────────────────────
	weave_timer -= delta
	if weave_timer <= 0.0:
		var weave_base = max(0.30, 1.5 - float(boss_number - 1) * 0.05 - float(phase) * 0.30)
		weave_timer = weave_base + randf() * 0.20
		var opts = [0, 1, 2]
		opts.erase(weave_lane)
		# Phase 3: aggressively track player lane
		if phase >= 3 and main_ref:
			var player = main_ref.get_node_or_null("Player")
			if player and is_instance_valid(player):
				opts = [player.current_lane]
		weave_lane = opts[randi() % opts.size()]

	var tx = main_ref.LANE_X[weave_lane] if main_ref else position.x
	var dx = tx - position.x
	var vx = sign(dx) * min(abs(dx) * 3.5, 160.0)

	# ── Vertical positioning (charge overrides gap) ───────────────────────────
	var desired_y: float
	if is_charging:
		# Rush forward — much smaller gap to threaten a ram
		desired_y = player_pos.y - 100.0
	else:
		desired_y = player_pos.y - 230.0
	var dy = desired_y - position.y
	var vy_max: float = 380.0 if is_charging else 130.0
	var vy = clamp(dy * 4.0, -vy_max, vy_max)
	velocity = Vector2(vx, vy)

	# Gap safety — velocity push only (no hard snap), suspended during charge
	if not is_charging:
		var min_gap: float = 175.0 + float(phase) * 10.0
		if position.y > player_pos.y - min_gap:
			velocity.y = min(velocity.y, -90.0)

	# ── Phase 2+: spawn drones ────────────────────────────────────────────────
	if phase >= 2:
		drone_timer -= delta
		if drone_timer <= 0.0:
			drone_timer = max(2.0, 5.0 - float(phase) * 1.2) + randf() * 0.5
			if main_ref and main_ref.has_method("spawn_boss_drone"):
				main_ref.spawn_boss_drone(position)

# ─── Ram override (boss doesn't get blasted away) ─────────────────────────────
func _check_ram_player() -> void:
	if main_ref == null or ram_cooldown > 0.0: return
	var player = main_ref.get_node_or_null("Player")
	if not player or not is_instance_valid(player): return
	if position.distance_to(player.position) < 54.0:
		player.take_damage(20.0 * mass)
		# Boss barely moves — just a small nudge back
		var away = (position - player.position).normalized()
		knockback_vel   = away * 120.0
		knockback_timer = 0.25
		ram_cooldown    = 1.5

# ─── Drawing ──────────────────────────────────────────────────────────────────
func _draw() -> void:
	var t  := Time.get_ticks_msec() / 1000.0
	var p1 := (sin(t * 4.5) + 1.0) * 0.5
	var p3 := (sin(t * 8.0) + 1.0) * 0.5
	var c  := color
	if phase == 2:
		c = Color(c.r + p1 * 0.12, c.g, c.b + p1 * 0.18).clamp()
	elif phase == 3:
		c = Color(c.r + p3 * 0.35, c.g + p3 * 0.05, c.b + p3 * 0.25).clamp()

	_draw_phase_effects(c, t, p1, p3)
	if _has_sprite():
		# ── Sprite hull ──────────────────────────────────────────────────────
		var reg = get_node_or_null("/root/SpriteRegistry")
		var sf: float = 0.035
		if reg:
			sf = float(reg.get_scale("boss"))
		var ts: Vector2 = _enemy_tex.get_size()
		draw_set_transform(Vector2.ZERO, -PI / 2.0, Vector2(sf, sf))
		draw_texture(_enemy_tex, Vector2(-ts.x * 0.5, -ts.y * 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		match _get_shape_type():
			0: _draw_armored(c, t, p1)
			1: _draw_racer(c, t, p1)
			2: _draw_hex(c, t, p1)
			3: _draw_juggernaut(c, t, p1)
			_: _draw_phantom(c, t, p1)
	_draw_health_bar()
	queue_redraw()

func _draw_phase_effects(c: Color, t: float, p1: float, p3: float) -> void:
	if phase >= 2:
		draw_rect(Rect2(-50, -62, 100, 118), Color(c.r, c.g, c.b, 0.07 + p1 * 0.10))
		draw_arc(Vector2.ZERO, 54, 0, TAU, 64, Color(c.r, c.g, c.b, 0.20 + p1 * 0.16), 1.5)
	if phase >= 3:
		for i in 6:
			var a1 := t * 3.2 + float(i) * (TAU / 6.0)
			var a2 := a1 + 0.4 + randf() * 0.2
			draw_line(Vector2(cos(a1)*50, sin(a1)*50), Vector2(cos(a2)*57, sin(a2)*57),
				Color(0.65, 0.90, 1.0, 0.68 + p3 * 0.30), 1.5)
		for i in 6:
			var angle := t * 3.2 + float(i) * (TAU / 6.0)
			var op    := Vector2(cos(angle) * 50.0, sin(angle) * 0.65 * 50.0)
			draw_circle(op, 6.0, Color(0.70, 0.92, 1.0, 0.90))
			draw_circle(op, 3.0, Color(1.0, 1.0, 1.0, 0.85))
			var tp := Vector2(cos(angle - 0.22) * 50.0, sin(angle - 0.22) * 0.65 * 50.0)
			draw_line(tp, op, Color(0.60, 0.88, 1.0, 0.42), 2.0)

func _draw_health_bar() -> void:
	var bar_w := 72.0
	var hp_ratio: float = clamp(health / max_health, 0.0, 1.0)
	var bar_col: Color
	if   hp_ratio > 0.55: bar_col = Color(0.10, 0.85, 0.15)
	elif hp_ratio > 0.25: bar_col = Color(1.00, 0.65, 0.00)
	else:                  bar_col = Color(0.90, 0.08, 0.08)
	draw_rect(Rect2(-bar_w * 0.5, -82, bar_w, 10), Color(0.06, 0.0, 0.0))
	draw_rect(Rect2(-bar_w * 0.5, -82, bar_w * hp_ratio, 10), bar_col)
	draw_rect(Rect2(-bar_w * 0.5, -82, bar_w * hp_ratio,  3), Color(1.0, 1.0, 1.0, 0.15))
	draw_rect(Rect2(-bar_w*0.5 + bar_w*0.55 - 1, -82, 2, 10), Color(0.0, 0.0, 0.0, 0.85))
	draw_rect(Rect2(-bar_w*0.5 + bar_w*0.25 - 1, -82, 2, 10), Color(0.0, 0.0, 0.0, 0.85))

# ── Shape 0: Armored Behemoth — wide, heavily plated war machine ──────────────
func _draw_armored(c: Color, t: float, p1: float) -> void:
	var dark   := Color(c.r * 0.48, c.g * 0.48, c.b * 0.50)
	var plate  := Color(c.r * 0.72, c.g * 0.72, c.b * 0.75)
	var chrome := Color(0.75, 0.76, 0.84)
	var black  := Color(0.06, 0.06, 0.08)
	var fa     := 0.55 + sin(t * 14.0) * 0.45
	# Rear exhausts
	draw_rect(Rect2(-24, 44, 8, 12), dark);  draw_rect(Rect2(16, 44, 8, 12), dark)
	var ea := 0.35 + float(phase - 1) * 0.20
	draw_circle(Vector2(-20, 56), 5.0 + float(phase)*1.5, Color(1.0, 0.48, 0.02, ea * fa))
	draw_circle(Vector2( 20, 56), 5.0 + float(phase)*1.5, Color(1.0, 0.48, 0.02, ea * fa))
	# Wheels
	for wx in [-36.0, 36.0]:
		for wy in [-28.0, 28.0]:
			draw_circle(Vector2(wx, wy), 13.0, black)
			draw_circle(Vector2(wx, wy),  9.5, Color(c.r*0.50, c.g*0.50, c.b*0.55))
			draw_circle(Vector2(wx, wy),  5.0, chrome);  draw_circle(Vector2(wx, wy), 2.5, black)
			for li in 4:
				var la := float(li) * PI * 0.5 + t * float(phase - 1) * 0.8
				draw_circle(Vector2(wx + cos(la)*6.5, wy + sin(la)*6.5), 1.4, chrome)
	# Hull
	draw_rect(Rect2(-28, -46, 56, 92), c)
	draw_rect(Rect2(-44, -18, 17, 44), dark);  draw_rect(Rect2(27, -18, 17, 44), dark)
	draw_rect(Rect2(-44, -16,  2, 40), plate); draw_rect(Rect2(42, -16,  2, 40), plate)
	draw_rect(Rect2(-28, -52, 56,  8), plate); draw_rect(Rect2(-22, -50, 44, 5), chrome)
	draw_rect(Rect2(-26, -48, 52,  3), chrome)
	draw_rect(Rect2(-22, -44, 44, 8), black)
	for gx in [-18, -10, -2, 6, 14]:
		draw_rect(Rect2(gx, -44, 4, 8), Color(0.04, 0.04, 0.06))
	draw_rect(Rect2(-26, -50, 12, 5), Color(1.0, 0.96, 0.78))
	draw_rect(Rect2( 14, -50, 12, 5), Color(1.0, 0.96, 0.78))
	draw_rect(Rect2(-20, -34, 40, 18), Color(c.r*0.18, c.g*0.22, c.b*0.52, 0.90))
	draw_rect(Rect2(-22, -36, 44,  4), plate);  draw_rect(Rect2(-20, -37, 40, 2), chrome)
	draw_rect(Rect2(-16,  -6, 32, 22), dark)
	draw_rect(Rect2(-10, -12, 20, 10), dark)
	draw_circle(Vector2(-5, -8), 5.5, Color(0.16, 0.16, 0.20))
	draw_circle(Vector2( 5, -8), 5.5, Color(0.16, 0.16, 0.20))
	draw_rect(Rect2(-8, -20, 4, 12), dark);  draw_rect(Rect2(4, -20, 4, 12), dark)
	draw_rect(Rect2(-7, -22, 2, 5), chrome); draw_rect(Rect2(5, -22, 2, 5), chrome)
	var sc := Color(1.0, 0.65, 0.10) if phase == 1 else (Color(0.55, 0.25, 1.0) if phase == 2 else Color(1.0, 0.10, 0.10))
	draw_circle(Vector2(0, -2), 4.5, sc.darkened(0.4));  draw_circle(Vector2(0, -2), 2.5, sc)
	draw_rect(Rect2(-28, 44, 56, 6), plate)
	draw_circle(Vector2(-18, 46), 4.5, Color(0.95, 0.08, 0.06))
	draw_circle(Vector2( 18, 46), 4.5, Color(0.95, 0.08, 0.06))
	if phase >= 2:
		for jx in [-16.0, 0.0, 16.0]:
			draw_circle(Vector2(jx, 52), (5.5 + float(phase-1)) * (0.9 + p1 * 0.3), Color(1.0, 0.50, 0.00, fa * 0.75))

# ── Shape 1: Velocity Racer — long, narrow, high-speed aerodynamic frame ──────
func _draw_racer(c: Color, t: float, p1: float) -> void:
	var dark   := Color(c.r * 0.38, c.g * 0.38, c.b * 0.38)
	var chrome := Color(0.80, 0.82, 0.90)
	var black  := Color(0.06, 0.06, 0.08)
	var fa     := 0.55 + sin(t * 16.0) * 0.45
	# Engine exhausts (triple pipes)
	for ex in [-14.0, 0.0, 14.0]:
		draw_rect(Rect2(ex - 4, 48, 8, 16), dark)
		draw_circle(Vector2(ex, 64), 5.0 + float(phase)*1.2, Color(0.10, 0.60, 1.0, fa * (0.55 + float(phase-1)*0.18)))
	# Rear wing
	draw_rect(Rect2(-54, 34, 108, 5), dark);   draw_rect(Rect2(-54, 32, 108, 3), chrome)
	draw_rect(Rect2(-50, 37,   6, 10), dark);  draw_rect(Rect2(44,  37,   6, 10), dark)
	# Narrow body
	draw_rect(Rect2(-16, -60, 32, 110), c)
	# Side diffuser vents
	draw_rect(Rect2(-28, -10, 13, 28), dark);  draw_rect(Rect2(15, -10, 13, 28), dark)
	for vy in [-6, 0, 6, 12, 18]:
		draw_rect(Rect2(-27, vy - 10, 11, 2), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2( 16, vy - 10, 11, 2), Color(0.04, 0.04, 0.06))
	# Nose cone
	draw_rect(Rect2(-10, -68, 20, 10), dark)
	draw_rect(Rect2( -6, -74, 12,  8), c)
	draw_rect(Rect2( -3, -78,  6,  6), chrome)
	draw_rect(Rect2(-24, -62, 48, 4), dark);   draw_rect(Rect2(-22, -60, 44, 3), chrome)
	# Headlights — narrow slits
	draw_rect(Rect2(-14, -64, 8, 3), Color(0.60, 0.90, 1.0))
	draw_rect(Rect2(  6, -64, 8, 3), Color(0.60, 0.90, 1.0))
	# Cockpit
	draw_rect(Rect2(-10, -52, 20, 22), Color(c.r*0.15, c.g*0.25, c.b*0.55, 0.88))
	draw_rect(Rect2( -8, -50,  5,  4), Color(1.0, 1.0, 1.0, 0.22))
	# Single-barrel roof weapon
	draw_rect(Rect2(-4, -8, 8, 14), dark);  draw_circle(Vector2(0, -4), 4.5, Color(0.18, 0.18, 0.22))
	draw_rect(Rect2(-2, -18, 4, 14), dark); draw_rect(Rect2(-1, -20, 2, 4), chrome)
	var sc := Color(0.10, 0.80, 1.0) if phase == 1 else (Color(1.0, 0.55, 0.0) if phase == 2 else Color(1.0, 0.15, 0.15))
	draw_circle(Vector2(0, 6), 3.5, sc.darkened(0.35));  draw_circle(Vector2(0, 6), 2.0, sc)
	# Narrow wheels
	for wx in [-16.0, 16.0]:
		for wy in [-38.0, 30.0]:
			draw_circle(Vector2(wx, wy), 9.0, black)
			draw_circle(Vector2(wx, wy), 6.5, Color(c.r*0.45, c.g*0.60, 0.15))
			draw_circle(Vector2(wx, wy), 3.0, chrome);  draw_circle(Vector2(wx, wy), 1.5, black)
	if phase >= 2:
		for ex in [-14.0, 0.0, 14.0]:
			draw_circle(Vector2(ex, 68), (3.5 + float(phase)) * (0.8 + p1 * 0.45), Color(0.10, 0.60, 1.0, fa * 0.85))

# ── Shape 2: Hex Sentinel — hexagonal hull, extending side cannons ────────────
func _draw_hex(c: Color, t: float, p1: float) -> void:
	var dark   := Color(c.r * 0.42, c.g * 0.42, c.b * 0.44)
	var bright := c.lightened(0.22)
	var chrome := Color(0.72, 0.74, 0.82)
	var fa     := 0.55 + sin(t * 12.0) * 0.45
	# Hexagonal hull
	var pts := PackedVector2Array()
	for i in 6:
		var a := float(i) / 6.0 * TAU - PI / 6.0
		pts.append(Vector2(cos(a) * 34, sin(a) * 44))
	draw_colored_polygon(pts, c)
	var pts2 := PackedVector2Array()
	for i in 6:
		var a := float(i) / 6.0 * TAU - PI / 6.0
		pts2.append(Vector2(cos(a) * 22, sin(a) * 29))
	draw_colored_polygon(pts2, dark)
	draw_polyline(pts + PackedVector2Array([pts[0]]), chrome, 1.5)
	# Side cannon arms
	draw_rect(Rect2(-62, -10, 30, 18), dark);  draw_rect(Rect2(32, -10, 30, 18), dark)
	draw_rect(Rect2(-68, -5, 10, 8), Color(0.18, 0.18, 0.22))
	draw_rect(Rect2( 58, -5, 10, 8), Color(0.18, 0.18, 0.22))
	draw_rect(Rect2(-70, -3, 6, 4), chrome);  draw_rect(Rect2(64, -3, 6, 4), chrome)
	draw_circle(Vector2(-68, -1), 4.5, Color(c.r, c.g, c.b, 0.70 + p1 * 0.30))
	draw_circle(Vector2( 68, -1), 4.5, Color(c.r, c.g, c.b, 0.70 + p1 * 0.30))
	# Rotating scanner ring
	draw_arc(Vector2.ZERO, 18.0, t * 2.0, t * 2.0 + TAU * 0.75, 32, Color(bright.r, bright.g, bright.b, 0.58 + p1 * 0.28), 2.0)
	# Central reactor core
	draw_circle(Vector2.ZERO, 12.0, dark)
	draw_circle(Vector2.ZERO,  8.0, Color(c.r * 0.8 + 0.2, c.g * 0.8 + 0.2, c.b * 0.8 + 0.2, 0.90))
	draw_circle(Vector2.ZERO,  4.0, Color(1.0, 1.0, 1.0, 0.80 + p1 * 0.20))
	# Phase indicator lights at hex corners
	var sc := Color(1.0, 0.9, 0.10) if phase == 1 else (Color(0.10, 0.90, 1.0) if phase == 2 else Color(1.0, 0.10, 0.10))
	for i in 6:
		var a := float(i) / 6.0 * TAU - PI / 6.0
		draw_circle(Vector2(cos(a)*34, sin(a)*44), 3.0, sc)
	# Exhausts at bottom hex face
	for ex in [-12.0, 0.0, 12.0]:
		draw_circle(Vector2(ex, 44), 4.5 + float(phase), Color(1.0, 0.45, 0.05, fa * (0.45 + float(phase-1)*0.18)))
	if phase >= 2:
		draw_arc(Vector2.ZERO, 68, -0.15 + t * 0.55, 0.15 + t * 0.55 + PI, 32, Color(c.r, c.g, c.b, 0.16 + p1 * 0.20), 1.5)

# ── Shape 3: Iron Juggernaut — massive wide low-profile bulldozer ─────────────
func _draw_juggernaut(c: Color, t: float, p1: float) -> void:
	var dark   := Color(c.r * 0.44, c.g * 0.44, c.b * 0.46)
	var plate  := Color(c.r * 0.70, c.g * 0.70, c.b * 0.74)
	var chrome := Color(0.70, 0.72, 0.80)
	var black  := Color(0.05, 0.05, 0.07)
	var fa     := 0.55 + sin(t * 10.0) * 0.45
	# Front dozer blade
	draw_rect(Rect2(-52, -48, 104, 10), plate);  draw_rect(Rect2(-48, -44, 96, 6), chrome)
	draw_rect(Rect2(-50, -52, 100,  6), dark)
	# Six chunky wheels (3 per side)
	for wx in [-50.0, 50.0]:
		for wy in [-20.0, 4.0, 28.0]:
			draw_circle(Vector2(wx, wy), 11.0, black)
			draw_circle(Vector2(wx, wy),  8.0, Color(c.r*0.50, c.g*0.50, c.b*0.55))
			draw_circle(Vector2(wx, wy),  4.0, chrome);  draw_circle(Vector2(wx, wy), 2.0, black)
	# Wide hull
	draw_rect(Rect2(-44, -36, 88, 72), c)
	draw_rect(Rect2(-58, -22, 15, 50), dark);  draw_rect(Rect2(43, -22, 15, 50), dark)
	draw_rect(Rect2(-60, -20,  3, 46), plate); draw_rect(Rect2(57, -20,  3, 46), plate)
	# Side turret housings
	draw_rect(Rect2(-44, -14, 12, 22), Color(0.18, 0.18, 0.22))
	draw_rect(Rect2( 32, -14, 12, 22), Color(0.18, 0.18, 0.22))
	draw_circle(Vector2(-38, -3), 7.0, dark);  draw_circle(Vector2(38, -3), 7.0, dark)
	draw_rect(Rect2(-41, -20, 6, 14), dark);   draw_rect(Rect2(35, -20, 6, 14), dark)
	draw_rect(Rect2(-40, -22, 4,  4), chrome); draw_rect(Rect2(36, -22, 4,  4), chrome)
	# Windshield slit
	draw_rect(Rect2(-20, -28, 40, 8), Color(c.r*0.15, c.g*0.20, c.b*0.50, 0.88))
	draw_rect(Rect2(-22, -30, 44, 3), plate)
	# Low command pod
	draw_rect(Rect2(-18, -18, 36, 24), dark);  draw_rect(Rect2(-14, -16, 28, 20), Color(c.r*0.28, c.g*0.28, c.b*0.32))
	# Heavy cannon (wide single barrel)
	draw_rect(Rect2(-8, -18, 16, 10), dark)
	draw_rect(Rect2(-5, -32, 10, 18), dark);  draw_rect(Rect2(-4, -34, 8, 4), chrome)
	var sc := Color(1.0, 0.70, 0.0) if phase == 1 else (Color(1.0, 0.30, 0.0) if phase == 2 else Color(1.0, 0.06, 0.06))
	draw_circle(Vector2(0, -10), 5.0, sc.darkened(0.4));  draw_circle(Vector2(0, -10), 2.8, sc)
	# Rear bumper
	draw_rect(Rect2(-44, 34, 88, 6), plate);  draw_rect(Rect2(-40, 35, 80, 3), chrome)
	draw_circle(Vector2(-28, 36), 4.0, Color(0.9, 0.08, 0.06))
	draw_circle(Vector2( 28, 36), 4.0, Color(0.9, 0.08, 0.06))
	# Quad exhaust
	for ex in [-14.0, -5.0, 5.0, 14.0]:
		draw_rect(Rect2(ex - 3, 34, 6, 10), dark)
		draw_circle(Vector2(ex, 44), 4.0 + float(phase), Color(1.0, 0.38, 0.02, fa * (0.45 + float(phase-1)*0.16)))
	if phase >= 2:
		draw_rect(Rect2(-44, 34, 88, 4), Color(c.r, c.g, c.b, 0.10 + p1 * 0.18))

# ── Shape 4: Phantom Wraith — organic oval hull with animated tentacle arms ────
func _draw_phantom(c: Color, t: float, p1: float) -> void:
	var dark  := Color(c.r * 0.35, c.g * 0.35, c.b * 0.38)
	var glow  := Color(minf(c.r * 1.25, 1.0), minf(c.g * 1.25, 1.0), minf(c.b * 1.25, 1.0))
	var fa    := 0.55 + sin(t * 10.0) * 0.45
	var pulse := (sin(t * 5.0) + 1.0) * 0.5
	# 4 animated tentacle arms
	for i in 4:
		var ba  := float(i) / 4.0 * TAU + PI * 0.25
		var wig := sin(t * 3.0 + float(i) * 1.5) * 0.30
		var ex  := cos(ba + wig) * 56;  var ey := sin(ba + wig) * 56
		var mx  := cos(ba + wig * 0.5) * 34;  var my := sin(ba + wig * 0.5) * 34
		for seg in 6:
			var st: float = float(seg) / 5.0
			var sx: float = lerp(0.0, ex, st) + (1.0 - st) * (mx - lerp(0.0, ex, st)) * 0.4
			var sy: float = lerp(0.0, ey, st) + (1.0 - st) * (my - lerp(0.0, ey, st)) * 0.4
			draw_circle(Vector2(sx, sy), lerp(9.0, 2.5, st), Color(c.r, c.g, c.b, lerp(0.90, 0.28, st)))
		draw_circle(Vector2(ex, ey), 4.0, Color(glow.r, glow.g, glow.b, 0.62 + pulse * 0.35))
	# Outer oval body
	draw_circle(Vector2.ZERO, 34.0, dark)
	draw_circle(Vector2.ZERO, 28.0, c)
	# Inner energy ring
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.33 + pulse * 0.24), 2.5)
	# Central eye
	draw_circle(Vector2.ZERO, 11.0, dark)
	draw_circle(Vector2.ZERO,  7.0, Color(glow.r, glow.g, glow.b, 0.85 + pulse * 0.15))
	draw_circle(Vector2.ZERO,  4.0, Color(1.0, 1.0, 1.0, 0.90))
	draw_circle(Vector2.ZERO,  1.5, dark)
	# 3 orbiting mini-eyes (phase indicators)
	var sc := Color(1.0, 0.80, 0.10) if phase == 1 else (Color(0.20, 0.90, 1.0) if phase == 2 else Color(1.0, 0.10, 0.10))
	for i in 3:
		var ep := Vector2(cos(t * 2.5 + float(i) * (TAU / 3.0)) * 20.0, sin(t * 2.5 + float(i) * (TAU / 3.0)) * 20.0)
		draw_circle(ep, 4.5, sc.darkened(0.35));  draw_circle(ep, 2.5, sc)
	# Propulsion glow (bottom)
	for ex in [-12.0, 0.0, 12.0]:
		draw_circle(Vector2(ex, 34), 6.0 + float(phase)*1.5, Color(c.r, c.g, c.b, fa * (0.32 + float(phase-1)*0.14)))
	if phase >= 2:
		for i in 8:
			var wa := t * 1.8 + float(i) * (TAU / 8.0)
			var wr := 32.0 + sin(t * 4.0 + float(i)) * 4.0
			draw_circle(Vector2(cos(wa)*wr, sin(wa)*wr), 3.5, Color(c.r, c.g, c.b, 0.16 + p1 * 0.22))
