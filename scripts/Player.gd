extends CharacterBody2D

signal died
signal shot_fired

# ─── Stats ────────────────────────────────────────────────────────────────────
var max_health: int = 100
var health: int = 100
var shield: float = 0.0
var max_shield: float = 50.0
var shield_active: bool = false
var shield_recharge_timer: float = 0.0

var weapon_damage: float = 15.0
var fire_rate: float = 0.12       # seconds between shots — rapid bullet hell
var fire_timer: float = 0.0

var boost_speed: float = 600.0
var normal_speed: float = 0.0
var is_boosting: bool = false
var invincible: bool = false
var boost_timer: float = 0.0
var boost_duration: float = 0.5
const BOOST_COOLDOWN: float = 4.0
var boost_cooldown: float = 0.0
var revival_timer: float = 0.0   # counts down after ad-continue revival; blocks damage
var _vfx_t: float = 0.0   # animation clock for VFX effects

# ─── Lane movement ────────────────────────────────────────────────────────────
const LANE_X: Array = [130.0, 240.0, 350.0]
var current_lane: int = 1
var target_x: float = 240.0
const LANE_SPEED: float = 1400.0   # faster = snappier lane switch feel
var lane_input_cooldown: float = 0.0

# ─── Perks ────────────────────────────────────────────────────────────────────
var has_lifesteal: bool    = false
var has_afterburner: bool  = false
var has_rapid_fire: bool   = false
var has_ram_fury: bool     = false
var has_magnet: bool       = false
var magnet_radius: float   = 100.0
# New perks
var has_homing: bool       = false
var has_piercing: bool     = false
var has_iron_skin: bool    = false
var has_nano_repair: bool  = false
var has_overload: bool     = false
var has_twin_barrels: bool = false
var has_adrenaline: bool   = false
var _overload_counter: int = 0
var _nano_repair_timer: float = 0.0
var _boost_cd_mult: float  = 1.0   # Turbo Engine reduces this

# ─── Sprite ───────────────────────────────────────────────────────────────────
var _skin_tex: Texture2D = null   # set from SpriteRegistry; null → procedural draw

# ─── Consumable state ─────────────────────────────────────────────────────────
var has_resurrection: bool = false
var field_medic_used: bool = false

# ─── Touch controls ───────────────────────────────────────────────────────────
var _touch_start: Vector2 = Vector2.ZERO
var _touch_id: int = -1
var _swipe_done: bool = false    # prevents boost firing after a drag-swipe
const SWIPE_THRESHOLD: float = 22.0   # lower = more reactive

# ─── References set by Main ───────────────────────────────────────────────────
var main_ref = null

func _ready() -> void:
	max_health = GameState.get_max_health()
	health = max_health
	normal_speed = 0.0  # forward speed handled by road scroll
	target_x = LANE_X[current_lane]
	position.x = target_x
	position.y = get_viewport_rect().size.y * 0.82

	# Sprite — look up texture for the active skin
	_refresh_skin_tex()

	# Starting weapon tier
	var tier = GameState.upgrades["starting_weapon"]
	weapon_damage = 16.5 + tier * 10.0

	# Apply run consumables
	if GameState.run_active_consumables.get("armor_plate", false):
		max_health += 50
		health = max_health
	if GameState.run_active_consumables.get("war_machine", false):
		weapon_damage *= 1.20
	if GameState.run_active_consumables.get("overdrive", false):
		apply_perk("Rapid Fire")
	has_resurrection = GameState.run_active_consumables.get("resurrection", false)

func _refresh_skin_tex() -> void:
	# Look up the texture for the currently active skin. Called once on ready.
	# Call again after GameState.set_active_skin() if you swap skins mid-session.
	var reg = get_node_or_null("/root/SpriteRegistry")
	if reg:
		_skin_tex = reg.get_skin_texture(GameState.active_skin)
	else:
		_skin_tex = null

