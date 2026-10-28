extends Node2D

const LANE_X: Array = [130.0, 240.0, 350.0]
var SCREEN_H: float = 854.0

# ─── Road ─────────────────────────────────────────────────────────────────────
var road_scroll_speed: float = 300.0

# ─── Distance / perk gating ───────────────────────────────────────────────────
var distance: float = 0.0
var last_perk_distance: float = 0.0
var perk_count: int = 0          # how many perks granted this run
const PERK_INTERVAL_BASE: float  = 1000.0
const PERK_INTERVAL_STEP: float  = 350.0   # added per perk gained
const PERK_INTERVAL_MAX:  float  = 3000.0

func _next_perk_interval() -> float:
	return minf(PERK_INTERVAL_BASE + perk_count * PERK_INTERVAL_STEP, PERK_INTERVAL_MAX)

# ─── Enemy spawning ───────────────────────────────────────────────────────────
var spawn_timer: float = 0.0
var spawn_interval: float = 1.10   # base spawn interval

# ─── Difficulty (milestone-based, every 80 m; resets per zone) ───────────────
var last_milestone: float = 0.0
const MILESTONE_INTERVAL: float = 80.0
var enemy_speed_mult: float = 1.0
var enemy_aggression: float = 1.2   # +20% base aggression
# Zone-base values — each new zone starts slightly harder than the last zone started
var _zone_base_speed_mult: float   = 1.0
var _zone_base_aggression: float   = 1.2
var _zone_base_spawn_interval: float = 1.10

# ─── Boss ─────────────────────────────────────────────────────────────────────
var boss_active: bool = false
var current_boss = null
var boss_count: int = 0
const BOSS_INTERVAL: float = 2500.0
var next_boss_distance: float = 2500.0

var current_environment: int = 0
const ENV_NAMES: Array = [
	"CITY HIGHWAY",    "DESERT ROAD",      "NIGHT CITY",      "ICE ROAD",         "VOLCANO PASS",
	"FOREST TRACK",    "INDUSTRIAL ZONE",  "COASTAL ROAD",    "UNDERGROUND TUNNEL","SPACE HIGHWAY",
	"NEON WASTELAND",  "CRIMSON BADLANDS", "CRYSTAL CAVERNS", "TOXIC SWAMP",      "ARCTIC TUNDRA",
	"STORM CORRIDOR",  "CYBERPUNK SLUMS",  "LAVA FIELDS",     "SKY BRIDGE",       "HAUNTED HIGHWAY",
	"BLOOD MOON PASS", "QUANTUM GRID",     "SHADOW REALM",    "CHROME CITY",      "VOID CORRIDOR",
]

# ─── Run tracking ─────────────────────────────────────────────────────────────
var _prev_hp: float = 0.0
var _damage_free_dist: float = 0.0
var _max_damage_free_dist: float = 0.0
var _shake_t: float = 0.0
var _shake_mag: float = 0.0

# ─── State ────────────────────────────────────────────────────────────────────
var game_running: bool = false
var paused_for_perk: bool = false

# ─── Scene refs ───────────────────────────────────────────────────────────────
@onready var player = $Player
@onready var hud = $HUD
@onready var enemies_container = $Enemies
@onready var coins_container = $Coins
@onready var bullets_container = $Bullets
@onready var effects_container = $Effects
@onready var road_node = $Road

# ─── Preloads ─────────────────────────────────────────────────────────────────
var grunt_scene    = preload("res://scenes/Grunt.tscn")
var shooter_scene  = preload("res://scenes/Shooter.tscn")
var speeder_scene  = preload("res://scenes/Speeder.tscn")
var kamikaze_scene = preload("res://scenes/Kamikaze.tscn")
var tank_scene     = preload("res://scenes/Tank.tscn")
var boss_scene     = preload("res://scenes/Boss.tscn")
var coin_scene     = preload("res://scenes/Coin.tscn")
var bullet_scene   = preload("res://scenes/Bullet.tscn")
var perk_scene     = preload("res://scenes/PerkScreen.tscn")
var gameover_scene = preload("res://scenes/GameOver.tscn")
var explosion_scene = preload("res://scenes/Explosion.tscn")

# ─── Ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	SCREEN_H = get_viewport_rect().size.y
	road_scroll_speed = 350.0 + GameState.get_starting_speed_bonus()
	game_running = true
	Music.set_environment(0)   # Start with env 0 (City) music

	player.main_ref = self
	player.died.connect(_on_player_died)
	player.shot_fired.connect(_on_player_shot)
	_prev_hp = player.health

	# Head Start consumable: begin 400 m ahead
	if GameState.run_active_consumables.get("head_start", false):
		distance = 400.0
		last_perk_distance = 400.0
		last_milestone = 400.0

	hud.update_health(player.health, player.max_health)
	hud.update_coins(0)
	hud.update_distance(0)
	hud.update_best_distance(GameState.best_distance)

	# First-run tutorial: show controls popup before first action
	if not GameState.tutorial_done:
		_show_controls_tutorial()

