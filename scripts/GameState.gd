extends Node

const SAVE_PATH = "user://save.json"
const DAILY_REWARD: int = 300

# ---- Meta-progression --------------------------------------------------------
var coins: int = 0
var best_distance: float = 0.0
var gems: int = 0

var upgrades: Dictionary = {
	"max_health": 0, "starting_weapon": 0, "coin_multiplier": 0,
	"starting_speed": 0, "shield_recharge": 0,
	"explosion_radius": 0, "enemy_health_reduction": 0,
}
const UPGRADE_MAX: Dictionary = {
	"max_health": 5, "starting_weapon": 3, "coin_multiplier": 5,
	"starting_speed": 3, "shield_recharge": 4,
	"explosion_radius": 3, "enemy_health_reduction": 5,
}
const UPGRADE_COSTS: Dictionary = {
	"max_health":            [100, 200, 400, 800, 1600],
	"starting_weapon":       [150, 300, 600],
	"coin_multiplier":       [200, 400, 800, 1600, 3200],
	"starting_speed":        [100, 200, 400],
	"shield_recharge":       [150, 300, 600, 1200],
	"explosion_radius":      [100, 200, 400],
	"enemy_health_reduction":[200, 400, 800, 1600, 3200],
}
const UPGRADE_NAMES: Dictionary = {
	"max_health":            "Max Health",
	"starting_weapon":       "Starting Weapon Tier",
	"coin_multiplier":       "Coin Multiplier",
	"starting_speed":        "Starting Speed",
	"shield_recharge":       "Shield Recharge Rate",
	"explosion_radius":      "Explosion Radius",
	"enemy_health_reduction":"Enemy Health Reduction",
}

# ---- Shop — skins ------------------------------------------------------------
var owned_skins: Array = ["default"]
var active_skin: String = "default"

const SKINS: Array = [
	{"key": "default",    "name": "STEEL BLUE",    "color": Color(0.20, 0.60, 1.00), "price": 0,    "currency": "coins"},
	{"key": "crimson",    "name": "CRIMSON",        "color": Color(0.85, 0.10, 0.10), "price": 300,  "currency": "coins"},
	{"key": "inferno",    "name": "INFERNO",        "color": Color(1.00, 0.35, 0.00), "price": 500,  "currency": "coins"},
	{"key": "stealth",    "name": "STEALTH",        "color": Color(0.12, 0.12, 0.18), "price": 600,  "currency": "coins"},
	{"key": "forest",     "name": "FOREST GHOST",   "color": Color(0.15, 0.58, 0.12), "price": 750,  "currency": "coins"},
	{"key": "neon",       "name": "NEON PHANTOM",   "color": Color(0.00, 0.88, 1.00), "price": 900,  "currency": "coins"},
	{"key": "ice",        "name": "ICE BLADE",      "color": Color(0.55, 0.80, 1.00), "price": 1100, "currency": "coins"},
	{"key": "rose",       "name": "ROSE",           "color": Color(0.95, 0.28, 0.55), "price": 1300, "currency": "coins"},
	{"key": "gold",       "name": "GOLD RUSH",      "color": Color(1.00, 0.78, 0.00), "price": 1500, "currency": "coins"},
	{"key": "toxic",      "name": "TOXIC",          "color": Color(0.20, 0.95, 0.30), "price": 1800, "currency": "coins"},
	{"key": "chrome",     "name": "CHROME",         "color": Color(0.78, 0.78, 0.82), "price": 2000, "currency": "coins"},
	{"key": "obsidian",   "name": "OBSIDIAN",       "color": Color(0.08, 0.08, 0.12), "price": 2200, "currency": "coins"},
	{"key": "void",       "name": "VOID WALKER",    "color": Color(0.32, 0.00, 0.52), "price": 2500, "currency": "coins"},
	{"key": "coral",      "name": "CORAL",          "color": Color(0.98, 0.50, 0.45), "price": 2800, "currency": "coins"},
	{"key": "ultraviolet","name": "ULTRAVIOLET",    "color": Color(0.55, 0.00, 0.95), "price": 3500, "currency": "coins"},
]

func get_skin_color() -> Color:
	for s in SKINS:
		if s["key"] == active_skin:
			return s["color"]
	return Color(0.20, 0.60, 1.00)

