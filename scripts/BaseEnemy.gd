extends CharacterBody2D

signal died
@warning_ignore("unused_signal")
signal shot_fired

# ─── Base stats (overridden by subclasses) ────────────────────────────────────
var health: float = 60.0
var max_health: float = 15.0
var speed: float = 120.0
var mass: float = 1.0
var coin_value: int = 2
var color: Color = Color(1.0, 0.3, 0.3)

var lane: int = 1
var main_ref = null
var dead: bool = false
var aggression: float = 1.0
var is_boss: bool = false
var is_tank: bool = false

# ─── Sprite (set by subclass via _sprite_type in setup()) ────────────────────
var _sprite_type: String = ""    # "grunt" | "speeder" | "kamikaze" | "shooter" | "tank" | "boss"
var _enemy_tex: Texture2D = null # null → procedural draw_car() is used

# ─── Ram state ────────────────────────────────────────────────────────────────
var ram_cooldown: float = 0.0
var knockback_timer: float = 0.0
var knockback_vel: Vector2 = Vector2.ZERO

# ─── Hit flash ────────────────────────────────────────────────────────────────
var hit_flash_timer: float = 0.0

# ─── Bullet dodge ─────────────────────────────────────────────────────────────
var bdodge_timer: float = 0.0       # how long the lateral dodge impulse lasts
var bdodge_dir_x: float = 0.0       # +1 or -1
var bdodge_cooldown: float = 0.0    # prevents re-rolling every frame
const DODGE_SPEED: float    = 260.0
const DODGE_DURATION: float = 0.20
const DODGE_COOLDOWN: float = 1.4

func _ready() -> void:
	max_health = health
	setup()   # subclass sets _sprite_type here
	_load_enemy_tex()
	queue_redraw()

func _load_enemy_tex() -> void:
	if _sprite_type.is_empty(): return
	var reg = get_node_or_null("/root/SpriteRegistry")
	if reg == null: return
	if _sprite_type == "boss":
		var boss_num: int = get("boss_number") if get("boss_number") != null else 1
		_enemy_tex = reg.get_boss_texture(boss_num)
	else:
		_enemy_tex = reg.get_enemy_texture(_sprite_type)

func _has_sprite() -> bool:
	return _enemy_tex != null

func setup() -> void:
	pass  # overridden by subclasses

func main_update(delta: float, player_pos: Vector2) -> void:
	if dead:
		return
	ram_cooldown     -= delta
	knockback_timer  -= delta
	bdodge_timer     -= delta
	bdodge_cooldown  -= delta
	hit_flash_timer  -= delta
	if hit_flash_timer > 0.0:
		queue_redraw()

	if knockback_timer > 0.0:
		velocity = knockback_vel
	else:
		ai_update(delta, player_pos)

	# Bullet-dodge lateral impulse added on top of AI velocity
	if bdodge_timer > 0.0:
		velocity.x += bdodge_dir_x * DODGE_SPEED
	elif bdodge_cooldown <= 0.0:
		_check_bullet_dodge()

	move_and_slide()
	_separate_from_enemies()
	_check_ram_player()

func ai_update(_delta: float, _player_pos: Vector2) -> void:
	pass  # overridden

func _check_ram_player() -> void:
	if main_ref == null or ram_cooldown > 0.0:
		return
	var player = main_ref.get_node_or_null("Player")
	if not player or not is_instance_valid(player):
		return
	if position.distance_to(player.position) < 38.0:
		if player.is_boosting:
			# Player rammed the enemy — apply player's ram damage to enemy only
			take_damage(player.get_ram_damage(mass))
			GameState.run_ram_kills += 1
		else:
			# Enemy rammed the player — apply enemy ram damage to player
			var ram_dmg = 10.5 * mass
			if main_ref.get_road_scroll_speed() > 400:
				ram_dmg *= 1.3
			player.take_damage(ram_dmg)
			take_damage(20.0)

		# Knock the enemy away either way
		var away = (position - player.position).normalized()
		knockback_vel   = away * 300.0
		knockback_timer = 0.5
		ram_cooldown    = 1.2

func _check_bullet_dodge() -> void:
	if not main_ref or dead or is_boss:
		return
	var bullets = main_ref.get_node_or_null("Bullets")
	if not bullets:
		return
	for bullet in bullets.get_children():
		if not is_instance_valid(bullet) or not bullet.is_player_bullet:
			continue
		var to_self: Vector2 = position - bullet.position
		if to_self.length() > 240.0:
			continue
		# Check if bullet direction aims within ~40° of this enemy
		if bullet.direction.dot(to_self.normalized()) > 0.75:
			if randf() < 0.25:
				# Dodge! Pick a direction, bias away from road edges
				bdodge_dir_x = 1.0 if randf() < 0.5 else -1.0
				if position.x < 140.0:
					bdodge_dir_x =  1.0
				elif position.x > 340.0:
					bdodge_dir_x = -1.0
				bdodge_timer    = DODGE_DURATION
				bdodge_cooldown = DODGE_COOLDOWN
			else:
				# Missed the roll — short cooldown before next check
				bdodge_cooldown = 0.45
			break   # only react to one bullet per check

# Returns true if any living tank occupies the given lane (within 55 px of its centre X)
func _tank_in_lane(lane_idx: int) -> bool:
	if not main_ref:
		return false
	var enemies = main_ref.get_node_or_null("Enemies")
	if not enemies:
		return false
	var lx: float = main_ref.LANE_X[lane_idx]
	for e in enemies.get_children():
		if e == self or not is_instance_valid(e) or e.dead:
			continue
		if e.is_tank and abs(e.position.x - lx) < 55.0:
			return true
	return false

