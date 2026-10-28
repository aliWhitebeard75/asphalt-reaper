extends Node
# Translation autoload.  Call  Locale.t("key")  anywhere for translated text.
# Language is stored in GameState.language ("en" or "fa").
# Persian (Farsi) text is stored as UTF-8 strings directly in this file.

# ── Helpers ───────────────────────────────────────────────────────────────────
func lang() -> String:
	return GameState.language if GameState else "en"

func t(key: String) -> String:
	var l := lang()
	if l == "fa" and FA.has(key):
		return FA[key]
	if EN.has(key):
		return EN[key]
	return key   # fallback: return key itself

# ── English strings ───────────────────────────────────────────────────────────
const EN: Dictionary = {
	# MainMenu
	"title":          "ASPHALT\nREAPER",
	"tagline":        "SURVIVE  ◈  UPGRADE  ◈  REPEAT",
	"btn_engage":     "▶  ENGAGE",
	"btn_armory":     "◆  ARMORY",
	"btn_briefing":   "?  BRIEFING",
	"btn_disconnect": "DISCONNECT",
	"btn_settings":   "⚙  SETTINGS",
	"hint_controls":  "⟨ SWIPE TO STEER  ◈  TAP TO BOOST ⟩",

	# Settings
	"settings_title":    "SETTINGS",
	"music_volume":      "Music Volume",
	"sfx_volume":        "SFX Volume",
	"language_label":    "Language",
	"lang_en":           "ENGLISH",
	"lang_fa":           "فارسی",
	"btn_back":          "← BACK",
	"btn_yes":           "YES",
	"btn_no":            "NO",
	"lang_confirm":      "Language will change and the game will restart.",

	# Garage
	"garage_title":     "GARAGE",
	"daily_challenge":  "DAILY CHALLENGE",
	"reward_label":     "Reward",
	"btn_play":         "START RUN",
	"btn_shop":         "SHOP",
	"max_level":        "MAX",
	"upgrade_btn":      "UPGRADE",

	# Upgrade names
	"upg_max_health":            "Max Health",
	"upg_coin_multiplier":       "Coin Multiplier",
	"upg_starting_speed":        "Starting Speed",
	"upg_shield_recharge":       "Shield Recharge Rate",
	"upg_explosion_radius":      "Explosion Radius",
	"upg_enemy_health_reduction":"Enemy Health Reduction",
	"upg_starting_weapon":       "Starting Weapon Tier",

	# Upgrade descriptions
	"desc_max_health":            "More armour keeps you alive longer.",
	"desc_coin_multiplier":       "Earn more coins every run.",
	"desc_starting_speed":        "Hit the road faster each time.",
	"desc_shield_recharge":       "Shield bounces back quicker.",
	"desc_explosion_radius":      "Bigger blasts, wider destruction.",
	"desc_enemy_health_reduction":"Enemies spawn weaker.",
	"desc_starting_weapon":       "Start with a stronger loadout.",

	# Upgrade effects
	"eff_max_health":            "+25 HP",
	"eff_coin_multiplier":       "+25%",
	"eff_starting_speed":        "+40 km/h",
	"eff_shield_recharge":       "+50% rate",
	"eff_explosion_radius":      "+20 radius",
	"eff_enemy_health_reduction":"-8% enemy HP",
	"eff_starting_weapon":       "+1 tier",

	# Stats footer
	"stat_runs":         "Runs",
	"stat_kills":        "Kills",
	"stat_bosses":       "Bosses",
	"stat_achievements": "Achievements",

	# Daily challenge descriptions
	"daily_distance":  "Travel %d m in one run",
	"daily_kills":     "Kill %d enemies in one run",
	"daily_boss":      "Defeat the boss",
	"daily_ram":       "Ram %d enemies with boost",
	"daily_fallback":  "Complete a run",
	"completed":       "COMPLETED!",
	"m_unit":          "m",
	"kills_unit":      "kills",
	"boss_unit":       "boss",
	"rams_unit":       "rams",

	# Shop
	"shop_title":      "ARMORY",
	"tab_skins":       "SKINS",
	"tab_boosts":      "BOOSTS",
	"tab_premium":     "♦ GEMS",
	"equipped":        "EQUIPPED",
	"owned":           "owned",
	"free_label":      "FREE",
	"active_label":    "ACTIVE",
	"btn_equip":       "EQUIP",
	"btn_buy":         "BUY",
	"locked_label":    "LOCKED",
	"single_use_note": "Single-use · activates at next run start",
	"gems_earn_note":  "Earned from achievements & daily challenges",
	"coins_label":     "COINS",
	"gems_label":      "GEMS",

	# Boosts
	"boost_armor_plate": "Armor Plate",
	"boost_lucky_coins": "Lucky Coins",
	"boost_field_medic": "Field Medic",
	"boost_head_start":  "Head Start",
	"desc_armor_plate":  "+50 max HP next run",
	"desc_lucky_coins":  "+60% coins earned next run",
	"desc_field_medic":  "Auto-heal 25 HP once at low HP",
	"desc_head_start":   "Begin 400 m ahead next run",

	# Premium
	"prem_resurrection": "Resurrection",
	"prem_overdrive":    "Overdrive",
	"prem_war_machine":  "War Machine",
	"desc_resurrection": "Revive once with 40 HP when you die",
	"desc_overdrive":    "Start run with Rapid Fire active",
	"desc_war_machine":  "+20% bullet damage next run",

	# Skin names
	"skin_default":     "STEEL BLUE",
	"skin_crimson":     "CRIMSON",
	"skin_inferno":     "INFERNO",
	"skin_stealth":     "STEALTH",
	"skin_forest":      "FOREST GHOST",
	"skin_neon":        "NEON PHANTOM",
	"skin_ice":         "ICE BLADE",
	"skin_rose":        "ROSE",
	"skin_gold":        "GOLD RUSH",
	"skin_toxic":       "TOXIC",
	"skin_chrome":      "CHROME",
	"skin_obsidian":    "OBSIDIAN",
	"skin_void":        "VOID WALKER",
	"skin_coral":       "CORAL",
	"skin_ultraviolet": "ULTRAVIOLET",

	# HUD
	"perks_label":   "PERKS",
	"phase_label":   "PHASE",
	"coins_hud":     "◆",

	# Ad-continue button (GameOver)
	"ad_btn_ready":       "▶  WATCH AD  •  CONTINUE",
	"ad_btn_loading":     "⏳  Loading Ad...",
	"ad_btn_watching":    "Watching...",
	"ad_btn_unavailable": "▶  WATCH AD  •  CONTINUE  (unavailable)",
	"ad_btn_no_plugin":   "▶  WATCH AD  (plugin not loaded)",
	"ad_btn_timeout":     "Ad Unavailable",

	# PerkScreen
	"perk_replace_title": "REPLACE A PERK",
	"perk_adding_prefix": "Adding:  ",
	"perk_slot_open":     "— open",

	# Main scene
	"tap_to_continue":    "TAP TO CONTINUE",

	# HUD
	"best_none":          "BEST — m",
	"best_value":         "BEST %.0f m",

	# Tutorial — page titles
	"tut_controls_title": "PILOT CONTROLS",
	"tut_enemies_title":  "ENEMY FIELD GUIDE",
	"tut_ready_title":    "YOU'RE READY, PILOT",

	# Tutorial — controls page
	"tut_hint_swipe":        "← SWIPE →",
	"tut_hint_swipe_desc":   "Change lane",
	"tut_hint_boost":        "▲  HOLD",
	"tut_hint_boost_desc":   "BOOST  —  invincible + destroys on ram",
	"tut_hint_coins":        "◆  Coins",
	"tut_hint_coins_desc":   "collect to upgrade between runs",
	"tut_btn_next_enemies":  "NEXT: ENEMIES  ▶",
	"tut_btn_next_gotime":   "NEXT: GO TIME  ▶",
	"tut_btn_skip":          "SKIP",
	"tut_btn_engage":        "▶  ENGAGE — START RUN",

	# Tutorial — enemy page
	"tut_page1_sub":      "Know what you're up against",
	"tut_name_grunt":     "GRUNT",
	"tut_name_shooter":   "SHOOTER",
	"tut_name_speeder":   "SPEEDER",
	"tut_name_kamikaze":  "KAMIKAZE",
	"tut_name_tank":      "TANK",
	"tut_name_boss":      "BOSS",
	"tut_warn_grunt":     "Rams you sideways",
	"tut_warn_shooter":   "Fires bullets from range",
	"tut_warn_speeder":   "Fast weaving racer",
	"tut_warn_kamikaze":  "⚠ HEAVY DAMAGE",
	"tut_warn_tank":      "⛊ INVINCIBLE — dodge",
	"tut_warn_boss":      "3 phases, charge attacks",
	"tut_tip_grunt":      "→ Boost-ram or stay in different lane",
	"tut_tip_shooter":    "→ Dodge bullets, close the gap",
	"tut_tip_speeder":    "→ Boost before it flanks you",
	"tut_tip_kamikaze":   "→ BOOST AWAY the moment you see it",
	"tut_tip_tank":       "→ STEER AROUND IT. Cannot be killed.",
	"tut_tip_boss":       "→ Boost through charge attacks",

	# Tutorial — ready page
	"tut_perks_header":   "✦  PERKS",
	"tut_boss_header":    "◉  BOSS FIGHTS",
	"tut_perk_desc":      "Every 1000 m, choose 1 of 3 perks to keep for the run.\nHold up to 3 at once — drop one to swap.",
	"tut_phase_1":        "Phase 1",
	"tut_phase_2":        "Phase 2",
	"tut_phase_3":        "Phase 3",
	"tut_phase_1_desc":   "Spread shots",
	"tut_phase_2_desc":   "Charge dash + barrage",
	"tut_phase_3_desc":   "Full arsenal + orbs",
	"tut_boost_tip":      "→ BOOST through charge attacks",

	# GameOver
	"wrecked":       "WRECKED",
	"distance_lbl":  "DISTANCE",
	"coins_lbl":     "COINS",
	"kills_lbl":     "KILLS",
	"best_lbl":      "BEST",
	"btn_restart":   "DRIVE AGAIN",
	"btn_garage":    "GARAGE",
	"achievements_banner": "-- ACHIEVEMENTS UNLOCKED --",
	"achievement_reward":  "+%d coins",

	# Perk names (as displayed in HUD slots)
	"perk_Rapid Fire":      "Rapid Fire",
	"perk_Afterburner":     "Afterburner",
	"perk_Shield Bubble":   "Shield Bubble",
	"perk_Lifesteal":       "Lifesteal",
	"perk_Ram Fury":        "Ram Fury",
	"perk_Magnet Aura":     "Magnet Aura",
	"perk_Double Coins":    "Double Coins",
	"perk_Ricochet Shots":   "Ricochet Shots",
	"perk_Chain Explosion":  "Chain Explosion",
	"perk_Homing Shots":     "Homing Shots",
	"perk_Explosive Rounds": "Explosive Rounds",
	"perk_Piercing Shot":    "Piercing Shot",
	"perk_Overload":         "Overload",
	"perk_Twin Barrels":     "Twin Barrels",
	"perk_Adrenaline":       "Adrenaline",
	"perk_Iron Skin":        "Iron Skin",
	"perk_Nano Repair":      "Nano Repair",
	"perk_Battle Hardened":  "Battle Hardened",
	"perk_Scavenger":        "Scavenger",
	"perk_Turbo Engine":     "Turbo Engine",
	"perk_Lucky Strike":     "Lucky Strike",
	"perk_Coin Rush":        "Coin Rush",
	"perk_Nemesis":          "Nemesis",
	"perk_Executioner":      "Executioner",

	# Environment zone names (indices 0-24)
	"env_0":  "CITY HIGHWAY",     "env_1":  "DESERT ROAD",
	"env_2":  "NIGHT CITY",       "env_3":  "ICE ROAD",
	"env_4":  "VOLCANO PASS",     "env_5":  "FOREST TRACK",
	"env_6":  "INDUSTRIAL ZONE",  "env_7":  "COASTAL ROAD",
	"env_8":  "UNDERGROUND TUNNEL","env_9": "SPACE HIGHWAY",
	"env_10": "NEON WASTELAND",   "env_11": "CRIMSON BADLANDS",
	"env_12": "CRYSTAL CAVERNS",  "env_13": "TOXIC SWAMP",
	"env_14": "ARCTIC TUNDRA",    "env_15": "STORM CORRIDOR",
	"env_16": "CYBERPUNK SLUMS",  "env_17": "LAVA FIELDS",
	"env_18": "SKY BRIDGE",       "env_19": "HAUNTED HIGHWAY",
	"env_20": "BLOOD MOON PASS",  "env_21": "QUANTUM GRID",
	"env_22": "SHADOW REALM",     "env_23": "CHROME CITY",
	"env_24": "VOID CORRIDOR",

	# Achievement names
	"ach_first_run":     "First Blood",
	"ach_first_boss":    "Boss Slayer",
	"ach_road_warrior":  "Road Warrior",
	"ach_speedrunner":   "Speed Runner",
	"ach_long_haul":     "Long Haul",
	"ach_speed_demon":   "Speed Demon",
	"ach_endless":       "Endless Runner",
	"ach_ram_rage":      "Ram Rage",
	"ach_ram_god":       "Ram God",
	"ach_untouchable":   "Untouchable",
	"ach_unstoppable":   "Unstoppable",
	"ach_veteran":       "Veteran",
	"ach_survivor":      "Survivor",
	"ach_zone_clearer":  "Zone Clearer",
	"ach_boss_hunter":   "Boss Hunter",
	"ach_legend":        "Legend",
	"ach_death_machine": "Death Machine",
	"ach_perk_master":   "Perk Master",
	"ach_coin_hoarder":  "Coin Hoarder",
	"ach_boss_rush":     "Boss Rush",
}

