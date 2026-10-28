extends "res://scripts/BaseEnemy.gd"

var _avoid_timer: float = 0.0   # cooldown before next proactive lane switch

func setup() -> void:
	health     = 350.0
	max_health = 350.0
	speed      = 60.0
	mass       = 3.0
	coin_value = 8
	color      = Color(0.4, 0.4, 0.5)
	is_tank    = true
	_sprite_type = "tank"

func ai_update(_delta: float, _player_pos: Vector2) -> void:
	var road_speed: float = main_ref.get_road_scroll_speed() if main_ref else 300.0
	bdodge_timer = -1.0   # suppress BaseEnemy lateral dodge

	_avoid_timer = maxf(0.0, _avoid_timer - _delta)

	# Proactively move to a different lane when we are about to run into the player.
	# This prevents the tank from parking on top of them and pushing them off-screen.
	if main_ref and _avoid_timer <= 0.0:
		var same_x: bool = abs(position.x - _player_pos.x) < 55.0
		var closing: bool = _player_pos.y > position.y and (_player_pos.y - position.y) < 220.0
		if same_x and closing:
			var best_li: int = -1
			var best_dx: float = 9999.0
			for li in 3:
				var lx: float = main_ref.LANE_X[li]
				if abs(lx - _player_pos.x) < 55.0:
					continue   # skip player's current lane
				var dx: float = abs(lx - position.x)
				if dx < best_dx:
					best_dx = dx
					best_li = li
			if best_li >= 0:
				lane = best_li
				_avoid_timer = 2.5   # don't re-check until well clear

	# Steer smoothly toward target lane X, then drive straight down
	var target_x: float = main_ref.LANE_X[lane] if main_ref else position.x
	var vx: float = clamp(target_x - position.x, -200.0, 200.0)
	velocity = Vector2(vx, speed + road_speed * 0.2)

func _check_bullet_dodge() -> void:
	pass   # tanks never dodge — they own their lane

# ── Invincibility ─────────────────────────────────────────────────────────────
func take_damage(_amount: float) -> void:
	pass  # Tank is invincible — immune to all damage

func _check_ram_player() -> void:
	if main_ref == null or ram_cooldown > 0.0:
		return
	var player = main_ref.get_node_or_null("Player")
	if not player or not is_instance_valid(player):
		return
	if position.distance_to(player.position) < 46.0:
		if not player.is_boosting:
			var ram_dmg = 10.5 * mass
			if main_ref.get_road_scroll_speed() > 400:
				ram_dmg *= 1.3
			player.take_damage(ram_dmg)
		# Immediately switch to a lane away from the player so we don't pile on top
		var player_lane: int = player.current_lane
		var opts: Array = [0, 1, 2]
		opts.erase(player_lane)
		lane = opts[randi() % opts.size()]
		var target_x: float = main_ref.LANE_X[lane]
		var dx: float = target_x - position.x
		# Strong lateral burst — tank steers fully into the new lane
		knockback_vel   = Vector2(sign(dx) * 480.0, 60.0)
		knockback_timer = 0.40
		ram_cooldown    = 1.2

