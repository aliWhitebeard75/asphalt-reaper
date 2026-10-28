extends Node2D

signal hit_target(bullet, target)

var direction: Vector2 = Vector2.UP
var speed: float = 550.0
var damage: float = 15.0
var is_player_bullet: bool = true
var is_ricochet: bool = false
var target_node = null  # set on ricochet bullets for mild homing
var bullet_color: Color = Color(1.0, 0.2, 0.2)
var bullet_size: float = 1.0
# New perk flags set by Main when the bullet is fired
var is_homing: bool = false
var is_boss_bullet: bool = false
var is_parry: bool = false       # parry return bullet — cyan visual
var pierce_remaining: int = 0
var _homing_nearest = null
var _homing_scan_t: float = 0.0
var _last_pierced = null       # enemy to skip after a pierce
var _pierce_skip_t: float = 0.0

func _process(delta: float) -> void:
	# Ricochet homing
	if is_ricochet and target_node and is_instance_valid(target_node):
		var to_target = (target_node.position - position).normalized()
		direction = direction.lerp(to_target, 0.18).normalized()

	# Pierce immunity countdown
	if _pierce_skip_t > 0.0:
		_pierce_skip_t -= delta
		if _pierce_skip_t <= 0.0:
			_last_pierced = null

	# Homing: player bullets → enemies; boss homing bullets → player
	if is_homing:
		_homing_scan_t -= delta
		if _homing_scan_t <= 0.0:
			_homing_scan_t = 0.15
			if is_player_bullet:
				_find_homing_target()   # finds nearest enemy
			else:
				# Phantom boss: home on player
				var main = get_parent().get_parent() if get_parent() else null
				_homing_nearest = main.get_node_or_null("Player") if main else null
		if _homing_nearest and is_instance_valid(_homing_nearest):
			var is_dead: Variant = _homing_nearest.get("dead")
			if not (is_dead == true):
				var to_t: Vector2 = (_homing_nearest.position - position).normalized()
				var lerp_speed: float = 3.0 if is_player_bullet else 3.5
				direction = direction.lerp(to_t, delta * lerp_speed).normalized()

	position += direction * speed * delta
	queue_redraw()
	_check_hits()

func _find_homing_target() -> void:
	var parent := get_parent()
	if not parent:
		return
	var main := parent.get_parent()
	if not main:
		return
	var enemies = main.get_node_or_null("Enemies")
	if not enemies:
		return
	var best_d := 9999.0
	_homing_nearest = null
	for e in enemies.get_children():
		if is_instance_valid(e) and not e.dead:
			var d := position.distance_to(e.position)
			if d < best_d:
				best_d = d
				_homing_nearest = e

func _check_hits() -> void:
	var parent = get_parent()
	if not parent:
		return

	var main = parent.get_parent()
	if not main:
		return

	if is_player_bullet:
		var enemies = main.get_node_or_null("Enemies")
		if enemies:
			# Ricochet bullets use a wider radius so homing can close the last gap
			var radius = 50.0 if is_ricochet else 30.0
			for e in enemies.get_children():
				if e == _last_pierced:
					continue
				if is_instance_valid(e) and not e.dead and position.distance_to(e.position) < radius:
					emit_signal("hit_target", self, e)
					return
	else:
		var player = main.get_node_or_null("Player")
		if player and is_instance_valid(player):
			if position.distance_to(player.position) < 30.0:
				emit_signal("hit_target", self, player)

func _draw() -> void:
	if is_parry:
		_draw_parry_bullet()
	elif is_player_bullet:
		if is_ricochet:
			_draw_ricochet_bullet()
		else:
			_draw_player_bullet()
	elif is_boss_bullet:
		_draw_boss_bullet()
	else:
		_draw_enemy_bullet()