# ── Persian (Farsi) strings ───────────────────────────────────────────────────
const FA: Dictionary = {
	# MainMenu
	"title":          "آسفالت\nریپر",
	"tagline":        "بقا  ◈  ارتقا  ◈  تکرار",
	"btn_engage":     "▶  شروع",
	"btn_armory":     "◆  زرادخانه",
	"btn_briefing":   "?  راهنما",
	"btn_disconnect": "خروج",
	"btn_settings":   "⚙  تنظیمات",
	"hint_controls":  "⟨ بکش برای فرمان  ◈  لمس برای تقویت ⟩",

	# Settings
	"settings_title":    "تنظیمات",
	"music_volume":      "صدای موسیقی",
	"sfx_volume":        "صدای جلوه‌ها",
	"language_label":    "زبان",
	"lang_en":           "ENGLISH",
	"lang_fa":           "فارسی",
	"btn_back":          "بازگشت ←",
	"btn_yes":           "بله",
	"btn_no":            "نه",
	"lang_confirm":      "زبان تغییر می‌کند و بازی ری‌استارت می‌شود.",

	# Garage
	"garage_title":     "گاراژ",
	"daily_challenge":  "چالش روزانه",
	"reward_label":     "جایزه",
	"btn_play":         "شروع مسیر",
	"btn_shop":         "فروشگاه",
	"max_level":        "حداکثر",
	"upgrade_btn":      "ارتقا",

	# Upgrade names
	"upg_max_health":            "حداکثر سلامتی",
	"upg_coin_multiplier":       "ضریب سکه",
	"upg_starting_speed":        "سرعت اولیه",
	"upg_shield_recharge":       "نرخ شارژ سپر",
	"upg_explosion_radius":      "شعاع انفجار",
	"upg_enemy_health_reduction":"کاهش سلامت دشمن",
	"upg_starting_weapon":       "سطح سلاح اولیه",

	# Upgrade descriptions
	"desc_max_health":            "زره بیشتر، زنده‌تر می‌مانی.",
	"desc_coin_multiplier":       "هر بار سکه بیشتری کسب کن.",
	"desc_starting_speed":        "هر بار سریع‌تر شروع کن.",
	"desc_shield_recharge":       "سپر سریع‌تر شارژ می‌شود.",
	"desc_explosion_radius":      "انفجار قوی‌تر، ویرانی گسترده‌تر.",
	"desc_enemy_health_reduction":"دشمنان ضعیف‌تر ظاهر می‌شوند.",
	"desc_starting_weapon":       "با تجهیزات قوی‌تر شروع کن.",

	# Upgrade effects
	"eff_max_health":            "+۲۵ HP",
	"eff_coin_multiplier":       "+۲۵٪",
	"eff_starting_speed":        "+۴۰ km/h",
	"eff_shield_recharge":       "+۵۰٪ نرخ",
	"eff_explosion_radius":      "+۲۰ شعاع",
	"eff_enemy_health_reduction":"-۸٪ HP دشمن",
	"eff_starting_weapon":       "+۱ سطح",

	# Stats footer
	"stat_runs":         "دفعات",
	"stat_kills":        "کشتار",
	"stat_bosses":       "رئیس‌ها",
	"stat_achievements": "دستاوردها",

	# Daily challenge
	"daily_distance":  "%d متر را در یک مسیر طی کن",
	"daily_kills":     "%d دشمن را در یک مسیر بکش",
	"daily_boss":      "رئیس را شکست بده",
	"daily_ram":       "با تقویت %d دشمن را له کن",
	"daily_fallback":  "یک مسیر را تمام کن",
	"completed":       "تکمیل شد!",
	"m_unit":          "متر",
	"kills_unit":      "کشته",
	"boss_unit":       "رئیس",
	"rams_unit":       "له",

	# Shop
	"shop_title":      "زرادخانه",
	"tab_skins":       "رنگ‌ها",
	"tab_boosts":      "تقویت‌ها",
	"tab_premium":     "♦ جواهر",
	"equipped":        "پوشیده شده",
	"owned":           "دارید",
	"free_label":      "رایگان",
	"active_label":    "فعال",
	"btn_equip":       "بپوش",
	"btn_buy":         "خرید",
	"locked_label":    "قفل",
	"single_use_note": "تک‌بار مصرف · در شروع مسیر بعدی فعال می‌شود",
	"gems_earn_note":  "از دستاوردها و چالش‌های روزانه کسب می‌شود",
	"coins_label":     "سکه",
	"gems_label":      "جواهر",

	# Boosts
	"boost_armor_plate": "زره محافظ",
	"boost_lucky_coins": "سکه‌های شانس",
	"boost_field_medic": "پزشک میدانی",
	"boost_head_start":  "شروع جلو",
	"desc_armor_plate":  "+۵۰ سلامتی در مسیر بعدی",
	"desc_lucky_coins":  "+۶۰٪ سکه در مسیر بعدی",
	"desc_field_medic":  "خودکار ۲۵ HP در سلامتی پایین درمان",
	"desc_head_start":   "۴۰۰ متر جلوتر شروع کن",

	# Premium
	"prem_resurrection": "رستاخیز",
	"prem_overdrive":    "شتاب‌دهنده",
	"prem_war_machine":  "ماشین جنگی",
	"desc_resurrection": "با ۴۰ HP یک بار زنده شو",
	"desc_overdrive":    "با شلیک سریع شروع کن",
	"desc_war_machine":  "+۲۰٪ آسیب گلوله در مسیر بعدی",

	# Skin names
	"skin_default":     "آبی فولادی",
	"skin_crimson":     "قرمز",
	"skin_inferno":     "آتش",
	"skin_stealth":     "مخفی",
	"skin_forest":      "شبح جنگل",
	"skin_neon":        "شبح نئون",
	"skin_ice":         "تیغ یخ",
	"skin_rose":        "رز",
	"skin_gold":        "هجوم طلا",
	"skin_toxic":       "سمی",
	"skin_chrome":      "کروم",
	"skin_obsidian":    "آبسیدین",
	"skin_void":        "قدم‌زن خلاء",
	"skin_coral":       "مرجانی",
	"skin_ultraviolet": "ماوراء بنفش",

	# HUD
	"perks_label":   "مهارت‌ها",
	"phase_label":   "مرحله",
	"coins_hud":     "◆",

	# Ad-continue button (GameOver)
	"ad_btn_ready":       "▶  تماشای آگهی  •  ادامه",
	"ad_btn_loading":     "⏳  بارگذاری آگهی...",
	"ad_btn_watching":    "در حال تماشا...",
	"ad_btn_unavailable": "▶  تماشای آگهی  •  ادامه  (ناموجود)",
	"ad_btn_no_plugin":   "▶  تماشای آگهی  (پلاگین بارگذاری نشد)",
	"ad_btn_timeout":     "آگهی ناموجود",

	# PerkScreen
	"perk_replace_title": "جایگزینی مهارت",
	"perk_adding_prefix": "افزودن:  ",
	"perk_slot_open":     "— خالی",

	# Main scene
	"tap_to_continue":    "برای ادامه لمس کنید",

	# HUD
	"best_none":          "بهترین — م",
	"best_value":         "بهترین %.0f م",

	# Tutorial — page titles
	"tut_controls_title": "کنترل‌های خلبان",
	"tut_enemies_title":  "راهنمای دشمنان",
	"tut_ready_title":    "آماده‌ای، خلبان",

	# Tutorial — controls page
	"tut_hint_swipe":        "← بکش →",
	"tut_hint_swipe_desc":   "تغییر لاین",
	"tut_hint_boost":        "▲  نگه‌دار",
	"tut_hint_boost_desc":   "بوست  —  شکست‌ناپذیر + کوبنده",
	"tut_hint_coins":        "◆  سکه‌ها",
	"tut_hint_coins_desc":   "برای ارتقا بین مسیرها جمع کن",
	"tut_btn_next_enemies":  "بعدی: دشمنان  ▶",
	"tut_btn_next_gotime":   "بعدی: وقت بازیه  ▶",
	"tut_btn_skip":          "رد کردن",
	"tut_btn_engage":        "▶  شروع — شروع مسیر",

	# Tutorial — enemy page
	"tut_page1_sub":      "با دشمنانت آشنا شو",
	"tut_name_grunt":     "گرانت",
	"tut_name_shooter":   "تیرانداز",
	"tut_name_speeder":   "سریع‌رو",
	"tut_name_kamikaze":  "انتحاری",
	"tut_name_tank":      "تانک",
	"tut_name_boss":      "رئیس",
	"tut_warn_grunt":     "از کنار می‌کوبه",
	"tut_warn_shooter":   "از فاصله شلیک می‌کنه",
	"tut_warn_speeder":   "تند و پیچ‌پیچ",
	"tut_warn_kamikaze":  "⚠ آسیب سنگین",
	"tut_warn_tank":      "⛊ شکست‌ناپذیر — دور بزن",
	"tut_warn_boss":      "۳ فاز، حملات شارژ",
	"tut_tip_grunt":      "→ بوست بزن یا تو لاین دیگه بمون",
	"tut_tip_shooter":    "→ از گلوله‌ها فرار کن، نزدیک بشو",
	"tut_tip_speeder":    "→ قبل از دور زدن بوست بزن",
	"tut_tip_kamikaze":   "→ همین‌که دیدیش بوست بزن",
	"tut_tip_tank":       "→ دورش بزن. کشتنی نیست.",
	"tut_tip_boss":       "→ از حملات شارژ با بوست رد بشو",

	# Tutorial — ready page
	"tut_perks_header":   "✦  مهارت‌ها",
	"tut_boss_header":    "◉  نبرد با رئیس",
	"tut_perk_desc":      "هر ۱۰۰۰ متر، ۱ مهارت از ۳ انتخاب کن.\nتا ۳ مهارت داری — یکی رو بنداز تا جای جدید باز بشه.",
	"tut_phase_1":        "فاز ۱",
	"tut_phase_2":        "فاز ۲",
	"tut_phase_3":        "فاز ۳",
	"tut_phase_1_desc":   "شلیک پخش",
	"tut_phase_2_desc":   "شارژ + رگبار",
	"tut_phase_3_desc":   "تمام سلاح‌ها + گوی‌ها",
	"tut_boost_tip":      "→ از حملات شارژ با بوست رد بشو",

	# GameOver
	"wrecked":       "نابود شدی",
	"distance_lbl":  "مسافت",
	"coins_lbl":     "سکه",
	"kills_lbl":     "کشتار",
	"best_lbl":      "بهترین",
	"btn_restart":   "دوباره برو",
	"btn_garage":    "گاراژ",
	"achievements_banner": "-- دستاوردهای جدید --",
	"achievement_reward":  "+%d سکه",

	# Perk names
	"perk_Rapid Fire":      "شلیک سریع",
	"perk_Afterburner":     "موتور فوق‌العاده",
	"perk_Shield Bubble":   "حباب سپر",
	"perk_Lifesteal":       "جذب جان",
	"perk_Ram Fury":        "خشم کوبنده",
	"perk_Magnet Aura":     "جذب مغناطیسی",
	"perk_Double Coins":    "سکه مضاعف",
	"perk_Ricochet Shots":   "گلوله برگشتی",
	"perk_Chain Explosion":  "انفجار زنجیری",
	"perk_Homing Shots":     "گلوله هدایت‌شونده",
	"perk_Explosive Rounds": "گلوله انفجاری",
	"perk_Piercing Shot":    "گلوله نافذ",
	"perk_Overload":         "اضافه‌بار",
	"perk_Twin Barrels":     "دو لوله",
	"perk_Adrenaline":       "آدرنالین",
	"perk_Iron Skin":        "پوست آهنین",
	"perk_Nano Repair":      "ترمیم نانو",
	"perk_Battle Hardened":  "سخت‌جنگ",
	"perk_Scavenger":        "جمع‌کننده",
	"perk_Turbo Engine":     "موتور توربو",
	"perk_Lucky Strike":     "ضربه اقبال",
	"perk_Coin Rush":        "بارش سکه",
	"perk_Nemesis":          "نمسیس",
	"perk_Executioner":      "اعدام‌کننده",

	# Environment zone names
	"env_0":  "بزرگراه شهری",      "env_1":  "جاده بیابانی",
	"env_2":  "شهر شبانه",         "env_3":  "جاده یخی",
	"env_4":  "گردنه آتشفشانی",    "env_5":  "مسیر جنگلی",
	"env_6":  "منطقه صنعتی",       "env_7":  "جاده ساحلی",
	"env_8":  "تونل زیرزمینی",     "env_9":  "بزرگراه فضایی",
	"env_10": "بیابان نئونی",       "env_11": "سرزمین قرمز",
	"env_12": "غارهای کریستالی",   "env_13": "باتلاق سمی",
	"env_14": "تندرای قطبی",       "env_15": "راهروی طوفانی",
	"env_16": "محله‌های سایبرپانک","env_17": "دشت‌های گدازه",
	"env_18": "پل آسمانی",          "env_19": "بزرگراه روح‌زده",
	"env_20": "گردنه ماه خونین",   "env_21": "شبکه کوانتومی",
	"env_22": "سرزمین سایه",       "env_23": "شهر کروم",
	"env_24": "راهروی خلاء",

	# Achievement names
	"ach_first_run":     "خون اول",
	"ach_first_boss":    "قاتل رئیس",
	"ach_road_warrior":  "جنگجوی جاده",
	"ach_speedrunner":   "دونده سرعت",
	"ach_long_haul":     "مسیر طولانی",
	"ach_speed_demon":   "دیو سرعت",
	"ach_endless":       "دونده بی‌پایان",
	"ach_ram_rage":      "خشم کوبنده",
	"ach_ram_god":       "خدای کوبنده",
	"ach_untouchable":   "دست‌نخورده",
	"ach_unstoppable":   "توقف‌ناپذیر",
	"ach_veteran":       "کهنه‌کار",
	"ach_survivor":      "بازمانده",
	"ach_zone_clearer":  "پاک‌کننده منطقه",
	"ach_boss_hunter":   "شکارچی رئیس",
	"ach_legend":        "افسانه",
	"ach_death_machine": "ماشین مرگ",
	"ach_perk_master":   "استاد مهارت",
	"ach_coin_hoarder":  "جمع‌آور سکه",
	"ach_boss_rush":     "هجوم رئیس",
}
