extends "res://scripts/BaseEnemy.gd"

# Which side of the player to approach: 0 = left lane, 2 = right lane
var side_pref: int = 0
var target_lane: int = -1
var lane_reeval_timer: float = 0.0
const LANE_REEVAL_INTERVAL: float = 1.4  # re-pick target lane every ~1.4 seconds

func _ready() -> void:
	super._ready()
	side_pref = (randi() % 2) * 2  # 0 or 2

func setup() -> void:
	health = 120.0
	max_health = 30.0
	speed = 88.0
	mass = 1.2
	coin_value = 2
	color = Color(0.9, 0.2, 0.2)
	_sprite_type = "grunt"

func draw_car(c: Color) -> void:
	var dark  := Color(c.r * 0.42, c.g * 0.42, c.b * 0.42)
	var mid   := Color(c.r * 0.65, c.g * 0.65, c.b * 0.65)
	# Wide wheel arches (behind body)
	for wx in [-18, 18]:
		for wy in [-14, 14]:
			draw_circle(Vector2(wx, wy), 9.0, dark)
	# Main body — wide, low-slung
	draw_rect(Rect2(-18, -22, 36, 44), c)
	# Thick side panels / skirts
	draw_rect(Rect2(-22,  -8, 6, 24), mid)
	draw_rect(Rect2( 16,  -8, 6, 24), mid)
	# Hood scoop
	draw_rect(Rect2( -5, -22, 10, 10), dark)
	draw_rect(Rect2( -3, -21,  6,  7), Color(0.04, 0.04, 0.06))
	# Front bumper — thick chrome
	draw_rect(Rect2(-18, -26, 36,  5), Color(0.72, 0.72, 0.78))
	draw_rect(Rect2(-18, -27, 36,  2), Color(0.90, 0.90, 0.95))
	# Headlights — wide rectangular
	draw_rect(Rect2(-16, -25, 10, 4), Color(1.0, 0.96, 0.80))
	draw_rect(Rect2(  6, -25, 10, 4), Color(1.0, 0.96, 0.80))
	# Windshield
	draw_rect(Rect2(-12, -16, 24, 12), Color(c.r*0.3, c.g*0.3, c.b*0.55, 0.80))
	draw_rect(Rect2( -9, -15,  7,  4), Color(1.0, 1.0, 1.0, 0.20))
	# Cabin roof (lower, wide)
	draw_rect(Rect2(-11,  -4, 22, 14), dark)
	# Rear bumper & taillights
	draw_rect(Rect2(-18,  20, 36,  5), Color(0.72, 0.72, 0.78))
	draw_rect(Rect2(-16,  21, 12,  3), Color(0.92, 0.08, 0.08))
	draw_rect(Rect2(  4,  21, 12,  3), Color(0.92, 0.08, 0.08))
	# Wheels
	for wx in [-18, 18]:
		for wy in [-14, 14]:
			draw_circle(Vector2(wx, wy), 8.0, Color(0.10, 0.10, 0.12))
			draw_circle(Vector2(wx, wy), 5.0, Color(0.70, 0.70, 0.75))
			draw_circle(Vector2(wx, wy), 2.5, Color(0.25, 0.25, 0.28))

func ai_update(delta: float, player_pos: Vector2) -> void:
	var road_speed = main_ref.get_road_scroll_speed() if main_ref else 300.0

	# Re-evaluate target lane on first call and every LANE_REEVAL_INTERVAL seconds
	lane_reeval_timer -= delta
	if target_lane == -1 or lane_reeval_timer <= 0.0:
		lane_reeval_timer = LANE_REEVAL_INTERVAL
		var player_lane = 1
		if main_ref:
			var p = main_ref.get_node_or_null("Player")
			if p and is_instance_valid(p):
				player_lane = p.current_lane
		# Park in the lane beside the player (never the same lane, never a tank lane)
		var preferred: int
		if player_lane == 0:
			preferred = 1
		elif player_lane == 2:
			preferred = 1
		else:
			preferred = side_pref  # 0 or 2

		# If preferred lane has a tank, try the other non-player lanes
		if _tank_in_lane(preferred):
			var alts: Array = [0, 1, 2]
			alts.erase(player_lane)
			alts.erase(preferred)
			var safe: Array = alts.filter(func(l): return not _tank_in_lane(l))
			if safe.size() > 0:
				preferred = safe[randi() % safe.size()]
			# else: all lanes have tanks — stay in preferred (no safe option)
		target_lane = preferred

	# Slide toward locked target lane
	var target_x: float = main_ref.LANE_X[target_lane] if main_ref else position.x
	var dx = target_x - position.x
	var vx = sign(dx) * min(abs(dx) * 2.0, 110.0) * aggression

	# Match the player's Y level, then lunge sideways into the player
	var dy = player_pos.y - position.y
	var vy: float
	if abs(dy) > 25.0:
		vy = road_speed * 0.4 + sign(dy) * speed * 0.6
	else:
		# Side-by-side with player — ram!
		vx = sign(player_pos.x - position.x) * 180.0 * aggression
		vy = road_speed * 0.05

	velocity = Vector2(vx, vy)