func set_active_skin(key: String) -> void:
	active_skin = key
	save()

func buy_skin(key: String) -> bool:
	for s in SKINS:
		if s["key"] != key:
			continue
		if owned_skins.has(key):
			set_active_skin(key)
			return true
		if s["currency"] == "coins" and coins >= s["price"]:
			coins -= s["price"]
			owned_skins.append(key)
			set_active_skin(key)
			return true
	return false

# ---- Shop — boosts (single-use, spend coins) --------------------------------
const BOOSTS: Array = [
	{"key": "armor_plate", "name": "Armor Plate", "desc": "+50 max HP next run",            "price": 80},
	{"key": "lucky_coins", "name": "Lucky Coins",  "desc": "+60% coins earned next run",     "price": 100},
	{"key": "field_medic", "name": "Field Medic",  "desc": "Auto-heal 25 HP once at low HP", "price": 120},
	{"key": "head_start",  "name": "Head Start",   "desc": "Begin 400 m ahead next run",     "price": 150},
]

# ---- Shop — premium (single-use, spend gems) --------------------------------
const PREMIUM: Array = [
	{"key": "resurrection", "name": "Resurrection", "desc": "Revive once with 40 HP when you die",  "price": 35},
	{"key": "overdrive",    "name": "Overdrive",    "desc": "Start run with Rapid Fire active",     "price": 28},
	{"key": "war_machine",  "name": "War Machine",  "desc": "+20% bullet damage next run",          "price": 45},
]

# ---- Consumable inventory + active-run snapshot -----------------------------
var consumables: Dictionary = {
	"armor_plate": 0, "lucky_coins": 0, "field_medic": 0, "head_start": 0,
	"resurrection": 0, "overdrive": 0, "war_machine": 0,
}
var run_active_consumables: Dictionary = {}   # set at start_run(); read during the run

func buy_boost(key: String) -> bool:
	for b in BOOSTS:
		if b["key"] == key and coins >= b["price"]:
			coins -= b["price"]
			consumables[key] += 1
			save()
			return true
	return false

func buy_premium(key: String) -> bool:
	for p in PREMIUM:
		if p["key"] == key and gems >= p["price"]:
			gems -= p["price"]
			consumables[key] += 1
			save()
			return true
	return false

func earn_gems(amount: int) -> void:
	gems += amount
	# save() called by callers via end_run / other save points

# ---- Lifetime stats ----------------------------------------------------------
var total_runs: int = 0
var total_kills: int = 0
var bosses_defeated: int = 0
var best_run_kills: int = 0

# ---- Per-run state -----------------------------------------------------------
var current_perks: Array = []
var run_coins_earned: int = 0
var run_kills: int = 0
var run_bosses: int = 0
var run_ram_kills: int = 0
var run_max_perks: int = 0
var run_new_achievements: Array = []
var run_ad_used: bool = false   # one free revival per run via ad
# Pre-revival snapshot — zeroed by start_run(); filled by start_revived_run()
var _revival_coins: int = 0
var _revival_kills: int = 0
var _revival_ram_kills: int = 0
var _revival_bosses: int = 0
var _revival_new_achievements: Array = []

