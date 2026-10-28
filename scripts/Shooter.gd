extends "res://scripts/BaseEnemy.gd"

var shoot_timer: float = 0.0
var base_shoot_interval: float = 1.33
var preferred_distance: float = 250.0

# Lane-dodge state
var dodge_timer: float = 0.0   # fires on first frame (0.0 - delta < 0)
var dodge_interval: float = 1.4
var target_lane: int = 1       # updated by dodge logic each interval

func setup() -> void:
	health = 85.0
	max_health = 25.0
	speed = 64.0
	mass = 0.8
	coin_value = 3
	color = Color(0.9, 0.5, 0.1)
	_sprite_type = "shooter"

func draw_car(c: Color) -> void:
	var dark   := Color(c.r * 0.40, c.g * 0.40, c.b * 0.40)
	var bright := c.lightened(0.30)
	# Narrow pointed nose
	draw_rect(Rect2(-11, -26, 22, 10), dark)
	draw_rect(Rect2( -7, -28, 14,  4), c)
	# Main body — sleek, angular
	draw_rect(Rect2(-14, -18, 28, 42), c)
	# Side accent strakes
	draw_rect(Rect2(-18, -10, 5, 20), dark)
	draw_rect(Rect2( 13, -10, 5, 20), dark)
	# Windshield — narrow and raked
	draw_rect(Rect2(-10, -18, 20, 11), Color(c.r*0.2, c.g*0.3, c.b*0.6, 0.88))
	draw_rect(Rect2( -8, -17,  5,  3), Color(1.0, 1.0, 1.0, 0.25))
	# Roof-mounted targeting sensor
	draw_rect(Rect2( -5,  -7, 10,  8), dark)
	draw_circle(Vector2(0, -3), 3.5, Color(c.r*0.3, c.g*0.3, 0.05))
	draw_circle(Vector2(0, -3), 2.0, Color(1.0, 0.65, 0.10, 0.90))
	# Hood center stripe
	draw_rect(Rect2( -2, -26,  4, 10), bright)
	# Front headlights (sharp triangular feel via small rects)
	draw_rect(Rect2(-13, -25,  7,  3), Color(1.0, 0.95, 0.70))
	draw_rect(Rect2(  6, -25,  7,  3), Color(1.0, 0.95, 0.70))
	# Rear diffuser
	draw_rect(Rect2(-14,  22, 28,  5), dark)
	draw_rect(Rect2(-11,  23,  5,  3), Color(0.9, 0.1, 0.1))
	draw_rect(Rect2(  6,  23,  5,  3), Color(0.9, 0.1, 0.1))
	# Wheels
	for wx in [-14, 14]:
		for wy in [-12, 14]:
			draw_circle(Vector2(wx, wy), 6.5, Color(0.11, 0.11, 0.14))
			draw_circle(Vector2(wx, wy), 4.0, Color(c.r*0.6, c.g*0.5, 0.15))
			draw_circle(Vector2(wx, wy), 1.8, Color(0.20, 0.20, 0.22))

func ai_update(delta: float, player_pos: Vector2) -> void:
	var road_speed = main_ref.get_road_scroll_speed() if main_ref else 300.0

	# Periodically change lanes, always avoiding the player's current lane
	dodge_timer -= delta
	if dodge_timer <= 0.0:
		dodge_timer = max(0.4, dodge_interval - aggression * 0.08) + randf() * 0.3

		var player_lane = 1
		if main_ref:
			var p = main_ref.get_node_or_null("Player")
			if p and is_instance_valid(p):
				player_lane = p.current_lane

		# Options: any lane except player's and any lane a tank occupies
		var options: Array = [0, 1, 2]
		options.erase(player_lane)
		# Filter out tank lanes; keep at least one fallback
		var safe: Array = options.filter(func(l): return not _tank_in_lane(l))
		if safe.size() > 0:
			options = safe
		if options.size() > 1:
			options.erase(target_lane)  # try to actually move, not stay put
		if options.size() > 0:
			target_lane = options[randi() % options.size()]

	# Slide toward target lane
	var tx: float = main_ref.LANE_X[target_lane] if main_ref else position.x
	var dx = tx - position.x
	var vx = sign(dx) * min(abs(dx) * 3.0, 130.0) * aggression

	# Maintain preferred vertical distance from player (stay back and shoot)
	# road_speed factor keeps enemy visually aligned with road scroll at all difficulty levels
	var dy = position.y - player_pos.y
	var vy: float
	if dy < preferred_distance - 20:
		# Too close — fall back with the road
		vy = road_speed * 0.45 + speed * 0.5
	elif dy > preferred_distance + 20:
		# Too far — advance toward preferred distance
		vy = road_speed * 0.2 + speed * 0.3
	else:
		# Hold position
		vy = road_speed * 0.35

	velocity = Vector2(vx, vy)

	# Fire at player when in range
	shoot_timer -= delta
	var effective_interval = base_shoot_interval / aggression
	if shoot_timer <= 0.0 and position.distance_to(player_pos) < 380.0:
		shoot_timer = effective_interval
		emit_signal("shot_fired")