# ── Drawing ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	var t     := Time.get_ticks_msec() / 1000.0
	var pulse := (sin(t * 3.5) + 1.0) * 0.5
	var c     := color

	# Invincibility field (always visible, behind everything)
	draw_rect(Rect2(-29, -38, 58, 76), Color(0.35, 0.65, 1.0, 0.12 + pulse * 0.14))
	draw_arc(Vector2(0, 0), 36, 0, TAU, 48, Color(0.50, 0.80, 1.0, 0.18 + pulse * 0.22), 1.5)

	if _has_sprite():
		# ── Sprite body (invincibility field drawn above, hull sprite here) ──
		var reg = get_node_or_null("/root/SpriteRegistry")
		var sf: float = 0.022
		if reg:
			sf = float(reg.get_scale("tank"))
		var ts: Vector2 = _enemy_tex.get_size()
		draw_set_transform(Vector2.ZERO, -PI / 2.0, Vector2(sf, sf))
		draw_texture(_enemy_tex, Vector2(-ts.x * 0.5, -ts.y * 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return   # skip procedural hull; field already drawn above

	var dark  := Color(c.r * 0.40, c.g * 0.40, c.b * 0.42)
	var plate := Color(c.r * 0.68, c.g * 0.68, c.b * 0.72)
	var chrome := Color(0.72, 0.72, 0.80)

	# Dual rear exhausts
	draw_rect(Rect2(-20, 30,  6, 10), dark)
	draw_rect(Rect2( 14, 30,  6, 10), dark)
	draw_circle(Vector2(-17, 40), 3.5, Color(1.0, 0.45, 0.05, 0.55 + pulse * 0.40))
	draw_circle(Vector2( 17, 40), 3.5, Color(1.0, 0.45, 0.05, 0.55 + pulse * 0.40))

	# Chunky wheels (6 total — dual rear axle feel)
	for wx in [-24.0, 24.0]:
		for wy in [-18.0, 8.0, 26.0]:
			draw_circle(Vector2(wx, wy), 8.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 5.0, Color(0.55, 0.55, 0.60))
			draw_circle(Vector2(wx, wy), 2.5, Color(0.20, 0.20, 0.24))

	# Main hull
	draw_rect(Rect2(-22, -32, 44, 64), c)
	# Side armour skirts
	draw_rect(Rect2(-26, -16, 5, 36), dark)
	draw_rect(Rect2( 21, -16, 5, 36), dark)

	# Front angled armour wedge
	draw_rect(Rect2(-22, -38, 44, 8), plate)
	draw_rect(Rect2(-18, -36, 36, 5), chrome)

	# Front grille with ram bar
	draw_rect(Rect2(-18, -30, 36, 6), dark)
	for gx in [-12, -4, 4, 12]:
		draw_rect(Rect2(gx, -30, 3, 6), Color(0.04, 0.04, 0.06))

	# Headlights (wide armoured units)
	draw_rect(Rect2(-20, -32, 9, 4), Color(1.0, 0.95, 0.75))
	draw_rect(Rect2( 11, -32, 9, 4), Color(1.0, 0.95, 0.75))
	draw_rect(Rect2(-19, -32, 3, 4), Color(1.0, 1.0, 1.0))
	draw_rect(Rect2( 16, -32, 3, 4), Color(1.0, 1.0, 1.0))

	# Armoured windshield slit
	draw_rect(Rect2(-14, -22, 28,  8), Color(c.r*0.2, c.g*0.25, c.b*0.5, 0.88))
	draw_rect(Rect2(-12, -21,  8,  3), Color(1.0, 1.0, 1.0, 0.14))
	# Armour plate above windshield
	draw_rect(Rect2(-18, -24, 36,  3), plate)

	# Roof turret / weapon mount
	draw_rect(Rect2( -8,  -8, 16, 14), dark)
	draw_rect(Rect2( -5,  -6, 10, 10), Color(0.18, 0.18, 0.22))
	draw_circle(Vector2(0, -2), 5.0, dark)
	draw_rect(Rect2( -2, -12,  4, 10), dark)  # barrel
	draw_rect(Rect2( -1, -14,  2,  4), chrome)

	# Rear armour plate
	draw_rect(Rect2(-22, 30, 44,  6), plate)
	draw_rect(Rect2(-18, 31, 36,  3), chrome)
	# Taillights
	draw_circle(Vector2(-15, 32), 3.0, Color(0.9, 0.08, 0.08))
	draw_circle(Vector2( 15, 32), 3.0, Color(0.9, 0.08, 0.08))

	# Rivet / bolt detail on hull
	for bx in [-17.0, -7.0, 7.0, 17.0]:
		draw_circle(Vector2(bx, -28), 1.8, chrome)
		draw_circle(Vector2(bx,  28), 1.8, chrome)
	for by in [-20.0, 0.0, 18.0]:
		draw_circle(Vector2(-20, by), 1.8, chrome)
		draw_circle(Vector2( 20, by), 1.8, chrome)

	# No HP bar — tanks are invincible; showing one would mislead players