# ---- Achievements ------------------------------------------------------------
const ACHIEVEMENTS: Array = [
	{"key": "first_run",    "name": "First Blood",      "desc": "Complete a run",                  "reward": 50},
	{"key": "first_boss",   "name": "Boss Slayer",      "desc": "Defeat your first boss",           "reward": 200},
	{"key": "road_warrior", "name": "Road Warrior",     "desc": "Reach 1500 m in one run",          "reward": 100},
	{"key": "speedrunner",  "name": "Speed Runner",     "desc": "Reach 3000 m in one run",          "reward": 150},
	{"key": "long_haul",    "name": "Long Haul",        "desc": "Reach 5000 m in one run",          "reward": 500},
	{"key": "speed_demon",  "name": "Speed Demon",      "desc": "Reach 10000 m in one run",         "reward": 800},
	{"key": "endless",      "name": "Endless Runner",   "desc": "Reach 15000 m in one run",         "reward": 1500},
	{"key": "ram_rage",     "name": "Ram Rage",         "desc": "Ram 15 enemies in one run",        "reward": 150},
	{"key": "ram_god",      "name": "Ram God",          "desc": "Ram 30 enemies in one run",        "reward": 250},
	{"key": "untouchable",  "name": "Untouchable",      "desc": "800 m without taking damage",      "reward": 300},
	{"key": "unstoppable",  "name": "Unstoppable",      "desc": "2000 m without taking damage",     "reward": 500},
	{"key": "veteran",      "name": "Veteran",          "desc": "Complete 10 total runs",           "reward": 250},
	{"key": "survivor",     "name": "Survivor",         "desc": "Complete 25 total runs",           "reward": 300},
	{"key": "zone_clearer", "name": "Zone Clearer",     "desc": "Defeat 5 bosses total",            "reward": 400},
	{"key": "boss_hunter",  "name": "Boss Hunter",      "desc": "Defeat 10 bosses total",           "reward": 400},
	{"key": "legend",       "name": "Legend",           "desc": "Defeat 25 bosses total",           "reward": 1000},
	{"key": "death_machine","name": "Death Machine",    "desc": "Kill 50 enemies in one run",       "reward": 200},
	{"key": "perk_master",  "name": "Perk Master",      "desc": "Fill all 3 perk slots in one run", "reward": 150},
	{"key": "coin_hoarder", "name": "Coin Hoarder",     "desc": "Earn 500 coins in one run",        "reward": 200},
	{"key": "boss_rush",    "name": "Boss Rush",        "desc": "Defeat 3 bosses in one run",       "reward": 350},
]
var achievements: Dictionary = {
	"first_run": false,   "first_boss": false,   "road_warrior": false, "speedrunner": false,
	"long_haul": false,   "speed_demon": false,  "endless": false,      "ram_rage": false,
	"ram_god": false,     "untouchable": false,  "unstoppable": false,  "veteran": false,
	"survivor": false,    "zone_clearer": false, "boss_hunter": false,  "legend": false,
	"death_machine": false, "perk_master": false, "coin_hoarder": false, "boss_rush": false,
}

# ---- Tutorial ----------------------------------------------------------------
var tutorial_done: bool = false
var parry_tutorial_done: bool = false

# ---- Settings ----------------------------------------------------------------
var language: String = "en"          # "en" or "fa"
var music_volume: float = 0.70       # 0.0 – 1.0
var sfx_volume: float = 0.80         # 0.0 – 1.0

# ---- Daily challenge ---------------------------------------------------------
var daily_date: String = ""
var daily_type: String = ""
var daily_target: int = 0
var daily_progress: int = 0
var daily_done: bool = false

# ---- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	load_data()
	_refresh_daily()

func start_run() -> void:
	current_perks.clear()
	run_coins_earned = 0
	run_kills = 0
	run_bosses = 0
	run_ram_kills = 0
	run_max_perks = 0
	run_new_achievements = []
	run_ad_used = false
	_revival_coins = 0
	_revival_kills = 0
	_revival_ram_kills = 0
	_revival_bosses = 0
	_revival_new_achievements = []
	total_runs += 1
	_refresh_daily()

	# Activate consumables for this run (deduct 1 of each owned)
	run_active_consumables = {}
	for key in consumables.keys():
		if consumables[key] > 0:
			run_active_consumables[key] = true
			consumables[key] -= 1
	save()

func start_revived_run() -> void:
	# Called when the player watches an ad and continues the run.
	# end_run() already committed the pre-revival stats (coins, kills, bosses).
	# Save pre-revival totals so the final GameOver can show full-run figures,
	# then reset per-run accumulators so end_run() doesn't double-count.
	_revival_coins            = run_coins_earned
	_revival_kills            = run_kills
	_revival_bosses           = run_bosses
	_revival_ram_kills        = run_ram_kills
	_revival_new_achievements = run_new_achievements.duplicate()
	run_ad_used = true
	run_coins_earned = 0
	run_kills = 0
	run_bosses = 0
	run_ram_kills = 0
	run_new_achievements = []
	# do NOT reset run_max_perks — perks were earned earlier and still apply

func earn_run_coins(amount: int) -> void:
	var mult: float = get_coin_multiplier()
	if run_active_consumables.get("lucky_coins", false):
		mult += 0.60
	run_coins_earned += int(amount * mult)