# ─── Game loop ────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not game_running:
		return

	# Road always scrolls
	road_node.scroll_offset += road_scroll_speed * delta
	road_node.speed_ref = road_scroll_speed
	road_node.queue_redraw()

	# Distance freezes during boss fights; resumes the moment boss is defeated
	if not boss_active:
		distance += road_scroll_speed * delta * 0.1
	hud.update_distance(distance)

	if paused_for_perk:
		return

	# Screen shake
	if _shake_t > 0.0:
		_shake_t -= delta
		var sf: float = _shake_t / 0.30
		position = Vector2(randf_range(-1.0, 1.0) * _shake_mag * sf,
						   randf_range(-1.0, 1.0) * _shake_mag * sf)
	else:
		position = Vector2.ZERO

	# Damage-free streak tracking (for Untouchable achievement)
	var cur_hp: float = player.health
	if cur_hp < _prev_hp:
		_damage_free_dist = 0.0
	_prev_hp = cur_hp
	_damage_free_dist += road_scroll_speed * delta * 0.1
	if _damage_free_dist > _max_damage_free_dist:
		_max_damage_free_dist = _damage_free_dist

	# Update all enemies (includes boss)
	for e in enemies_container.get_children():
		if is_instance_valid(e) and not e.dead:
			e.main_update(delta, player.position)

	# Redraw player
	player.queue_redraw()

	# Shield HUD
	hud.update_shield(player.shield if player.shield_active else 0.0, player.max_shield)

	# ── Boss fight mode ───────────────────────────────────────────────────────
	if boss_active:
		if is_instance_valid(current_boss):
			hud.update_boss_health(current_boss.health, current_boss.max_health)
		_cleanup_offscreen()
		return  # skip regular spawning & difficulty scaling during boss

	# ── Regular spawning ──────────────────────────────────────────────────────
	# Perk milestone — grows each time a perk is granted
	if distance - last_perk_distance >= _next_perk_interval():
		last_perk_distance = distance
		_trigger_perk_selection()
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

	# Difficulty milestone every 80 m
	if distance - last_milestone >= MILESTONE_INTERVAL:
		last_milestone = distance
		_on_difficulty_milestone()

	# Boss milestone
	if distance >= next_boss_distance and not paused_for_perk:
		_spawn_boss()

	_cleanup_offscreen()

# ─── Difficulty milestone ─────────────────────────────────────────────────────
func _on_difficulty_milestone() -> void:
	# Road speed increases continuously (visual game pace — never resets)
	road_scroll_speed = minf(road_scroll_speed + 12.0, 900.0)
	# Combat difficulty scales up within the current zone
	spawn_interval    = maxf(spawn_interval - 0.05, 0.50)
	enemy_speed_mult  = minf(enemy_speed_mult + 0.04, 2.5)
	enemy_aggression  = minf(enemy_aggression + 0.072, 3.0) # +20% step vs old 0.06

# Called at zone start (after boss dies). Resets combat difficulty to a per-zone
# baseline so each area starts accessible and ramps toward the boss.
func _reset_zone_difficulty() -> void:
	var z: float = float(boss_count)   # boss_count already reflects the new zone index
	_zone_base_speed_mult     = minf(1.0  + z * 0.07, 1.80)
	_zone_base_aggression     = minf(1.2  + z * 0.12, 2.60)   # +20% base + steeper ramp
	_zone_base_spawn_interval = maxf(1.10 - z * 0.06, 0.55)
	enemy_speed_mult  = _zone_base_speed_mult
	enemy_aggression  = _zone_base_aggression
	spawn_interval    = _zone_base_spawn_interval
	last_milestone    = distance   # restart milestone counter for this zone

# ─── Enemy spawning ───────────────────────────────────────────────────────────
func _spawn_enemy() -> void:
	if enemies_container.get_child_count() >= 5:
		return

	var player_lane = player.current_lane if is_instance_valid(player) else 1
	var lane: int
	if randf() < 0.20:
		lane = player_lane
	else:
		var lane_pool: Array = [0, 1, 2]
		lane_pool.erase(player_lane)
		lane = lane_pool[randi() % lane_pool.size()]

	var scene: PackedScene
	var roll = randf()

	if distance < 300.0:
		scene = grunt_scene
	elif distance < 800.0:
		scene = grunt_scene if roll < 0.65 else shooter_scene
	elif distance < 1500.0:
		if   roll < 0.35: scene = grunt_scene
		elif roll < 0.60: scene = shooter_scene
		elif roll < 0.80: scene = speeder_scene
		else:              scene = kamikaze_scene
	elif distance < 3000.0:
		if   roll < 0.25: scene = grunt_scene
		elif roll < 0.45: scene = shooter_scene
		elif roll < 0.65: scene = speeder_scene
		elif roll < 0.82: scene = kamikaze_scene
		else:              scene = tank_scene
	else:
		if   roll < 0.20: scene = grunt_scene
		elif roll < 0.40: scene = shooter_scene
		elif roll < 0.58: scene = speeder_scene
		elif roll < 0.76: scene = kamikaze_scene
		else:              scene = tank_scene

	var enemy = scene.instantiate()
	enemies_container.add_child(enemy)
	enemy.position = Vector2(LANE_X[lane], -70.0)
	enemy.lane = lane
	enemy.main_ref = self

	enemy.speed      *= enemy_speed_mult
	enemy.aggression  = enemy_aggression
	enemy.health *= GameState.get_enemy_health_multiplier() * 1.035
	enemy.max_health = enemy.health

	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.shot_fired.connect(_on_enemy_shot.bind(enemy))

# ─── Boss spawning ────────────────────────────────────────────────────────────
func _spawn_boss() -> void:
	boss_active = true
	boss_count += 1
	next_boss_distance = distance + BOSS_INTERVAL

	# Advance environment (cycles through 0-24)
	current_environment = (boss_count - 1) % ENV_NAMES.size()
	road_node.set_environment(current_environment)
	Music.set_environment(current_environment)
	hud.show_zone_banner(Locale.t("env_" + str(current_environment)))

	# Clear all regular enemies
	for e in enemies_container.get_children():
		if is_instance_valid(e):
			e.queue_free()

	var boss = boss_scene.instantiate()
	# Set boss_number BEFORE add_child so _ready() -> setup() uses the right stats
	boss.boss_number = current_environment + 1
	enemies_container.add_child(boss)
	boss.position = Vector2(LANE_X[1], -100.0)
	boss.lane = 1
	boss.main_ref = self
	boss.aggression = enemy_aggression

	boss.died.connect(_on_boss_died.bind(boss))
	boss.boss_attack_fired.connect(_on_boss_attack.bind(boss))
	boss.phase_changed.connect(_on_boss_phase_changed.bind(boss))

	current_boss = boss
	hud.update_boss_health(boss.health, boss.max_health)

	# Show zone banner first, then boss warning after it fades
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(boss) and boss_active:
		SFX.play_boss()
		hud.show_boss_warning(boss.get_boss_name())

	# First-ever boss fight: teach the parry mechanic
	if boss_count == 1 and not GameState.parry_tutorial_done and boss_active:
		await get_tree().create_timer(1.2).timeout
		_show_tutorial_popup(
			"⚡  BOSS BATTLE  ⚡",
			"When a boss bullet heads for you —\n\nTAP BOOST at that exact moment\nto DEFLECT it straight back at the boss!",
			func():
				GameState.parry_tutorial_done = true
				GameState.save(),
			_ParryDemo.new()
		)