func _physics_process(delta: float) -> void:
	if not is_instance_valid(self):
		return

	# Lane input
	lane_input_cooldown -= delta
	if lane_input_cooldown <= 0.0:
		if Input.is_action_just_pressed("move_left") and current_lane > 0:
			current_lane -= 1
			target_x = LANE_X[current_lane]
			lane_input_cooldown = 0.15
		elif Input.is_action_just_pressed("move_right") and current_lane < 2:
			current_lane += 1
			target_x = LANE_X[current_lane]
			lane_input_cooldown = 0.15

	# Smooth lane transition
	position.x = move_toward(position.x, target_x, LANE_SPEED * delta)

	# Revival invincibility countdown (granted after watching an ad)
	if revival_timer > 0.0:
		revival_timer = maxf(0.0, revival_timer - delta)
		queue_redraw()   # animate the revival glow

	# Boost
	boost_cooldown -= delta
	boost_timer -= delta
	if Input.is_action_just_pressed("boost") and boost_cooldown <= 0.0:
		is_boosting = true
		invincible = true
		boost_timer = boost_duration
		boost_cooldown = BOOST_COOLDOWN * _boost_cd_mult
		SFX.play_boost()
	if boost_timer <= 0.0:
		is_boosting = false
		invincible = false

	# Boost velocity: dash forward; drift back to default Y when not boosting
	if is_boosting:
		velocity.y = -boost_speed * 0.4
	else:
		velocity.y = 0.0

	# Auto-fire
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = fire_rate
		emit_signal("shot_fired")

	# Shield recharge — runs whenever player owns the perk, not just while active
	if GameState.has_perk("Shield Bubble"):
		if not shield_active:
			# Count down the post-break delay before recharge begins
			shield_recharge_timer -= delta
			if shield_recharge_timer <= 0.0:
				shield = minf(shield + 20.0 * GameState.get_shield_recharge_rate() * delta, max_shield)
				if shield >= max_shield:
					shield_active = true  # re-enable blocking only when fully recharged

	# Magnet: pull nearby coins
	if has_magnet and main_ref:
		_pull_coins()

	# Nano Repair: +2 HP every 3 s
	if has_nano_repair and health < max_health:
		_nano_repair_timer -= delta
		if _nano_repair_timer <= 0.0:
			_nano_repair_timer = 3.0
			heal(2)

	move_and_slide()

	# Hard-clamp to road bounds so enemies can't push player off-screen
	var screen_h := get_viewport_rect().size.y
	position.x = clamp(position.x, 75.0, 405.0)
	position.y = clamp(position.y, 80.0, screen_h - 34.0)
	# Keep target in sync so lane snapping doesn't fight the clamp
	target_x = clamp(target_x, 75.0, 405.0)

	# Boost: kill nearby enemies instantly
	if is_boosting and main_ref:
		_boost_rampage()

	# Gradually return to default Y position when not boosting
	if not is_boosting:
		position.y = move_toward(position.y, screen_h * 0.82, 200.0 * delta)

	_vfx_t += delta

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_id    = event.index
			_swipe_done  = false
		elif event.index == _touch_id:
			_touch_id = -1
			# On lift: only boost if no swipe gesture was triggered during drag
			if not _swipe_done and boost_cooldown <= 0.0:
				is_boosting    = true
				invincible     = true
				boost_timer    = boost_duration
				boost_cooldown = BOOST_COOLDOWN * _boost_cd_mult
				SFX.play_boost()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		# Detect swipe early — during drag, not on lift — for instant response
		if not _swipe_done:
			var dx: float = event.position.x - _touch_start.x
			if abs(dx) > SWIPE_THRESHOLD and lane_input_cooldown <= 0.0:
				_swipe_done = true
				if dx < 0 and current_lane > 0:
					current_lane -= 1
					target_x = LANE_X[current_lane]
					lane_input_cooldown = 0.15
				elif dx > 0 and current_lane < 2:
					current_lane += 1
					target_x = LANE_X[current_lane]
					lane_input_cooldown = 0.15

func _boost_rampage() -> void:
	var enemies_node = main_ref.get_node_or_null("Enemies")
	if not enemies_node:
		return
	for enemy in enemies_node.get_children():
		if is_instance_valid(enemy) and not enemy.dead:
			if enemy.position.distance_to(position) < 130.0:
				# Bosses take a fixed hit rather than an instant kill
				var dmg: float = 40.0 if enemy.is_boss else 99999.0
				if has_ram_fury:
					dmg = 60.0 if enemy.is_boss else 99999.0
				enemy.take_damage(dmg)

func _pull_coins() -> void:
	var coins_node = main_ref.get_node_or_null("Coins")
	if not coins_node:
		return
	for coin in coins_node.get_children():
		if coin.position.distance_to(position) < magnet_radius:
			coin.position = coin.position.move_toward(position, 300.0 * get_process_delta_time())

