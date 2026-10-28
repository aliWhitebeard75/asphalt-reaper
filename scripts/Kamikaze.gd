extends "res://scripts/BaseEnemy.gd"

var exploded: bool = false

func setup() -> void:
	health = 100.0
	max_health = 1.0
	speed = 120.0
	mass = 0.7
	coin_value = 4
	color = Color(1.0, 0.1, 0.7)
	_sprite_type = "kamikaze"

func ai_update(_delta: float, player_pos: Vector2) -> void:
	var road_speed = main_ref.get_road_scroll_speed() if main_ref else 300.0
	var to_player = (player_pos - position).normalized()

	# Homing: x tracks player directly; y adds road_speed so it visually moves with the road
	# speed is already scaled at spawn — do NOT multiply by aggression (avoids double-scaling)
	velocity.x = to_player.x * speed
	velocity.y = road_speed * 0.35 + to_player.y * speed

	# Hard cap so late-game road_speed escalation doesn't make it invisible-fast
	velocity = velocity.limit_length(min(road_speed * 0.6 + speed, 650.0))

func _check_ram_player() -> void:
	if main_ref == null or exploded:
		return
	var player = main_ref.get_node_or_null("Player")
	if not player or not is_instance_valid(player):
		return
	if position.distance_to(player.position) < 42.0:
		exploded = true
		player.take_damage(50.0)
		if main_ref.has_method("spawn_explosion"):
			main_ref.spawn_explosion(position, Color(1.0, 0.4, 0.0))
		die()

func _draw() -> void:
	var t  := Time.get_ticks_msec() / 150.0
	var pulse := (sin(t * 2.2) + 1.0) * 0.5
	var c  := Color(1.0, 0.08 + pulse * 0.45, 0.55 - pulse * 0.30)
	var dark  := Color(0.30, 0.04, 0.15)
	var rust  := Color(0.52, 0.18, 0.05)
	var weld  := Color(0.80, 0.75, 0.10, 0.70)

	# Battered, asymmetric body (crumpled panels)
	draw_rect(Rect2(-14, -22, 30, 46), c)
	draw_rect(Rect2(-16,  -6,  4, 20), rust)   # crumpled left panel
	draw_rect(Rect2( 14,   0,  4, 14), dark)   # dented right rear
	# Cracked windshield
	draw_rect(Rect2(-10, -16, 21, 12), Color(0.25, 0.35, 0.55, 0.70))
	draw_rect(Rect2( -8, -15,  3,  3), Color(1.0, 1.0, 1.0, 0.18))
	# Crack lines on windshield
	draw_line(Vector2(-6, -16), Vector2(2, -4),  Color(0.0, 0.0, 0.0, 0.55), 1.0)
	draw_line(Vector2( 4, -16), Vector2(-2, -6), Color(0.0, 0.0, 0.0, 0.40), 1.0)
	# Roof (partially caved)
	draw_rect(Rect2( -8,  -4, 17, 13), dark)
	# Front — crumpled hood
	draw_rect(Rect2(-13, -26, 28,  5), rust)
	draw_rect(Rect2( -5, -24,  8,  5), dark)   # dent
	# Headlights (one broken)
	draw_circle(Vector2(-8, -24), 3.0, Color(1.0, 0.95, 0.75))
	draw_circle(Vector2( 8, -24), 3.0, Color(0.25, 0.18, 0.10))  # broken
	draw_line(Vector2(6, -26), Vector2(10, -22), Color(0.0, 0.0, 0.0, 0.80), 1.5)
	# Weld marks / battle scars
	draw_rect(Rect2(-3,  -5,  2, 12), weld)
	draw_rect(Rect2( 8,   4,  2,  8), weld)
	# Explosive glow underneath (danger warning)
	draw_circle(Vector2(0, 8), 10.0 + pulse * 4.0, Color(1.0, 0.40, 0.00, 0.18 + pulse * 0.18))
	draw_circle(Vector2(0, 8),  6.0,                Color(1.0, 0.80, 0.10, 0.25 + pulse * 0.30))
	# Rear (destroyed bumper)
	draw_rect(Rect2(-14, 22, 30,  4), rust)
	draw_rect(Rect2(  4, 23,  8,  2), dark)
	# Wheels (one slightly off-axis for damage feel)
	draw_circle(Vector2(-14, -12), 7.0, Color(0.10, 0.10, 0.12))
	draw_circle(Vector2(-14, -12), 4.0, Color(0.55, 0.50, 0.12))
	draw_circle(Vector2( 14, -12), 7.0, Color(0.10, 0.10, 0.12))
	draw_circle(Vector2( 14, -12), 4.0, Color(0.55, 0.50, 0.12))
	draw_circle(Vector2(-14,  14), 7.0, Color(0.10, 0.10, 0.12))
	draw_circle(Vector2(-14,  14), 4.0, Color(0.45, 0.40, 0.10))
	draw_circle(Vector2( 15,  15), 7.0, Color(0.10, 0.10, 0.12))  # slightly off
	draw_circle(Vector2( 15,  15), 4.0, Color(0.45, 0.40, 0.10))

	# Health bar
	var bar_w := 34.0
	var hp_ratio: float = clamp(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-bar_w / 2, -38, bar_w, 5), Color(0.3, 0.0, 0.0))
	draw_rect(Rect2(-bar_w / 2, -38, bar_w * hp_ratio, 5), Color(0.0, 0.9, 0.0))
