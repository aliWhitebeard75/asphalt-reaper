extends "res://scripts/BaseEnemy.gd"

var weave_timer: float = 0.0
var weave_dir: float = 1.0

func _ready() -> void:
	super._ready()
	weave_dir = 1.0 if randf() > 0.5 else -1.0

func setup() -> void:
	health = 50.0
	max_health = 25.0
	speed = 165.0
	mass = 0.6
	coin_value = 3
	color = Color(0.2, 0.9, 0.4)
	_sprite_type = "speeder"

func draw_car(c: Color) -> void:
	var dark   := Color(c.r * 0.38, c.g * 0.38, c.b * 0.38)
	var stripe := Color(1.0, 1.0, 1.0, 0.55)
	# Front splitter / pointed nose
	draw_rect(Rect2( -8, -28,  16,  6), dark)
	draw_rect(Rect2( -5, -32,  10,  6), c)
	# Narrow main body
	draw_rect(Rect2(-12, -24, 24, 48), c)
	# Side pods (aerodynamic)
	draw_rect(Rect2(-16,  -8, 5, 20), dark)
	draw_rect(Rect2( 11,  -8, 5, 20), dark)
	# Racing stripe down center
	draw_rect(Rect2( -2, -32,  4, 56), stripe)
	# Open cockpit canopy
	draw_rect(Rect2( -7, -18, 14,  9), Color(c.r*0.25, c.g*0.45, c.b*0.70, 0.85))
	draw_rect(Rect2( -5, -17,  4,  3), Color(1.0, 1.0, 1.0, 0.30))
	# Headlights (round, racing style)
	draw_circle(Vector2(-7, -29), 3.0, Color(1.0, 0.98, 0.78))
	draw_circle(Vector2( 7, -29), 3.0, Color(1.0, 0.98, 0.78))
	# Rear wing / diffuser
	draw_rect(Rect2(-14,  22, 28,  3), dark)
	draw_rect(Rect2(-16,  20, 32,  3), Color(0.18, 0.18, 0.22))  # wing
	# Taillights
	draw_rect(Rect2(-12,  23,  5,  2), Color(1.0, 0.10, 0.10))
	draw_rect(Rect2(  7,  23,  5,  2), Color(1.0, 0.10, 0.10))
	# Wheels (narrow, tall)
	for wx in [-12, 12]:
		for wy in [-14, 16]:
			draw_circle(Vector2(wx, wy), 6.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 3.5, Color(c.r*0.55, c.g*0.75, 0.12))
			draw_circle(Vector2(wx, wy), 1.5, Color(0.18, 0.18, 0.20))

func ai_update(delta: float, player_pos: Vector2) -> void:
	var road_speed = main_ref.get_road_scroll_speed() if main_ref else 300.0

	weave_timer -= delta
	if weave_timer <= 0.0:
		# Faster direction changes as aggression increases, but capped
		weave_timer = max(0.25, 0.6 - aggression * 0.07) + randf() * 0.2
		weave_dir = -weave_dir

	# vx: flat weave — NO aggression compound to prevent horizontal explosion at high difficulty
	var vx = weave_dir * 110.0
	# Slight nudge toward player's X so Speeder actually threatens the player
	vx += sign(player_pos.x - position.x) * 25.0

	# Hard bounds — bounce before going off-road
	if position.x < 80.0:
		weave_dir = 1.0
	if position.x > 400.0:
		weave_dir = -1.0

	# Avoid tanks: if a tank is close ahead in the same X zone, steer away
	if main_ref:
		var enemies = main_ref.get_node_or_null("Enemies")
		if enemies:
			for e in enemies.get_children():
				if not is_instance_valid(e) or e.dead or not e.is_tank:
					continue
				if abs(e.position.x - position.x) < 48.0 and e.position.y < position.y + 80.0 and e.position.y > position.y - 160.0:
					# Tank is in our path — steer hard away
					weave_dir = sign(position.x - e.position.x)
					if weave_dir == 0.0:
						weave_dir = 1.0
					break

	# vy: speed already scaled at spawn; road_speed keeps it visually aligned with the road
	var vy = road_speed * 0.4 + speed * 0.8

	velocity = Vector2(vx, vy)