# ── Player standard bullet — sleek yellow-white plasma bolt ───────────────────
func _draw_player_bullet() -> void:
	# Soft outer glow
	draw_circle(Vector2(0.0, -4.0), 11.0, Color(1.0, 0.95, 0.25, 0.10))
	# Fading tail (positive y = behind an upward-moving bullet)
	draw_polygon(
		PackedVector2Array([Vector2(-2.5, 3.0), Vector2(2.5, 3.0),
							Vector2(1.5, 30.0), Vector2(-1.5, 30.0)]),
		PackedColorArray([Color(1.0, 0.85, 0.10, 0.55), Color(1.0, 0.85, 0.10, 0.55),
						  Color(0.9, 0.40, 0.00, 0.00), Color(0.9, 0.40, 0.00, 0.00)])
	)
	# Elongated nose-cone body
	draw_polygon(
		PackedVector2Array([Vector2( 0.0, -16.0), Vector2( 3.5, -8.0),
							Vector2( 4.0,   2.0), Vector2( 0.0,  5.0),
							Vector2(-4.0,   2.0), Vector2(-3.5, -8.0)]),
		PackedColorArray([Color(1.00, 1.00, 0.85), Color(1.00, 0.95, 0.30),
						  Color(0.95, 0.75, 0.00), Color(0.85, 0.55, 0.00),
						  Color(0.95, 0.75, 0.00), Color(1.00, 0.95, 0.30)])
	)
	# White-hot core streak
	draw_line(Vector2(0.0, -14.0), Vector2(0.0, 2.0), Color(1.0, 1.0, 1.0, 0.75), 1.5)
	# Glowing tip
	draw_circle(Vector2(0.0, -15.0), 2.0, Color(1.0, 1.0, 1.0, 0.92))
	# Warm centre glow
	draw_circle(Vector2(0.0, -5.0), 3.5, Color(1.0, 1.0, 0.70, 0.40))

# ── Player ricochet bullet — wider orange-fire bolt with wing flares ──────────
func _draw_ricochet_bullet() -> void:
	# Outer glow
	draw_circle(Vector2(0.0, -4.0), 12.0, Color(1.0, 0.40, 0.00, 0.10))
	# Main tail
	draw_polygon(
		PackedVector2Array([Vector2(-3.0, 3.0), Vector2(3.0, 3.0),
							Vector2(2.0, 34.0), Vector2(-2.0, 34.0)]),
		PackedColorArray([Color(1.0, 0.50, 0.00, 0.65), Color(1.0, 0.50, 0.00, 0.65),
						  Color(0.8, 0.10, 0.00, 0.00), Color(0.8, 0.10, 0.00, 0.00)])
	)
	# Left wing flare
	draw_polygon(
		PackedVector2Array([Vector2(-4.0, -1.0), Vector2(-2.0,  4.0),
							Vector2(-8.0, 16.0), Vector2(-10.0, 11.0)]),
		PackedColorArray([Color(1.0, 0.60, 0.00, 0.50), Color(1.0, 0.40, 0.00, 0.40),
						  Color(0.8, 0.20, 0.00, 0.00), Color(0.7, 0.10, 0.00, 0.00)])
	)
	# Right wing flare
	draw_polygon(
		PackedVector2Array([Vector2( 4.0, -1.0), Vector2( 2.0,  4.0),
							Vector2( 8.0, 16.0), Vector2(10.0, 11.0)]),
		PackedColorArray([Color(1.0, 0.60, 0.00, 0.50), Color(1.0, 0.40, 0.00, 0.40),
						  Color(0.8, 0.20, 0.00, 0.00), Color(0.7, 0.10, 0.00, 0.00)])
	)
	# Wider aggressive body
	draw_polygon(
		PackedVector2Array([Vector2( 0.0, -17.0), Vector2( 4.0, -7.0),
							Vector2( 5.0,   2.0), Vector2( 0.0,  6.0),
							Vector2(-5.0,   2.0), Vector2(-4.0, -7.0)]),
		PackedColorArray([Color(1.00, 0.90, 0.60), Color(1.00, 0.55, 0.00),
						  Color(0.95, 0.35, 0.00), Color(0.85, 0.20, 0.00),
						  Color(0.95, 0.35, 0.00), Color(1.00, 0.55, 0.00)])
	)
	# Core streak
	draw_line(Vector2(0.0, -15.0), Vector2(0.0, 3.0), Color(1.0, 0.90, 0.50, 0.80), 1.5)
	# Glowing tip
	draw_circle(Vector2(0.0, -16.0), 2.5, Color(1.0, 0.90, 0.70, 0.95))
	draw_circle(Vector2(0.0,  -5.0), 4.0, Color(1.0, 0.55, 0.00, 0.35))