func end_run(distance: float, max_damage_free: float) -> void:
	if distance > best_distance:
		best_distance = distance
	if run_kills > best_run_kills:
		best_run_kills = run_kills
	coins += run_coins_earned
	total_kills += run_kills
	bosses_defeated += run_bosses
	_check_achievements(distance, max_damage_free)
	_update_daily(distance)
	save()

# ---- Derived stats -----------------------------------------------------------
func get_max_health() -> int:
	return 100 + upgrades["max_health"] * 25

func get_coin_multiplier() -> float:
	return 1.0 + upgrades["coin_multiplier"] * 0.25

func get_starting_speed_bonus() -> float:
	return upgrades["starting_speed"] * 40.0

func get_explosion_radius_bonus() -> float:
	return upgrades["explosion_radius"] * 20.0

func get_enemy_health_multiplier() -> float:
	return 1.0 - upgrades["enemy_health_reduction"] * 0.08

func get_shield_recharge_rate() -> float:
	return 1.0 + upgrades["shield_recharge"] * 0.5

# ---- Perk helpers ------------------------------------------------------------
func has_perk(perk_name: String) -> bool:
	return perk_name in current_perks

func add_perk(perk_name: String) -> void:
	if not has_perk(perk_name):
		current_perks.append(perk_name)
		if current_perks.size() > run_max_perks:
			run_max_perks = current_perks.size()

func remove_perk(perk_name: String) -> void:
	current_perks.erase(perk_name)

# ---- Upgrade shop ------------------------------------------------------------
func can_upgrade(key: String) -> bool:
	var lvl = upgrades[key]
	if lvl >= UPGRADE_MAX[key]:
		return false
	return coins >= UPGRADE_COSTS[key][lvl]

func buy_upgrade(key: String) -> bool:
	if not can_upgrade(key):
		return false
	coins -= UPGRADE_COSTS[key][upgrades[key]]
	upgrades[key] += 1
	save()
	return true

func get_upgrade_cost(key: String) -> int:
	var lvl = upgrades[key]
	if lvl >= UPGRADE_MAX[key]:
		return -1
	return UPGRADE_COSTS[key][lvl]

# ---- Achievement logic -------------------------------------------------------
func _check_achievements(distance: float, max_damage_free: float) -> void:
	var conds: Dictionary = {
		"first_run":    true,
		"first_boss":   _revival_bosses + run_bosses >= 1,
		"road_warrior": distance >= 1500.0,
		"speedrunner":  distance >= 3000.0,
		"long_haul":    distance >= 5000.0,
		"speed_demon":  distance >= 10000.0,
		"endless":      distance >= 15000.0,
		"ram_rage":     _revival_ram_kills + run_ram_kills >= 15,
		"ram_god":      _revival_ram_kills + run_ram_kills >= 30,
		"untouchable":  max_damage_free >= 800.0,
		"unstoppable":  max_damage_free >= 2000.0,
		"veteran":      total_runs >= 10,
		"survivor":     total_runs >= 25,
		"zone_clearer": bosses_defeated >= 5,
		"boss_hunter":  bosses_defeated >= 10,
		"legend":       bosses_defeated >= 25,
		"death_machine":_revival_kills + run_kills >= 50,
		"perk_master":  run_max_perks >= 3,
		"coin_hoarder": _revival_coins + run_coins_earned >= 500,
		"boss_rush":    _revival_bosses + run_bosses >= 3,
	}
	for key in conds.keys():
		if conds[key] and not achievements.get(key, false):
			achievements[key] = true
			coins += get_achievement_reward(key)
			gems  += 10    # gem bonus for every achievement
			run_new_achievements.append(key)

func get_achievement_reward(key: String) -> int:
	for a in ACHIEVEMENTS:
		if a["key"] == key:
			return a["reward"]
	return 0

func get_achievement_name(key: String) -> String:
	for a in ACHIEVEMENTS:
		if a["key"] == key:
			return a["name"]
	return key

func get_unlocked_count() -> int:
	var c: int = 0
	for k in achievements:
		if achievements[k]:
			c += 1
	return c

# ---- Daily challenge ---------------------------------------------------------
func _refresh_daily() -> void:
	var today: String = Time.get_date_string_from_system()
	if daily_date != today:
		daily_date = today
		daily_done = false
		daily_progress = 0
		_generate_daily()
		save()