func take_damage(amount: float) -> void:
	if invincible or revival_timer > 0.0:
		return
	if shield > 0.0 and shield_active:
		var absorbed = min(shield, amount)
		shield -= absorbed
		amount -= absorbed
		if shield <= 0.0:
			shield = 0.0
			shield_active = false
			shield_recharge_timer = 3.0  # 3-second delay before recharge starts

	if has_iron_skin:
		amount *= 0.80
	if amount > 0:
		health = maxi(health - int(amount), 0)
		if main_ref:
			main_ref.hud.update_health(health, max_health)

		# Field Medic: auto-heal once when HP drops below 25%
		if not field_medic_used and health > 0 and health <= int(max_health * 0.25):
			if GameState.run_active_consumables.get("field_medic", false):
				field_medic_used = true
				heal(25)

		if health <= 0:
			# Resurrection: revive once with 40 HP
			if has_resurrection:
				has_resurrection = false
				health = 40
				if main_ref:
					main_ref.hud.update_health(health, max_health)
				return
			health = 0
			emit_signal("died")

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	if main_ref:
		main_ref.hud.update_health(health, max_health)

func get_current_speed() -> float:
	if is_boosting:
		return boost_speed
	if main_ref:
		return main_ref.get_road_scroll_speed()
	return 300.0

# Called by Main when firing — handles Overload and Adrenaline
func consume_shot_damage() -> float:
	var dmg := weapon_damage
	if has_overload:
		_overload_counter += 1
		if _overload_counter >= 10:
			_overload_counter = 0
			dmg *= 3.0
	if has_adrenaline and health <= int(max_health * 0.25):
		dmg *= 2.0
	return dmg

func apply_perk(perk_name: String) -> void:
	match perk_name:
		"Rapid Fire":
			has_rapid_fire = true
			fire_rate = max(fire_rate * 0.80, 0.08)
		"Afterburner":
			has_afterburner = true
			boost_speed = 720.0
			boost_duration = 0.70
		"Shield Bubble":
			shield_active = true
			shield = max_shield
		"Lifesteal":
			has_lifesteal = true
		"Ram Fury":
			has_ram_fury = true
		"Magnet Aura":
			has_magnet = true
			magnet_radius = 220.0
		"Double Coins":
			pass  # handled in Main via GameState
		"Ricochet Shots":
			pass  # handled in Main bullet logic
		"Chain Explosion":
			pass  # handled in Main on enemy death
		# ── New perks ────────────────────────────────────────────────────────────
		"Homing Shots":
			has_homing = true
		"Explosive Rounds":
			pass  # handled in Main on bullet hit
		"Piercing Shot":
			has_piercing = true
		"Overload":
			has_overload = true
			_overload_counter = 0
		"Twin Barrels":
			has_twin_barrels = true
		"Adrenaline":
			has_adrenaline = true
		"Iron Skin":
			has_iron_skin = true
		"Nano Repair":
			has_nano_repair = true
			_nano_repair_timer = 3.0
		"Battle Hardened":
			max_health += 40
			health = mini(health + 40, max_health)
			if main_ref:
				main_ref.hud.update_health(health, max_health)
		"Scavenger":
			pass  # handled in Main on coin collect
		"Turbo Engine":
			_boost_cd_mult = 0.65
		"Lucky Strike":
			pass  # handled in Main on enemy death
		"Coin Rush":
			pass  # handled in Main on enemy death
		"Nemesis":
			pass  # handled in Main on bullet hit
		"Executioner":
			pass  # handled in Main on boss death

func unapply_perk(perk_name: String) -> void:
	match perk_name:
		"Lifesteal":       has_lifesteal   = false
		"Ram Fury":        has_ram_fury    = false
		"Magnet Aura":     has_magnet      = false;  magnet_radius = 100.0
		"Shield Bubble":   shield_active   = false;  shield = 0.0
		"Afterburner":     has_afterburner = false; boost_speed = 600.0; boost_duration = 0.5
		"Rapid Fire":      has_rapid_fire  = false; fire_rate = 0.12
		"Homing Shots":    has_homing      = false
		"Piercing Shot":   has_piercing    = false
		"Overload":        has_overload    = false;  _overload_counter = 0
		"Twin Barrels":    has_twin_barrels = false
		"Adrenaline":      has_adrenaline  = false
		"Iron Skin":       has_iron_skin   = false
		"Nano Repair":     has_nano_repair = false
		"Battle Hardened": max_health = maxi(max_health - 40, 10)
		"Turbo Engine":    _boost_cd_mult  = 1.0
		_: pass
	queue_redraw()

func get_ram_damage(enemy_mass: float) -> float:
	var speed = get_current_speed()
	var dmg = speed * enemy_mass * 0.05
	if has_ram_fury:
		dmg *= 1.5
	return dmg