# ── Parry bullet — cyan energy lance ─────────────────────────────────────────
func _draw_parry_bullet() -> void:
	# Long cyan tail
	draw_polygon(
		PackedVector2Array([Vector2(-3.0, 5.0), Vector2(3.0, 5.0),
							Vector2(1.5, 46.0), Vector2(-1.5, 46.0)]),
		PackedColorArray([Color(0.10, 0.85, 1.0, 0.50), Color(0.10, 0.85, 1.0, 0.50),
						  Color(0.00, 0.50, 1.0, 0.00), Color(0.00, 0.50, 1.0, 0.00)])
	)
	# Orbital ring pulse
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 32, Color(0.00, 0.90, 1.0, 0.35), 2.0)
	# Elongated body
	draw_polygon(
		PackedVector2Array([Vector2( 0.0, -18.0), Vector2( 4.0, -8.0),
							Vector2( 5.0,   3.0), Vector2( 0.0,  7.0),
							Vector2(-5.0,   3.0), Vector2(-4.0, -8.0)]),
		PackedColorArray([Color(1.00, 1.00, 1.00), Color(0.30, 0.95, 1.00),
						  Color(0.00, 0.75, 1.00), Color(0.00, 0.55, 1.00),
						  Color(0.00, 0.75, 1.00), Color(0.30, 0.95, 1.00)])
	)
	# White-hot core
	draw_line(Vector2(0.0, -16.0), Vector2(0.0, 4.0), Color(1.0, 1.0, 1.0, 0.85), 2.0)
	# Pure white tip
	draw_circle(Vector2(0.0, -17.0), 2.5, Color(1.0, 1.0, 1.0, 1.00))
	# Cyan centre glow
	draw_circle(Vector2(0.0,  -4.0), 5.0, Color(0.40, 0.95, 1.0, 0.50))

# ── Enemy standard bullet — glowing diamond ───────────────────────────────────
func _draw_enemy_bullet() -> void:
	var s := bullet_size
	var c := bullet_color
	# Outer glow
	draw_circle(Vector2.ZERO, 8.0 * s, Color(c.r, c.g, c.b, 0.20))
	# Outer diamond
	draw_polygon(
		PackedVector2Array([Vector2(0.0, -9.0 * s), Vector2( 6.5 * s, 0.0),
							Vector2(0.0,  7.0 * s), Vector2(-6.5 * s, 0.0)]),
		PackedColorArray([c.lightened(0.35), c, c.darkened(0.25), c])
	)
	# Inner bright diamond
	draw_polygon(
		PackedVector2Array([Vector2(0.0, -5.0 * s), Vector2( 3.5 * s, 0.0),
							Vector2(0.0,  4.0 * s), Vector2(-3.5 * s, 0.0)]),
		PackedColorArray([Color(1.0, 1.0, 1.0, 0.75), Color(1.0, 1.0, 1.0, 0.50),
						  Color(c.r, c.g, c.b, 0.30),  Color(1.0, 1.0, 1.0, 0.50)])
	)
	# Bright core dot
	draw_circle(Vector2.ZERO, 2.0 * s, Color(1.0, 1.0, 1.0, 0.90))

# ── Boss bullet — 4-spike star with aura ─────────────────────────────────────
func _draw_boss_bullet() -> void:
	var s := bullet_size
	var c := bullet_color
	# Double aura
	draw_circle(Vector2.ZERO, 16.0 * s, Color(c.r, c.g, c.b, 0.12))
	draw_circle(Vector2.ZERO, 10.0 * s, Color(c.r, c.g, c.b, 0.24))
	# Four angular spikes
	for i in 4:
		var angle := PI * 0.5 * float(i)
		var tip    := Vector2(0.0, -13.0 * s).rotated(angle)
		var side_a := Vector2( 3.5 * s, -4.0 * s).rotated(angle)
		var side_b := Vector2(-3.5 * s, -4.0 * s).rotated(angle)
		draw_polygon(
			PackedVector2Array([tip, side_a, side_b]),
			PackedColorArray([c.lightened(0.55), c, c])
		)
	# Core diamond
	draw_polygon(
		PackedVector2Array([Vector2(0.0, -8.0 * s), Vector2( 8.0 * s, 0.0),
							Vector2(0.0,  8.0 * s), Vector2(-8.0 * s, 0.0)]),
		PackedColorArray([c.lightened(0.40), c, c.darkened(0.35), c])
	)
	# Outer ring
	draw_arc(Vector2.ZERO, 12.0 * s, 0.0, TAU, 32, Color(c.r, c.g, c.b, 0.60), 1.5)
	# White-hot centre
	draw_circle(Vector2.ZERO, 3.5 * s, Color(1.0, 1.0, 1.0, 0.95))