func _separate_from_enemies() -> void:
	if not main_ref or dead:
		return
	var enemies = main_ref.get_node_or_null("Enemies")
	if not enemies:
		return
	const SEP: float = 44.0   # minimum centre-to-centre distance
	for other in enemies.get_children():
		if other == self or not is_instance_valid(other) or other.dead:
			continue
		var d: float = position.distance_to(other.position)
		if d < SEP and d > 0.5:
			# Push this enemy away — split the overlap 50/50 so both move
			position += (position - other.position).normalized() * (SEP - d) * 0.5

func take_damage(amount: float) -> void:
	if dead:
		return
	health -= amount
	hit_flash_timer = 0.14
	queue_redraw()
	if health <= 0.0:
		health = 0.0
		die()

func die() -> void:
	dead = true
	emit_signal("died")
	queue_free()

func _draw() -> void:
	var draw_col := color
	if hit_flash_timer > 0.0:
		var ratio: float = clamp(hit_flash_timer / 0.14, 0.0, 1.0)
		draw_col = color.lerp(Color.WHITE, ratio * 0.82)

	if _has_sprite():
		# ── Sprite body ──────────────────────────────────────────────────────
		var reg = get_node_or_null("/root/SpriteRegistry")
		var entity_kind: String
		if is_tank:
			entity_kind = "tank"
		elif is_boss:
			entity_kind = "boss"
		else:
			entity_kind = "enemy"
		var sf: float = 0.020
		if reg:
			sf = float(reg.get_scale(entity_kind))
		var ts: Vector2 = _enemy_tex.get_size()
		var mod: Color = draw_col
		if hit_flash_timer > 0.0:
			mod = draw_col.lerp(Color.WHITE, 0.65)
		draw_set_transform(Vector2.ZERO, -PI / 2.0, Vector2(sf, sf))
		draw_texture(_enemy_tex, Vector2(-ts.x * 0.5, -ts.y * 0.5), mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_car(draw_col)

	# ── Hit spark burst (radiates outward while flash is active)
	if hit_flash_timer > 0.0:
		var spark_t: float = 1.0 - clamp(hit_flash_timer / 0.14, 0.0, 1.0)
		var sa: float      = clamp(hit_flash_timer / 0.14, 0.0, 1.0) * 0.95
		for i in 7:
			var angle := float(i) / 7.0 * TAU
			var inner := 5.0 + spark_t * 4.0
			var outer := inner + spark_t * 22.0
			draw_line(
				Vector2(cos(angle) * inner, sin(angle) * inner),
				Vector2(cos(angle) * outer, sin(angle) * outer),
				Color(1.0, 0.88, 0.30, sa), 1.5
			)

	# ── Health bar above car ──────────────────────────────────────────────
	var bar_w := 34.0
	var hp_ratio: float = clamp(health / max_health, 0.0, 1.0)
	# Bar glow when enemy is near death
	if hp_ratio < 0.35:
		draw_rect(Rect2(-bar_w / 2 - 1, -39, bar_w + 2, 7), Color(1.0, 0.1, 0.1, 0.25))
	draw_rect(Rect2(-bar_w / 2, -38, bar_w, 5), Color(0.18, 0.02, 0.02))
	var bar_col := Color(0.0, 0.9, 0.0) if hp_ratio > 0.5 else (Color(1.0, 0.72, 0.0) if hp_ratio > 0.25 else Color(1.0, 0.10, 0.10))
	draw_rect(Rect2(-bar_w / 2, -38, bar_w * hp_ratio, 5), bar_col)

func draw_car(c: Color) -> void:
	var dark := Color(c.r * 0.45, c.g * 0.45, c.b * 0.45)
	var mid  := Color(c.r * 0.68, c.g * 0.68, c.b * 0.68)
	# Body
	draw_rect(Rect2(-15, -24, 30, 48), c)
	draw_rect(Rect2(-18,  -6, 5, 22), mid)
	draw_rect(Rect2( 13,  -6, 5, 22), mid)
	# Windshield
	draw_rect(Rect2(-10, -18, 20, 13), Color(c.r*0.35, c.g*0.5, c.b*0.8, 0.75))
	draw_rect(Rect2( -8, -17,  6,  4), Color(1.0, 1.0, 1.0, 0.22))
	# Roof
	draw_rect(Rect2( -8,  -5, 16, 14), dark)
	# Front bumper & lights
	draw_rect(Rect2(-15, -28, 30,  5), dark)
	draw_circle(Vector2(-9, -26), 3.0, Color(1.0, 0.95, 0.75))
	draw_circle(Vector2( 9, -26), 3.0, Color(1.0, 0.95, 0.75))
	# Rear bumper & taillights
	draw_rect(Rect2(-15, 22, 30,  4), dark)
	draw_circle(Vector2(-9, 23), 2.5, Color(0.9, 0.08, 0.08))
	draw_circle(Vector2( 9, 23), 2.5, Color(0.9, 0.08, 0.08))
	# Wheels
	for wx in [-15, 15]:
		for wy in [-14, 12]:
			draw_circle(Vector2(wx, wy), 6.0, Color(0.12, 0.12, 0.14))
			draw_circle(Vector2(wx, wy), 3.5, Color(0.65, 0.65, 0.70))