func _draw() -> void:
	# ── Sprite body (replaces procedural car when a texture is assigned) ─────
	if _skin_tex != null:
		var reg = get_node_or_null("/root/SpriteRegistry")
		var sf: float = 0.025
		if reg:
			sf = float(reg.get_scale("player"))
		var ts: Vector2 = _skin_tex.get_size()
		# Rotate –90° so a landscape sprite (car facing right) faces up in-game
		draw_set_transform(Vector2.ZERO, -PI / 2.0, Vector2(sf, sf))
		draw_texture(_skin_tex, Vector2(-ts.x * 0.5, -ts.y * 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# ── Procedural car body (used when no sprite is assigned) ────────────
		var col: Color = GameState.get_skin_color()
		if is_boosting:
			col = Color(1.0, 0.55, 0.05)
		var dark   := Color(col.r * 0.45, col.g * 0.45, col.b * 0.45)
		var mid    := Color(col.r * 0.70, col.g * 0.70, col.b * 0.70)
		var bright := col.lightened(0.28)
		var shine  := Color(1.0, 1.0, 1.0, 0.18)

		draw_circle(Vector2(-16, -18), 8.0, dark)
		draw_circle(Vector2( 16, -18), 8.0, dark)
		draw_circle(Vector2(-16,  18), 8.0, dark)
		draw_circle(Vector2( 16,  18), 8.0, dark)
		draw_rect(Rect2(-17,  6, 34, 22), col)
		draw_rect(Rect2(-17, -8, 34, 16), col)
		draw_rect(Rect2(-14, -28, 28, 22), col)
		draw_rect(Rect2(-20,  -4, 5, 26), mid)
		draw_rect(Rect2( 15,  -4, 5, 26), mid)
		draw_rect(Rect2(-3, -28, 6, 20), bright)
		draw_rect(Rect2(-14, -32, 28,  5), dark)
		draw_rect(Rect2( -9, -31, 5,  3), Color(0.05, 0.05, 0.08))
		draw_rect(Rect2(  4, -31, 5,  3), Color(0.05, 0.05, 0.08))
		draw_circle(Vector2(-11, -29), 3.5, Color(1.0, 0.98, 0.80))
		draw_circle(Vector2( 11, -29), 3.5, Color(1.0, 0.98, 0.80))
		draw_circle(Vector2(-11, -29), 1.8, Color(1.0, 1.0, 1.0))
		draw_circle(Vector2( 11, -29), 1.8, Color(1.0, 1.0, 1.0))
		draw_rect(Rect2(-11, -22, 22, 14), Color(0.40, 0.72, 0.92, 0.82))
		draw_rect(Rect2( -9, -21, 6,  5), Color(1.0, 1.0, 1.0, 0.30))
		draw_rect(Rect2(-10,  -8, 20, 14), dark)
		draw_rect(Rect2( -7,  -7, 8,  4), shine)
		draw_rect(Rect2(-9,   6, 18,  8), Color(0.30, 0.55, 0.75, 0.70))
		draw_rect(Rect2(-17, 26, 34,  4), dark)
		draw_circle(Vector2(-12, 27), 3.0, Color(0.95, 0.10, 0.10))
		draw_circle(Vector2( 12, 27), 3.0, Color(0.95, 0.10, 0.10))
		draw_circle(Vector2(-12, 27), 1.5, Color(1.0, 0.55, 0.55))
		draw_circle(Vector2( 12, 27), 1.5, Color(1.0, 0.55, 0.55))
		var tire := Color(0.12, 0.12, 0.14)
		var rim  := Color(0.75, 0.75, 0.80)
		for wx in [-16, 16]:
			for wy in [-18, 18]:
				draw_circle(Vector2(wx, wy), 7.0, tire)
				draw_circle(Vector2(wx, wy), 4.0, rim)
				draw_circle(Vector2(wx, wy), 2.0, Color(0.3, 0.3, 0.35))
		draw_rect(Rect2(-23, -12, 5, 4), dark)
		draw_rect(Rect2( 18, -12, 5, 4), dark)

	# ── Engine exhaust (always on, animated flicker) ─────────────────────────
	var ex_flicker := sin(_vfx_t * 20.0) * 0.5 + 0.5   # 0 → 1
	var ex_size    := 4.0 + ex_flicker * 2.5
	var ex_alpha   := 0.30 + ex_flicker * 0.15
	draw_circle(Vector2(-12, 28), ex_size + 2.0, Color(0.60, 0.25, 0.04, ex_alpha * 0.45))
	draw_circle(Vector2( 12, 28), ex_size + 2.0, Color(0.60, 0.25, 0.04, ex_alpha * 0.45))
	draw_circle(Vector2(-12, 28), ex_size,        Color(1.00, 0.48, 0.08, ex_alpha))
	draw_circle(Vector2( 12, 28), ex_size,        Color(1.00, 0.48, 0.08, ex_alpha))
	# Smoke wisps
	var sm_flicker := sin(_vfx_t * 14.0 + 1.2) * 0.5 + 0.5
	draw_circle(Vector2(-12, 34 + sm_flicker * 4.0), 4.5, Color(0.55, 0.55, 0.60, 0.10))
	draw_circle(Vector2( 12, 34 + sm_flicker * 4.0), 4.5, Color(0.55, 0.55, 0.60, 0.10))

	# ── Boost speed lines + glow ─────────────────────────────────────────────
	if is_boosting:
		var bl_t: float = clamp(boost_timer / boost_duration, 0.0, 1.0)
		var bl_a   := bl_t * 0.65
		# Radial speed lines
		for i in 10:
			var angle := float(i) / 10.0 * TAU + _vfx_t * 1.8
			var from_v := Vector2(cos(angle) * 30.0, sin(angle) * 22.0)
			var to_v   := Vector2(cos(angle) * 72.0, sin(angle) * 55.0)
			draw_line(from_v, to_v, Color(1.0, 0.75, 0.30, bl_a * 0.80), 1.5)
		# Outer glow ring
		draw_arc(Vector2.ZERO, 50.0, 0.0, TAU, 48,
			Color(1.0, 0.65, 0.15, bl_t * 0.45), 6.0)
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 40,
			Color(1.0, 0.90, 0.50, bl_t * 0.30), 3.0)
		# Core glow under car
		draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.60, 0.10, bl_t * 0.18))

	# ── Boost flame ─────────────────────────────────────────────────────────
	if is_boosting:
		draw_circle(Vector2(  0, 36), 14.0, Color(1.0, 0.40, 0.00, 0.20))
		draw_rect(Rect2(-12, 28, 24, 22), Color(1.0, 0.38, 0.00, 0.90))
		draw_rect(Rect2( -8, 30, 16, 16), Color(1.0, 0.72, 0.08, 0.95))
		draw_rect(Rect2( -4, 33,  8, 10), Color(1.0, 0.95, 0.60, 1.00))
		# Side exhausts
		draw_rect(Rect2(-20, 24,  5, 12), Color(1.0, 0.50, 0.00, 0.80))
		draw_rect(Rect2( 15, 24,  5, 12), Color(1.0, 0.50, 0.00, 0.80))
		# Headlight flare when boosting
		draw_circle(Vector2(-11, -29), 5.5, Color(1.0, 0.95, 0.70, 0.35))
		draw_circle(Vector2( 11, -29), 5.5, Color(1.0, 0.95, 0.70, 0.35))

	# ── Shield bubble ────────────────────────────────────────────────────────
	if shield_active and shield > 0:
		draw_arc(Vector2.ZERO, 36, 0, TAU, 48, Color(0.30, 0.75, 1.00, 0.55), 2.5)
		draw_arc(Vector2.ZERO, 34, 0, TAU, 48, Color(0.60, 0.92, 1.00, 0.25), 1.0)
		# Animated rotating sparks on shield edge
		for i in 6:
			var sa2: float = _vfx_t * 3.0 + float(i) / 6.0 * TAU
			draw_circle(Vector2(cos(sa2) * 36.0, sin(sa2) * 36.0), 2.5, Color(0.70, 0.95, 1.0, 0.65))

	# ── Magnet Aura: rotating orbital ring ────────────────────────────────
	if has_magnet:
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 32, Color(0.78, 0.28, 1.0, 0.18), 2.0)
		var ma_rot: float = _vfx_t * 2.5
		for i in 6:
			var ma_a: float = ma_rot + float(i) / 6.0 * TAU
			draw_circle(Vector2(cos(ma_a) * 42.0, sin(ma_a) * 42.0), 3.0, Color(0.80, 0.32, 1.0, 0.45))

	# ── Adrenaline: pulsing red danger glow when HP < 25% ─────────────────
	if has_adrenaline and health <= int(max_health * 0.25):
		var adr_a: float = clamp(0.45 + sin(_vfx_t * 8.0) * 0.45, 0.0, 0.90)
		draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 48, Color(1.0, 0.08, 0.08, adr_a), 4.0)
		draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 48, Color(1.0, 0.38, 0.0, adr_a * 0.50), 2.0)

	# ── Iron Skin: gold armor plate overlays ──────────────────────────────
	if has_iron_skin:
		draw_rect(Rect2(-18,   4, 36, 24), Color(1.0, 0.78, 0.08, 0.28))   # rear plate
		draw_rect(Rect2(-15, -32, 30,  8), Color(1.0, 0.78, 0.08, 0.28))   # front plate
		draw_rect(Rect2(-23,  -6,  6, 28), Color(1.0, 0.78, 0.08, 0.22))   # left flank
		draw_rect(Rect2( 17,  -6,  6, 28), Color(1.0, 0.78, 0.08, 0.22))   # right flank

	# ── Lifesteal: faint green pulse glow (always-on indicator) ──────────
	if has_lifesteal:
		var ls_a: float = 0.16 + sin(_vfx_t * 4.0) * 0.08
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 32, Color(0.20, 1.0, 0.40, ls_a), 3.0)

	# ── Ram Fury: orange front glow during boost ──────────────────────────
	if has_ram_fury and is_boosting:
		var rf_a: float = 0.50 + abs(sin(_vfx_t * 12.0)) * 0.30
		draw_rect(Rect2(-16, -38, 32, 10), Color(1.0, 0.38, 0.00, rf_a))
		draw_arc(Vector2(0.0, -28.0), 22.0, PI + 0.4, TAU - 0.4, 24,
			Color(1.0, 0.52, 0.08, rf_a * 0.80), 6.0)

	# ── Afterburner: blue-white jet flares during boost ───────────────────
	if has_afterburner and is_boosting:
		var af_t: float = abs(sin(_vfx_t * 16.0))
		draw_circle(Vector2(-12.0, 34.0 + af_t * 7.0), 9.0 + af_t * 4.0, Color(0.20, 0.60, 1.0, 0.48))
		draw_circle(Vector2( 12.0, 34.0 + af_t * 7.0), 9.0 + af_t * 4.0, Color(0.20, 0.60, 1.0, 0.48))
		draw_circle(Vector2(-12.0, 34.0 + af_t * 7.0), 5.0 + af_t * 2.5, Color(0.65, 0.92, 1.0, 0.72))
		draw_circle(Vector2( 12.0, 34.0 + af_t * 7.0), 5.0 + af_t * 2.5, Color(0.65, 0.92, 1.0, 0.72))

	# ── Turbo Engine: fast cyan strobe on exhaust ports ───────────────────
	if GameState.has_perk("Turbo Engine"):
		var te_t: float = abs(sin(_vfx_t * 22.0))
		draw_circle(Vector2(-12.0, 28.0), 6.0 + te_t * 2.0, Color(0.10, 0.80, 1.0, te_t * 0.55))
		draw_circle(Vector2( 12.0, 28.0), 6.0 + te_t * 2.0, Color(0.10, 0.80, 1.0, te_t * 0.55))

	# ── Overload: charge-progress dots beneath car ────────────────────────
	if has_overload:
		for i in 10:
			var dot_x: float = -18.0 + float(i) * 4.0
			if i < _overload_counter:
				draw_circle(Vector2(dot_x, 44.0), 2.8, Color(1.0, 0.28, 0.05, 0.90))
			else:
				draw_circle(Vector2(dot_x, 44.0), 1.8, Color(0.32, 0.32, 0.36, 0.45))

	# ── Revival invincibility: pulsing green halo (fades out over 3 s) ────────
	if revival_timer > 0.0:
		var rv_frac: float = clamp(revival_timer / 3.0, 0.0, 1.0)
		var rv_pulse: float = abs(sin(_vfx_t * 7.0))
		var rv_a: float = rv_frac * (0.55 + rv_pulse * 0.30)
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 48, Color(0.20, 1.00, 0.55, rv_a), 5.0)
		draw_arc(Vector2.ZERO, 50.0, 0.0, TAU, 48, Color(0.40, 1.00, 0.70, rv_a * 0.40), 2.0)
		for i in 8:
			var rv_ang: float = _vfx_t * 3.5 + float(i) / 8.0 * TAU
			draw_circle(Vector2(cos(rv_ang) * 42.0, sin(rv_ang) * 42.0), 3.0,
				Color(0.50, 1.00, 0.70, rv_frac * 0.75))