func spawn_boss_drone(_spawn_pos: Vector2) -> void:
	# Cap total enemies during boss fight
	if enemies_container.get_child_count() >= 5:
		return
	var drone = kamikaze_scene.instantiate()
	enemies_container.add_child(drone)
	# Spawn at the top of the screen so the player can see it coming
	var dlane: int = randi() % 3
	drone.position = Vector2(LANE_X[dlane], -70.0)
	drone.lane = dlane
	drone.main_ref = self
	drone.aggression = enemy_aggression
	drone.died.connect(_on_enemy_died.bind(drone))
	drone.shot_fired.connect(_on_enemy_shot.bind(drone))

func _fire_boss_bullet(pos: Vector2, dir: Vector2, dmg: float, spd: float,
		col: Color = Color(1.0, 0.2, 0.2), sz: float = 1.0) -> void:
	var b = bullet_scene.instantiate()
	bullets_container.add_child(b)
	b.position = pos
	b.direction = dir.normalized()
	b.is_player_bullet = false
	b.damage = dmg
	b.speed = spd
	b.bullet_color = col
	b.bullet_size = sz
	b.is_boss_bullet = true
	b.hit_target.connect(_on_bullet_hit)

func _on_boss_attack(attack_type: int, boss) -> void:
	if not is_instance_valid(boss) or not is_instance_valid(player):
		return
	var origin: Vector2 = boss.position + Vector2(0.0, 36.0)
	var aim: Vector2 = (player.position - boss.position).normalized()
	var bc: Color = boss.color   # tint bullets to boss identity

	match attack_type:
		0:  # ── Aimed spread ──────────────────────────────────────────────────
			# phase 1: 3 bullets  phase 2: 5 bullets  phase 3: 7 wider bullets
			var count = 3 + (boss.phase - 1) * 2
			var spread = deg_to_rad(22.0 + float(boss.phase) * 5.0)
			var spd = 260.0 + float(boss.phase) * 20.0
			for i in count:
				var t = (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
				var angle = aim.angle() + t * spread
				var dir = Vector2(cos(angle), sin(angle))
				_fire_boss_bullet(origin, dir, 12.0 + float(boss.phase) * 2.0, spd,
					bc.lerp(Color(1.0, 0.15, 0.05), 0.55), 1.0)

		1:  # ── Lane barrage — 3 pairs, one per lane, heading straight down ───
			# Forces the player to actively move to an uncovered lane
			var lane_xs: Array = LANE_X
			for lx in lane_xs:
				var lorigin1 = Vector2(lx, origin.y)
				var lorigin2 = Vector2(lx, origin.y - 28.0)
				var spd = 360.0 + float(boss.phase) * 15.0
				_fire_boss_bullet(lorigin1, Vector2.DOWN, 11.0, spd,
					Color(1.0, 0.85, 0.10).lerp(bc, 0.35), 1.15)
				_fire_boss_bullet(lorigin2, Vector2.DOWN, 11.0, spd,
					Color(1.0, 0.85, 0.10).lerp(bc, 0.35), 1.15)

		2:  # ── Radial burst — 8-10 bullets in all directions (Armored / Hex / Phantom) ──
			var rays = 8 + (boss.phase - 2) * 2
			for i in rays:
				var angle = float(i) / float(rays) * TAU
				var dir = Vector2(cos(angle), sin(angle))
				_fire_boss_bullet(origin, dir, 9.0, 200.0,
					bc.lerp(Color(0.8, 0.4, 1.0), 0.60), 1.3)

		3:  # ── Rapid twin volley (Velocity Racer) — 2 fast bullets per burst ──
			# High speed, tight spread; repeats based on phase
			var shots = 2 + boss.phase
			for i in shots:
				var scatter := deg_to_rad(randf_range(-14.0, 14.0))
				var dir = Vector2(sin(scatter + aim.angle()), cos(scatter + aim.angle())).normalized()
				# Slight stagger via a tiny spawn offset
				_fire_boss_bullet(origin + Vector2(0, float(i) * -12), dir,
					10.0 + float(boss.phase) * 2.0, 400.0 + float(boss.phase) * 35.0,
					bc.lerp(Color(0.20, 0.85, 1.0), 0.50), 0.85)

		4:  # ── Lateral sweep (Hex Sentinel) — row of bullets sweeping across lanes ──
			var cols: int = 5 + boss.phase
			for i in cols:
				var t: float = float(i) / float(cols - 1)
				var sweep_x: float = lerp(60.0, 420.0, t)      # left edge to right edge
				var sweep_dir: Vector2 = Vector2(aim.x * 0.3, 1.0).normalized()  # mostly downward
				_fire_boss_bullet(Vector2(sweep_x, origin.y), sweep_dir,
					11.0 + float(boss.phase) * 1.5, 290.0,
					bc.lerp(Color(0.10, 1.0, 0.55), 0.55), 1.1)

		5:  # ── Cluster bomb (Iron Juggernaut) — 3 slow wide shots, one per lane ──
			for lx in LANE_X:
				# Large, slow bomb — easy to dodge but wide radius feel
				_fire_boss_bullet(Vector2(lx, origin.y), aim.lerp(Vector2.DOWN, 0.5).normalized(),
					18.0 + float(boss.phase) * 3.0, 160.0,
					bc.lerp(Color(1.0, 0.40, 0.0), 0.45), 1.8)
			# Phase 2+: extra flanking bombs
			if boss.phase >= 2:
				for fx in [LANE_X[0] - 40, LANE_X[2] + 40]:
					_fire_boss_bullet(Vector2(clamp(fx, 60.0, 420.0), origin.y),
						Vector2.DOWN, 14.0, 140.0, bc.lerp(Color(1.0, 0.55, 0.0), 0.40), 1.5)

		6:  # ── Homing volley (Phantom Wraith) — bullets that curve toward player ──
			var count: int = 2 + boss.phase
			for i in count:
				var angle_offset: float = (float(i) / float(count) - 0.5) * deg_to_rad(50.0)
				var base_angle: float = aim.angle() + angle_offset
				var dir = Vector2(cos(base_angle), sin(base_angle))
				var b = bullet_scene.instantiate()
				bullets_container.add_child(b)
				b.position = origin + Vector2(cos(base_angle) * float(i) * 8, 0)
				b.direction = dir
				b.is_player_bullet = false
				b.is_boss_bullet = true
				b.is_homing = true    # reuse homing flag — will scan for player node
				b.damage = 10.0 + float(boss.phase) * 2.0
				b.speed = 220.0 + float(boss.phase) * 20.0
				b.bullet_color = bc.lerp(Color(0.80, 0.30, 1.0), 0.55)
				b.bullet_size = 1.2
				b.hit_target.connect(_on_bullet_hit)

func _on_boss_phase_changed(new_phase: int, boss) -> void:
	if is_instance_valid(boss):
		spawn_explosion(boss.position, Color(1.0, 0.6, 0.0))
	hud.show_boss_phase(new_phase)

func _on_boss_died(boss) -> void:
	boss_active = false
	current_boss = null
	GameState.run_bosses += 1
	GameState.earn_gems(2)
	_reset_zone_difficulty()   # new area starts fresh, slightly harder base
	if is_instance_valid(boss):
		spawn_explosion(boss.position, Color(1.0, 0.3, 0.0))
		# Drop coins — Executioner triples the haul
		var coin_mult := 2 if GameState.has_perk("Executioner") else 1
		for i in boss.coin_value * coin_mult:
			var c = coin_scene.instantiate()
			coins_container.add_child(c)
			c.position = boss.position + Vector2(randf_range(-40, 40), randf_range(-25, 25))
			c.collected.connect(_on_coin_collected)
	hud.hide_boss_bar()

# ─── Bullet handling ──────────────────────────────────────────────────────────
func _fire_player_bullet(origin: Vector2, dir: Vector2, dmg: float, allow_homing: bool = true) -> void:
	var b = bullet_scene.instantiate()
	bullets_container.add_child(b)
	b.position = origin
	b.direction = dir.normalized()
	b.is_player_bullet = true
	b.damage = dmg
	if is_instance_valid(player):
		# Homing only applies to centre bullets — spread bullets always fly straight
		b.is_homing = player.has_homing and allow_homing
		b.pierce_remaining = 1 if player.has_piercing else 0
	b.hit_target.connect(_on_bullet_hit)

func _on_player_shot() -> void:
	SFX.play_shoot()
	var origin: Vector2 = player.position + Vector2(0.0, -38.0)
	var dmg: float = player.consume_shot_damage()   # handles Overload + Adrenaline
	# Centre bullet(s) — homing allowed
	if GameState.has_perk("Twin Barrels"):
		_fire_player_bullet(origin + Vector2(-4, 0), Vector2.UP, dmg, true)
		_fire_player_bullet(origin + Vector2( 4, 0), Vector2.UP, dmg, true)
	else:
		_fire_player_bullet(origin, Vector2.UP, dmg, true)
	# Spread bullets — never home regardless of perk
	_fire_player_bullet(origin, Vector2(-0.259, -0.966), dmg * 0.35, false)
	_fire_player_bullet(origin, Vector2(0.259, -0.966), dmg * 0.35, false)

func _on_enemy_shot(shooter) -> void:
	if not is_instance_valid(shooter) or not is_instance_valid(player):
		return
	# Boss shooting is handled separately in _on_boss_shot
	if shooter.is_boss:
		return
	var b = bullet_scene.instantiate()
	bullets_container.add_child(b)
	b.position = shooter.position + Vector2(0.0, 32.0)
	var aim_dir = (player.position - shooter.position).normalized()
	b.direction = aim_dir
	b.is_player_bullet = false
	b.damage = 15.0
	b.speed = 330.0
	b.hit_target.connect(_on_bullet_hit)

func _on_bullet_hit(bullet, target) -> void:
	if not is_instance_valid(bullet):
		return

	if bullet.is_player_bullet:
		if is_instance_valid(target) and target.has_method("take_damage") and not target.dead:
			var dmg: float = bullet.damage
			if GameState.has_perk("Nemesis") and target.is_boss:
				dmg *= 1.5
			target.take_damage(dmg)
			if GameState.has_perk("Lifesteal") and is_instance_valid(player):
				var ls_amt: int = roundi(dmg * 0.05)
				if ls_amt > 0:
					player.heal(ls_amt)
			if GameState.has_perk("Ricochet Shots") and not bullet.is_ricochet:
				_spawn_ricochet(bullet.position, target)
			if GameState.has_perk("Explosive Rounds"):
				_spawn_explosive_aoe(bullet.position, target)
	else:
		if is_instance_valid(target) and target == player:
			# ── Parry: boosting player deflects boss bullets back ──────────────
			if bullet.is_boss_bullet and player.is_boosting and boss_active and is_instance_valid(current_boss):
				SFX.play_parry()
				# Three layered explosions — cyan outer, white core, orange flash
				spawn_explosion(bullet.position + Vector2(randf_range(-8,8), randf_range(-8,8)), Color(0.0, 0.90, 1.0))
				spawn_explosion(bullet.position, Color(1.0, 1.0, 1.0))
				spawn_explosion(bullet.position + Vector2(randf_range(-6,6), randf_range(-6,6)), Color(0.60, 0.95, 1.0))
				hud.flash_parry()
				_trigger_shake(16.0, 0.30)
				_fire_parry_bullet(bullet.position)
				if is_instance_valid(bullet):
					bullet.queue_free()
				return
			player.take_damage(bullet.damage)

	# Piercing Shot: survive one hit, immune to re-hitting same enemy for 0.2 s
	if bullet.is_player_bullet and bullet.pierce_remaining > 0:
		bullet.pierce_remaining -= 1
		bullet._last_pierced = target
		bullet._pierce_skip_t = 0.20
		return

	if is_instance_valid(bullet):
		bullet.queue_free()

func _trigger_shake(mag: float, dur: float) -> void:
	_shake_mag = mag
	_shake_t = dur

func _fire_parry_bullet(from_pos: Vector2) -> void:
	if not is_instance_valid(current_boss):
		return
	var b = bullet_scene.instantiate()
	bullets_container.add_child(b)
	b.position = from_pos
	b.direction = (current_boss.position - from_pos).normalized()
	b.is_player_bullet = true
	b.is_parry = true
	# Parry damage matches side bullets: 35% of weapon_damage
	b.damage = (player.weapon_damage if is_instance_valid(player) else 20.0) * 0.35
	b.speed = 520.0
	b.hit_target.connect(_on_bullet_hit)

func _spawn_explosive_aoe(pos: Vector2, origin) -> void:
	spawn_explosion(pos, Color(1.0, 0.65, 0.10))
	var aoe_radius := 55.0
	for e in enemies_container.get_children():
		if not is_instance_valid(e) or e.dead or e == origin:
			continue
		if e.position.distance_to(pos) < aoe_radius:
			e.take_damage(player.weapon_damage * 0.25)

func _spawn_ricochet(pos: Vector2, origin) -> void:
	var nearest = null
	var best_d = 9999.0
	for e in enemies_container.get_children():
		if e == origin or not is_instance_valid(e) or e.dead:
			continue
		var d = e.position.distance_to(pos)
		if d < best_d:
			best_d = d
			nearest = e
	if nearest and best_d < 600.0:
		var b = bullet_scene.instantiate()
		bullets_container.add_child(b)
		b.position = pos
		b.direction = (nearest.position - pos).normalized()
		b.is_player_bullet = true
		b.is_ricochet = true
		b.target_node = nearest
		b.damage = player.weapon_damage * 0.5
		b.hit_target.connect(_on_bullet_hit)

# ─── Enemy death ──────────────────────────────────────────────────────────────
func _on_enemy_died(enemy) -> void:
	if not is_instance_valid(enemy):
		return
	SFX.play_kill()
	SFX.play_explode()
	spawn_explosion(enemy.position, enemy.color.lerp(Color(1.0, 0.5, 0.0), 0.5))
	GameState.run_kills += 1
	var base_coins = enemy.coin_value
	if GameState.has_perk("Double Coins"):
		base_coins *= 2
	for i in base_coins:
		var c = coin_scene.instantiate()
		coins_container.add_child(c)
		c.position = enemy.position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		c.collected.connect(_on_coin_collected)
	if GameState.has_perk("Chain Explosion"):
		var radius = 90.0 + GameState.get_explosion_radius_bonus()
		spawn_explosion(enemy.position, Color(1.0, 0.5, 0.0))
		for e in enemies_container.get_children():
			if is_instance_valid(e) and not e.dead and e != enemy:
				if e.position.distance_to(enemy.position) < radius:
					e.take_damage(30.0)
	# Lucky Strike: 20% chance to instantly reset boost cooldown
	if GameState.has_perk("Lucky Strike") and is_instance_valid(player) and randf() < 0.20:
		player.boost_cooldown = 0.0
	# Coin Rush: 1 bonus coin per kill
	if GameState.has_perk("Coin Rush") and is_instance_valid(enemy):
		for _i in 2:
			var cr = coin_scene.instantiate()
			coins_container.add_child(cr)
			cr.position = enemy.position + Vector2(randf_range(-16, 16), randf_range(-8, 8))
			cr.collected.connect(_on_coin_collected)

func _on_coin_collected(value: int) -> void:
	SFX.play_coin()
	GameState.earn_run_coins(value)
	hud.update_coins(GameState._revival_coins + GameState.run_coins_earned)
	# Scavenger: coin pickups restore 1 HP
	if GameState.has_perk("Scavenger") and is_instance_valid(player):
		player.heal(1)

# ─── Explosions ───────────────────────────────────────────────────────────────
func spawn_explosion(pos: Vector2, col: Color = Color(1.0, 0.5, 0.0)) -> void:
	var expl = explosion_scene.instantiate()
	effects_container.add_child(expl)
	expl.position = pos
	expl.color = col

# ─── Tutorial animation demos ─────────────────────────────────────────────────
# Shown inside the popup card. Both extend Control and self-animate via _process.
# PROCESS_MODE_ALWAYS is applied by _show_tutorial_popup before adding to tree.

class _LaneSwitchDemo extends Control:
	# Animation: car slides left → right → centre, with swipe arrows + boost flash
	var _t: float = 0.0
	const LOOP: float = 4.6

	func _process(delta: float) -> void:
		_t = fmod(_t + delta, LOOP)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var t := _t

		# Road background
		draw_rect(Rect2(0.0, 0.0, w, h), Color(0.05, 0.07, 0.13))

		# Road edges
		draw_line(Vector2(w * 0.10, 0.0), Vector2(w * 0.10, h), Color(0.50, 0.65, 0.82, 0.55), 2.0)
		draw_line(Vector2(w * 0.90, 0.0), Vector2(w * 0.90, h), Color(0.50, 0.65, 0.82, 0.55), 2.0)

		# Dashed lane dividers
		var lxs := [w * 0.367, w * 0.633]
		for lx in lxs:
			var y := 0.0
			while y < h:
				draw_line(Vector2(lx, y), Vector2(lx, minf(y + 9.0, h)), Color(0.28, 0.55, 0.75, 0.38), 1.0)
				y += 17.0

		# Lane centre X values (left / centre / right)
		var lanes := [w * 0.24, w * 0.50, w * 0.76]

		# --- animation phases --------------------------------------------------
		# 0.0→0.9  : car at centre, swipe-left arrow fades in
		# 0.9→1.5  : slide centre→left
		# 1.5→2.3  : car at left, swipe-right arrow fades in
		# 2.3→3.0  : slide left→right
		# 3.0→3.7  : car at right, BOOST glow pulse
		# 3.7→4.3  : slide right→centre
		# 4.3→4.6  : brief pause at centre
		var car_x: float
		var swipe: int = 0   # –1 left  +1 right  0 none
		var boost_f: float = 0.0

		if t < 0.9:
			car_x  = lanes[1]
			swipe  = -1 if t > 0.35 else 0
		elif t < 1.5:
			var f := _ease((t - 0.9) / 0.6)
			car_x = lerp(lanes[1], lanes[0], f)
			swipe = -1
		elif t < 2.3:
			car_x = lanes[0]
			swipe = 1 if t > 1.85 else 0
		elif t < 3.0:
			var f := _ease((t - 2.3) / 0.7)
			car_x = lerp(lanes[0], lanes[2], f)
			swipe = 1
		elif t < 3.7:
			car_x   = lanes[2]
			boost_f = clampf((t - 3.05) / 0.65, 0.0, 1.0)
		elif t < 4.3:
			var f := _ease((t - 3.7) / 0.6)
			car_x = lerp(lanes[2], lanes[1], f)
		else:
			car_x = lanes[1]

		var car_y := h * 0.64

		# Boost glow
		if boost_f > 0.0:
			var pulse := sin(boost_f * TAU * 2.8) * 0.5 + 0.5
			draw_circle(Vector2(car_x, car_y), 24.0 + pulse * 7.0,
				Color(0.00, 0.88, 1.00, 0.16 + pulse * 0.14))
			draw_circle(Vector2(car_x, car_y), 15.0,
				Color(0.00, 0.88, 1.00, 0.22 + pulse * 0.22))

		# Swipe arrow (yellow, animated fade-in)
		if swipe != 0:
			var arrow_a := clampf((t - (0.35 if swipe < 0 else 1.85)) / 0.25, 0.0, 1.0)
			var ax := car_x + swipe * 26.0
			var ay := car_y - 30.0
			var ac := Color(1.00, 0.92, 0.15, arrow_a)
			var tip  := Vector2(ax + swipe * 12.0, ay)
			var tail := Vector2(ax - swipe * 4.0,  ay)
			draw_line(tail, tip, ac, 2.5)
			draw_line(tip, tip + Vector2(-swipe * 7.0, -5.0), ac, 2.0)
			draw_line(tip, tip + Vector2(-swipe * 7.0,  5.0), ac, 2.0)

		# Mini player car (inline)
		var cw := 13.0
		var ch := 20.0
		var car_col := Color(0.35, 0.92, 1.00) if boost_f > 0.05 else Color(0.10, 0.55, 0.90)
		draw_rect(Rect2(car_x - cw*0.5, car_y - ch*0.5, cw, ch), car_col)
		draw_rect(Rect2(car_x - cw*0.35, car_y - ch*0.5 + 4.0, cw*0.70, ch*0.40),
			Color(0.05, 0.30, 0.55))
		draw_rect(Rect2(car_x - cw*0.5,  car_y - ch*0.5, cw*0.30, 3.0), Color(1.0, 0.98, 0.80))
		draw_rect(Rect2(car_x + cw*0.20, car_y - ch*0.5, cw*0.30, 3.0), Color(1.0, 0.98, 0.80))
		draw_circle(Vector2(car_x - cw*0.35, car_y + ch*0.5 - 2.0), 2.0, Color(0.90, 0.08, 0.08))
		draw_circle(Vector2(car_x + cw*0.35, car_y + ch*0.5 - 2.0), 2.0, Color(0.90, 0.08, 0.08))

	static func _ease(x: float) -> float:
		return x * x * (3.0 - 2.0 * x)   # smooth-step


# Parry demo: boss fires bullet → player boosts → bullet deflects cyan → hits boss
class _ParryDemo extends Control:
	var _t: float = 0.0
	const LOOP: float = 4.0

	func _process(delta: float) -> void:
		_t = fmod(_t + delta, LOOP)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var t := _t

		# Road background
		draw_rect(Rect2(0.0, 0.0, w, h), Color(0.05, 0.07, 0.13))

		# Road edges
		draw_line(Vector2(w * 0.10, 0.0), Vector2(w * 0.10, h), Color(0.50, 0.65, 0.82, 0.55), 2.0)
		draw_line(Vector2(w * 0.90, 0.0), Vector2(w * 0.90, h), Color(0.50, 0.65, 0.82, 0.55), 2.0)

		# Dashed lane dividers
		var lxs := [w * 0.367, w * 0.633]
		for lx in lxs:
			var y := 0.0
			while y < h:
				draw_line(Vector2(lx, y), Vector2(lx, minf(y + 9.0, h)), Color(0.28, 0.55, 0.75, 0.32), 1.0)
				y += 17.0

		var cx    := w * 0.50
		var plyr_y := h * 0.80
		var boss_y := h * 0.13

		# --- animation phases --------------------------------------------------
		# 0.0→0.6  : boss pulses, no bullet
		# 0.6→1.7  : bullet travels DOWN (orange)
		# 1.7→2.15 : bullet near player, player BOOSTS — bullet turns cyan
		# 2.15→3.0 : bullet travels UP (cyan)
		# 3.0→3.5  : boss hit flash / shockwave
		# 3.5→4.0  : reset pause

		# Boss hit flash alpha
		var boss_hit := 0.0
		if t >= 3.0 and t < 3.5:
			boss_hit = sin((t - 3.0) / 0.5 * PI)

		# Boss
		var bw  := w * 0.36
		var bh  := 14.0
		var bc  := Color(0.72 + boss_hit * 0.28, 0.12, 0.10 + boss_hit * 0.25)
		draw_rect(Rect2(cx - bw * 0.5, boss_y - bh * 0.5, bw, bh), bc)
		draw_line(Vector2(cx - bw * 0.5, boss_y - bh * 0.5),
				  Vector2(cx - bw * 0.5 - 10.0, boss_y), bc, 2.0)
		draw_line(Vector2(cx + bw * 0.5, boss_y - bh * 0.5),
				  Vector2(cx + bw * 0.5 + 10.0, boss_y), bc, 2.0)
		# boss glow when hit
		if boss_hit > 0.0:
			draw_arc(Vector2(cx, boss_y), 28.0 + boss_hit * 14.0, 0.0, TAU, 32,
				Color(1.00, 0.50, 0.10, boss_hit * 0.70), 2.0)

		# Bullet
		var blt_visible := true
		var blt_y  := boss_y + bh
		var blt_col := Color(1.00, 0.38, 0.06)
		var blt_r  := 5.0

		if t < 0.6:
			blt_visible = false
		elif t < 1.7:
			var f := (t - 0.6) / 1.1
			blt_y   = lerp(boss_y + bh + 4.0, plyr_y - 22.0, f * f * (3.0 - 2.0 * f))
		elif t < 2.15:
			# deflect moment — flashes cyan, slight oscillation
			var f := (t - 1.7) / 0.45
			blt_y   = plyr_y - 22.0 + sin(f * PI) * 5.0
			blt_col = Color(0.00, 0.88 + f * 0.12, 1.00)
			blt_r   = 5.0 + f * 2.5
		elif t < 3.0:
			var f := (t - 2.15) / 0.85
			blt_y   = lerp(plyr_y - 22.0, boss_y + bh * 0.5, f * f * (3.0 - 2.0 * f))
			blt_col = Color(0.00, 0.92, 1.00)
			blt_r   = 6.0
		else:
			blt_visible = false

		if blt_visible:
			draw_circle(Vector2(cx, blt_y), blt_r + 4.0,
				Color(blt_col.r, blt_col.g, blt_col.b, 0.25))
			draw_circle(Vector2(cx, blt_y), blt_r, blt_col)

		# Player boost aura
		var boosting := t >= 1.7 and t < 2.15
		if boosting:
			var bf    := (t - 1.7) / 0.45
			var pulse := sin(bf * TAU * 3.0) * 0.5 + 0.5
			draw_circle(Vector2(cx, plyr_y), 22.0 + pulse * 7.0,
				Color(0.00, 0.85, 1.00, 0.20 + pulse * 0.20))

		# Player mini car
		var cw := 13.0
		var ch := 20.0
		var car_col := Color(0.35, 0.92, 1.00) if boosting else Color(0.10, 0.55, 0.90)
		draw_rect(Rect2(cx - cw*0.5, plyr_y - ch*0.5, cw, ch), car_col)
		draw_rect(Rect2(cx - cw*0.35, plyr_y - ch*0.5 + 4.0, cw*0.70, ch*0.40),
			Color(0.05, 0.30, 0.55))
		draw_rect(Rect2(cx - cw*0.5,  plyr_y - ch*0.5, cw*0.30, 3.0), Color(1.0, 0.98, 0.80))
		draw_rect(Rect2(cx + cw*0.20, plyr_y - ch*0.5, cw*0.30, 3.0), Color(1.0, 0.98, 0.80))
		draw_circle(Vector2(cx - cw*0.35, plyr_y + ch*0.5 - 2.0), 2.0, Color(0.90, 0.08, 0.08))
		draw_circle(Vector2(cx + cw*0.35, plyr_y + ch*0.5 - 2.0), 2.0, Color(0.90, 0.08, 0.08))

# ─── Tutorial ─────────────────────────────────────────────────────────────────
func _show_controls_tutorial() -> void:
	await get_tree().create_timer(0.4).timeout
	_show_tutorial_popup(
		"◈  CONTROLS  ◈",
		"SWIPE left or right to change lanes\n\nTAP anywhere to BOOST\nInvincible during dash · destroys nearby enemies",
		func():
			GameState.tutorial_done = true
			GameState.save(),
		_LaneSwitchDemo.new()
	)

func _show_tutorial_popup(header: String, body: String, on_close: Callable, anim_node: Control = null) -> void:
	get_tree().paused = true

	# ── Overlay layer (always processes even while paused) ────────────────────
	var cl := CanvasLayer.new()
	cl.layer = 20
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0.00, 0.02, 0.08, 0.90)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(dim)

	# Centred card panel
	var card := Panel.new()
	card.anchor_left   = 0.0;   card.anchor_right  = 1.0
	card.anchor_top    = 0.0;   card.anchor_bottom = 1.0
	card.offset_left   = 36.0;  card.offset_right  = -36.0
	card.offset_top    = 120.0; card.offset_bottom = -120.0
	card.process_mode  = Node.PROCESS_MODE_ALWAYS
	var cs := StyleBoxFlat.new()
	cs.bg_color     = Color(0.02, 0.06, 0.17, 0.97)
	cs.border_color = Color(0.00, 0.82, 1.00)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel", cs)
	cl.add_child(card)

	# Content VBox inside the card
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left   = 22.0; vb.offset_right  = -22.0
	vb.offset_top    = 22.0; vb.offset_bottom = -22.0
	vb.add_theme_constant_override("separation", 14)
	vb.process_mode  = Node.PROCESS_MODE_ALWAYS
	card.add_child(vb)

	# Header
	var h_lbl := Label.new()
	h_lbl.text = header
	h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_lbl.add_theme_color_override("font_color", Color(0.00, 0.92, 1.00))
	h_lbl.add_theme_font_size_override("font_size", 22)
	h_lbl.process_mode = Node.PROCESS_MODE_ALWAYS
	vb.add_child(h_lbl)

	# Divider
	var div_r := ColorRect.new()
	div_r.custom_minimum_size = Vector2(0.0, 2.0)
	div_r.color = Color(0.00, 0.65, 0.90, 0.45)
	div_r.process_mode = Node.PROCESS_MODE_ALWAYS
	vb.add_child(div_r)

	# Body
	var b_lbl := Label.new()
	b_lbl.text = body
	b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_lbl.add_theme_color_override("font_color", Color(0.82, 0.96, 1.00))
	b_lbl.add_theme_font_size_override("font_size", 15)
	b_lbl.process_mode = Node.PROCESS_MODE_ALWAYS
	vb.add_child(b_lbl)

	# Animation demo (optional)
	if anim_node:
		anim_node.custom_minimum_size = Vector2(0.0, 108.0)
		anim_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		anim_node.process_mode = Node.PROCESS_MODE_ALWAYS
		vb.add_child(anim_node)

	# Flex spacer pushes button to bottom
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.process_mode = Node.PROCESS_MODE_ALWAYS
	vb.add_child(sp)

	# Continue button (centred)
	var cc := CenterContainer.new()
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.process_mode = Node.PROCESS_MODE_ALWAYS
	vb.add_child(cc)

	var btn := Button.new()
	btn.text = Locale.t("tap_to_continue")
	btn.custom_minimum_size = Vector2(220.0, 50.0)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var bs := StyleBoxFlat.new()
	bs.bg_color     = Color(0.00, 0.48, 0.78)
	bs.border_color = Color(0.00, 0.85, 1.00)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(10)
	var bs_h := bs.duplicate() as StyleBoxFlat
	bs_h.bg_color = Color(0.00, 0.60, 0.90)
	btn.add_theme_stylebox_override("normal",  bs)
	btn.add_theme_stylebox_override("hover",   bs_h)
	btn.add_theme_stylebox_override("pressed", bs)
	btn.add_theme_stylebox_override("focus",   bs)
	btn.add_theme_color_override("font_color",         Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color",   Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.95, 1.0))
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func():
		cl.queue_free()
		get_tree().paused = false
		on_close.call()
	)
	cc.add_child(btn)