func _generate_daily() -> void:
	var h: int = daily_date.hash()
	var types: Array = ["distance", "kills", "boss", "ram"]
	daily_type = types[abs(h) % types.size()]
	var r: int = abs(h >> 4) % 10
	match daily_type:
		"distance": daily_target = 800  + r * 200
		"kills":    daily_target = 10   + r * 3
		"boss":     daily_target = 1
		"ram":      daily_target = 5    + (r % 6) * 2

func _update_daily(distance: float) -> void:
	if daily_done:
		return
	var val: int = 0
	match daily_type:
		"distance": val = int(distance)
		"kills":    val = _revival_kills + run_kills
		"boss":     val = _revival_bosses + run_bosses
		"ram":      val = _revival_ram_kills + run_ram_kills
	if val > daily_progress:
		daily_progress = val
	if daily_progress >= daily_target:
		daily_done = true
		coins += DAILY_REWARD
		gems  += 5    # gem bonus for daily completion

func get_daily_text() -> String:
	match daily_type:
		"distance": return "Travel %d m in one run" % daily_target
		"kills":    return "Kill %d enemies in one run" % daily_target
		"boss":     return "Defeat the boss"
		"ram":      return "Ram %d enemies with boost" % daily_target
		_:          return "Complete a run"

func get_daily_progress_text() -> String:
	if daily_done:
		return "COMPLETED!"
	match daily_type:
		"distance": return "%d / %d m" % [daily_progress, daily_target]
		"kills":    return "%d / %d kills" % [daily_progress, daily_target]
		"boss":     return "%d / %d boss" % [daily_progress, daily_target]
		"ram":      return "%d / %d rams" % [daily_progress, daily_target]
		_:          return "0 / 1"

# ---- Save / Load -------------------------------------------------------------
func save() -> void:
	var data: Dictionary = {
		"coins":         coins,         "best_distance":  best_distance,
		"gems":          gems,          "upgrades":       upgrades,
		"owned_skins":   owned_skins,   "active_skin":    active_skin,
		"consumables":   consumables,
		"total_runs":    total_runs,    "total_kills":    total_kills,
		"bosses_defeated":bosses_defeated,"best_run_kills":best_run_kills,
		"achievements":  achievements,
		"daily_date":    daily_date,    "daily_type":     daily_type,
		"daily_target":  daily_target,  "daily_progress": daily_progress,
		"daily_done":    daily_done,
		"tutorial_done": tutorial_done,
		"parry_tutorial_done": parry_tutorial_done,
		"language":      language,
		"music_volume":  music_volume,
		"sfx_volume":    sfx_volume,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var d = json.get_data()
	if not d is Dictionary:
		return
	coins           = d.get("coins",          0)
	best_distance   = d.get("best_distance",  0.0)
	gems            = d.get("gems",           0)
	total_runs      = d.get("total_runs",     0)
	total_kills     = d.get("total_kills",    0)
	bosses_defeated = d.get("bosses_defeated",0)
	best_run_kills  = d.get("best_run_kills", 0)
	active_skin     = d.get("active_skin",    "default")
	var saved_skins: Array = d.get("owned_skins", [])
	if saved_skins.size() > 0:
		owned_skins = saved_skins
	var saved_upg: Dictionary = d.get("upgrades", {})
	for k in upgrades.keys():
		if saved_upg.has(k):
			upgrades[k] = saved_upg[k]
	var saved_ach: Dictionary = d.get("achievements", {})
	for k in achievements.keys():
		if saved_ach.has(k):
			achievements[k] = saved_ach[k]
	var saved_cons: Dictionary = d.get("consumables", {})
	for k in consumables.keys():
		if saved_cons.has(k):
			consumables[k] = saved_cons[k]
	daily_date     = d.get("daily_date",     "")
	daily_type     = d.get("daily_type",     "")
	daily_target   = d.get("daily_target",   0)
	daily_progress = d.get("daily_progress", 0)
	daily_done     = d.get("daily_done",     false)
	tutorial_done        = d.get("tutorial_done",        false)
	parry_tutorial_done  = d.get("parry_tutorial_done",  false)
	language       = d.get("language",      "en")
	music_volume   = d.get("music_volume",  0.70)
	sfx_volume     = d.get("sfx_volume",    0.80)