# ─── Player death ─────────────────────────────────────────────────────────────
func _on_player_died() -> void:
	SFX.play_death()
	game_running   = false
	boss_active    = false
	paused_for_perk = false
	get_tree().paused = false   # kill any perk-screen pause so GameOver is interactive

	# Remove any dangling perk screens
	for child in get_children():
		if child.has_signal("perk_chosen"):
			child.queue_free()

	spawn_explosion(player.position, Color(1.0, 0.3, 0.0))
	GameState.end_run(distance, _max_damage_free_dist)

	await get_tree().create_timer(1.2).timeout

	var go = gameover_scene.instantiate()
	go.revive_requested.connect(revive_player)
	add_child(go)
	go.setup(distance,
		GameState._revival_coins + GameState.run_coins_earned,
		GameState._revival_kills + GameState.run_kills,
		GameState._revival_new_achievements + GameState.run_new_achievements)

# ─── Ad-continue revival ──────────────────────────────────────────────────────
func revive_player() -> void:
	# Called when the player watches an ad and returns to the app.
	# Pre-revival stats are already committed (end_run was called).
	# Reset per-run accumulators so the next end_run() doesn't double-count.
	GameState.start_revived_run()

	# Remove the Game Over overlay
	for node in get_tree().get_nodes_in_group("game_over_screen"):
		if is_instance_valid(node):
			node.queue_free()

	# Clear all enemies so the player has breathing room
	for e in enemies_container.get_children():
		if is_instance_valid(e):
			e.queue_free()

	# Dismiss any active boss
	if is_instance_valid(current_boss):
		current_boss.queue_free()
	current_boss = null
	boss_active   = false

	# Restore player
	var revival_hp: int = maxi(int(float(player.max_health) * 0.35), 30)
	player.health       = revival_hp
	player.revival_timer = 3.0   # 3 s of invincibility with green halo
	player.queue_redraw()
	if is_instance_valid(hud):
		hud.update_health(player.health, player.max_health)
		# Keep showing the pre-revival coin total so the counter never resets
		hud.update_coins(GameState._revival_coins)

	# Resume the game
	get_tree().paused = false
	game_running      = true

# ─── Perk screen ──────────────────────────────────────────────────────────────
func _trigger_perk_selection() -> void:
	paused_for_perk = true
	var ps = perk_scene.instantiate()
	add_child(ps)
	ps.perk_chosen.connect(_on_perk_chosen)

func _on_perk_chosen(new_perk: String, dropped_perk: String) -> void:
	if dropped_perk != "":
		GameState.remove_perk(dropped_perk)
		player.unapply_perk(dropped_perk)
	GameState.add_perk(new_perk)
	player.apply_perk(new_perk)
	perk_count += 1
	last_perk_distance = distance   # reset from the moment the perk was taken
	paused_for_perk = false
	hud.show_perk_notification(new_perk)

# ─── Cleanup ──────────────────────────────────────────────────────────────────
func _cleanup_offscreen() -> void:
	for b in bullets_container.get_children():
		if b.position.y < -120 or b.position.y > SCREEN_H + 80:
			b.queue_free()
	for c in coins_container.get_children():
		if c.position.y > SCREEN_H + 60:
			c.queue_free()
	for e in enemies_container.get_children():
		if e.position.y > SCREEN_H + 120:
			e.queue_free()

# ─── Public getters ───────────────────────────────────────────────────────────
func get_road_scroll_speed() -> float:
	return road_scroll_speed
