extends Control

# ---- Palette ----------------------------------------------------------------
const C_BG        := Color(0.02, 0.04, 0.10)   # deep space navy
const C_CARD      := Color(0.03, 0.07, 0.14)   # dark teal card
const C_CARD_HOV  := Color(0.05, 0.10, 0.20)
const C_BORDER    := Color(0.00, 0.52, 0.78)   # medium cyan
const C_CYAN      := Color(0.00, 0.82, 1.00)   # neon cyan (primary accent)
const C_CYAN_DARK := Color(0.00, 0.15, 0.28)
const C_CYAN_PRESS:= Color(0.00, 0.08, 0.16)
const C_GOLD      := Color(1.00, 0.90, 0.18)   # bright gold
const C_TEXT      := Color(0.85, 0.96, 1.00)   # ice white
const C_MUTED     := Color(0.38, 0.65, 0.80)
const C_DIM       := Color(0.12, 0.20, 0.28)

# ---- Upgrade metadata -------------------------------------------------------
const UPGRADE_KEYS: Array = [
	"max_health", "coin_multiplier", "starting_speed",
	"shield_recharge", "explosion_radius", "enemy_health_reduction", "starting_weapon"
]

const UPGRADE_DESC: Dictionary = {
	"max_health":            "More armour keeps you alive longer.",
	"coin_multiplier":       "Earn more coins every run.",
	"starting_speed":        "Hit the road faster each time.",
	"shield_recharge":       "Shield bounces back quicker.",
	"explosion_radius":      "Bigger blasts, wider destruction.",
	"enemy_health_reduction":"Enemies spawn weaker.",
	"starting_weapon":       "Start with a stronger loadout.",
}

const UPGRADE_EFFECT: Dictionary = {
	"max_health":            "+25 HP",
	"coin_multiplier":       "+25%",
	"starting_speed":        "+40 km/h",
	"shield_recharge":       "+50% rate",
	"explosion_radius":      "+20 radius",
	"enemy_health_reduction":"-8% enemy HP",
	"starting_weapon":       "+1 tier",
}

# ---- Node refs --------------------------------------------------------------
@onready var coins_label: Label       = $MainVBox/HeaderPanel/HeaderVBox/CoinsLabel
@onready var upgrade_container        = $MainVBox/ScrollContainer/UpgradeList
@onready var play_btn: Button         = $MainVBox/PlayBtn
@onready var _scroll: ScrollContainer = $MainVBox/ScrollContainer

var upgrade_buttons: Dictionary = {}
var _daily_status_lbl: Label = null
var _daily_progress_lbl: Label = null
var _stats_lbl: Label = null

# ---- Touch scroll state -----------------------------------------------------
var _touch_start_y: float = 0.0
var _scroll_start: int = 0
var _touch_id: int = -1
var _velocity: float = 0.0
var _last_y: float = 0.0
var _last_t: int = 0
var _vel_samples: Array = []   # ring buffer of [dy, dt] for smooth velocity

# ---- Lifecycle --------------------------------------------------------------
func _ready() -> void:
	_apply_styles()
	play_btn.text = Locale.t("btn_play")
	play_btn.text_direction = Control.TEXT_DIRECTION_AUTO
	play_btn.pressed.connect(_on_play)
	_build_daily_card()
	_build_upgrade_list()
	_build_stats_footer()
	_add_shop_button()
	_refresh()

func _add_shop_button() -> void:
	var main_vbox = $MainVBox

	# Back to Main Menu button (added first so it appears above play)
	var back_btn := Button.new()
	back_btn.text = Locale.t("btn_back")
	back_btn.text_direction = Control.TEXT_DIRECTION_AUTO
	back_btn.custom_minimum_size = Vector2(0, 40)
	_style_btn(back_btn,
		C_DIM, C_BORDER, C_BORDER, C_CYAN, C_CYAN_PRESS, C_MUTED, 15)
	back_btn.pressed.connect(func():
		SFX.play_click()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	main_vbox.add_child(back_btn)
	main_vbox.move_child(back_btn, play_btn.get_index())

	# Shop button
	var shop_btn := Button.new()
	shop_btn.text = Locale.t("btn_shop")
	shop_btn.text_direction = Control.TEXT_DIRECTION_AUTO
	shop_btn.custom_minimum_size = Vector2(0, 44)
	_style_btn(shop_btn,
		Color(0.18, 0.02, 0.14), Color(0.85, 0.00, 0.58),
		Color(0.85, 0.00, 0.58), Color(0.95, 0.10, 0.65),
		Color(0.12, 0.01, 0.10),
		Color(1.00, 0.78, 1.00), 18)
	shop_btn.pressed.connect(func():
		SFX.play_click()
		get_tree().change_scene_to_file("res://scenes/Shop.tscn"))
	main_vbox.add_child(shop_btn)
	main_vbox.move_child(shop_btn, play_btn.get_index())

# ---- Style helpers ----------------------------------------------------------
func _flat(bg: Color, border: Color, r: float = 8.0, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(int(r))
	return s

func _apply_styles() -> void:
	# Background
	$BgPanel.add_theme_stylebox_override("panel", _flat(C_BG, C_BG, 0.0, 0))

	# Header panel - bottom neon cyan border
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Color(0.02, 0.06, 0.14)
	hstyle.border_color = C_CYAN
	hstyle.border_width_bottom = 2
	hstyle.set_corner_radius_all(8)
	$MainVBox/HeaderPanel.add_theme_stylebox_override("panel", hstyle)

	# Title — neon cyan
	var title := $MainVBox/HeaderPanel/HeaderVBox/TitleLabel
	title.text = Locale.t("garage_title")
	title.text_direction = Control.TEXT_DIRECTION_AUTO
	title.add_theme_color_override("font_color", C_CYAN)
	title.add_theme_font_size_override("font_size", 34)

	# Coins
	coins_label.add_theme_color_override("font_color", C_GOLD)
	coins_label.add_theme_font_size_override("font_size", 17)

	# Play button — neon cyan
	_style_btn(play_btn, C_CYAN_DARK, C_CYAN, C_CYAN, C_CYAN, C_CYAN_PRESS, Color(0.90, 0.98, 1.00), 22)
	play_btn.add_theme_constant_override("outline_size", 0)

func _style_btn(btn: Button,
		bg_n: Color, bd_n: Color,
		bg_h: Color, bd_h: Color,
		bg_p: Color,
		font_col: Color, font_sz: int) -> void:
	btn.add_theme_stylebox_override("normal",  _flat(bg_n, bd_n, 10.0))
	btn.add_theme_stylebox_override("hover",   _flat(bg_h, bd_h, 10.0))
	btn.add_theme_stylebox_override("pressed", _flat(bg_p, bd_n, 10.0))
	btn.add_theme_stylebox_override("disabled",_flat(C_DIM, C_DIM, 10.0))
	btn.add_theme_color_override("font_color",          font_col)
	btn.add_theme_color_override("font_hover_color",    font_col)
	btn.add_theme_color_override("font_pressed_color",  font_col)
	btn.add_theme_color_override("font_disabled_color", C_MUTED)
	btn.add_theme_font_size_override("font_size", font_sz)

# ---- Daily challenge card ---------------------------------------------------
func _build_daily_card() -> void:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 80)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.03, 0.08, 0.16)
	card_style.border_color = Color(0.00, 0.65, 0.95)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	upgrade_container.add_child(card)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 14; hbox.offset_right = -14
	hbox.offset_top  = 10; hbox.offset_bottom = -10
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	# Left: title + task description
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	hbox.add_child(left)

	var title_lbl := Label.new()
	title_lbl.text = Locale.t("daily_challenge")
	title_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	title_lbl.add_theme_color_override("font_color",    Color(0.00, 0.90, 1.00))
	title_lbl.add_theme_font_size_override("font_size", 12)
	left.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = _get_daily_text_localized()
	desc_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	desc_lbl.add_theme_color_override("font_color",    Color(0.88, 0.88, 0.92))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(desc_lbl)

	# Right: reward + progress / status
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(100, 0)
	right.add_theme_constant_override("separation", 4)
	hbox.add_child(right)

	var reward_lbl := Label.new()
	reward_lbl.text = Locale.t("reward_label") + ": %d" % GameState.DAILY_REWARD
	reward_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_color_override("font_color",    Color(1.00, 0.82, 0.10))
	reward_lbl.add_theme_font_size_override("font_size", 12)
	right.add_child(reward_lbl)

	_daily_progress_lbl = Label.new()
	_daily_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_progress_lbl.add_theme_font_size_override("font_size", 12)
	right.add_child(_daily_progress_lbl)

	_daily_status_lbl = Label.new()
	_daily_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_status_lbl.add_theme_font_size_override("font_size", 13)
	right.add_child(_daily_status_lbl)

# ---- Lifetime stats footer ---------------------------------------------------
func _build_stats_footer() -> void:
	var sep := HSeparator.new()
	upgrade_container.add_child(sep)

	_stats_lbl = Label.new()
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_lbl.add_theme_color_override("font_color",    Color(0.30, 0.58, 0.72))
	_stats_lbl.add_theme_font_size_override("font_size", 12)
	upgrade_container.add_child(_stats_lbl)

# ---- Build upgrade cards ----------------------------------------------------
func _build_upgrade_list() -> void:
	for key in UPGRADE_KEYS:
		upgrade_container.add_child(_build_card(key))

func _build_card(key: String) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 92)
	card.add_theme_stylebox_override("panel", _flat(C_CARD, C_BORDER, 10.0))

	var inner := HBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left   =  14
	inner.offset_right  = -14
	inner.offset_top    =  10
	inner.offset_bottom = -10
	inner.add_theme_constant_override("separation", 12)
	card.add_child(inner)

	# Left info column
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	inner.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = Locale.t("upg_" + key)
	name_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = Locale.t("desc_" + key)
	desc_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	desc_lbl.add_theme_color_override("font_color", C_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	var star_lbl := Label.new()
	star_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(star_lbl)

	# Right column: level fraction + buy button
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(112, 0)
	right.add_theme_constant_override("separation", 6)
	inner.add_child(right)

	var level_lbl := Label.new()
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_color_override("font_color", C_MUTED)
	level_lbl.add_theme_font_size_override("font_size", 12)
	right.add_child(level_lbl)

	var eff_lbl := Label.new()
	eff_lbl.text = Locale.t("eff_" + key)
	eff_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	eff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_lbl.add_theme_color_override("font_color", C_GOLD)
	eff_lbl.add_theme_font_size_override("font_size", 11)
	right.add_child(eff_lbl)

	var btn := Button.new()
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_upgrade.bind(key))
	right.add_child(btn)

	upgrade_buttons[key] = {"level": level_lbl, "btn": btn, "stars": star_lbl}
	return card

# ---- Refresh ----------------------------------------------------------------
func _make_stars(cur: int, mx: int) -> String:
	var s := ""
	for i in range(mx):
		s += "★" if i < cur else "☆"
	return s

func _get_daily_text_localized() -> String:
	match GameState.daily_type:
		"distance": return Locale.t("daily_distance") % GameState.daily_target
		"kills":    return Locale.t("daily_kills")    % GameState.daily_target
		"boss":     return Locale.t("daily_boss")
		"ram":      return Locale.t("daily_ram")      % GameState.daily_target
		_:          return Locale.t("daily_fallback")

func _get_daily_progress_localized() -> String:
	if GameState.daily_done:
		return Locale.t("completed")
	match GameState.daily_type:
		"distance": return "%d / %d %s" % [GameState.daily_progress, GameState.daily_target, Locale.t("m_unit")]
		"kills":    return "%d / %d %s" % [GameState.daily_progress, GameState.daily_target, Locale.t("kills_unit")]
		"boss":     return "%d / 1 %s"  % [GameState.daily_progress, Locale.t("boss_unit")]
		"ram":      return "%d / %d %s" % [GameState.daily_progress, GameState.daily_target, Locale.t("rams_unit")]
		_:          return "0 / 1"

func _refresh() -> void:
	coins_label.text = "◆  %d  %s" % [GameState.coins, Locale.t("coins_label")]

	# Daily challenge
	if _daily_progress_lbl:
		_daily_progress_lbl.text = _get_daily_progress_localized()
		_daily_progress_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
		if GameState.daily_done:
			_daily_progress_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.40))
		else:
			_daily_progress_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80))
	if _daily_status_lbl:
		if GameState.daily_done:
			_daily_status_lbl.text = Locale.t("completed")
			_daily_status_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
			_daily_status_lbl.add_theme_color_override("font_color", Color(0.20, 1.00, 0.35))
		else:
			_daily_status_lbl.text = ""

	# Lifetime stats footer
	if _stats_lbl:
		_stats_lbl.text = "%s: %d   %s: %d   %s: %d   %s: %d/%d" % [
			Locale.t("stat_runs"),    GameState.total_runs,
			Locale.t("stat_kills"),   GameState.total_kills,
			Locale.t("stat_bosses"),  GameState.bosses_defeated,
			Locale.t("stat_achievements"), GameState.get_unlocked_count(), GameState.ACHIEVEMENTS.size()
		]
		_stats_lbl.text_direction = Control.TEXT_DIRECTION_AUTO

	for key in UPGRADE_KEYS:
		var lvl: int     = GameState.upgrades[key]
		var max_lvl: int = GameState.UPGRADE_MAX[key]
		var cost: int    = GameState.get_upgrade_cost(key)
		var d: Dictionary = upgrade_buttons[key]
		var btn: Button = d["btn"]

		# Stars
		var star_lbl: Label = d["stars"]
		if lvl >= max_lvl:
			star_lbl.text = _make_stars(max_lvl, max_lvl) + "  " + Locale.t("max_level")
			star_lbl.add_theme_color_override("font_color", C_GOLD)
		else:
			star_lbl.text = _make_stars(lvl, max_lvl)
			star_lbl.add_theme_color_override("font_color", C_GOLD)

		d["level"].text = "%d / %d" % [lvl, max_lvl]

		# Button state
		if lvl >= max_lvl:
			btn.text     = Locale.t("max_level")
			btn.disabled = true
			_style_btn(btn, C_DIM, C_DIM, C_DIM, C_DIM, C_DIM, C_MUTED, 12)
		elif GameState.can_upgrade(key):
			btn.text     = "%s  %d" % [Locale.t("upgrade_btn"), cost]
			btn.text_direction = Control.TEXT_DIRECTION_AUTO
			btn.disabled = false
			_style_btn(btn,
				C_CYAN_DARK, C_CYAN,
				C_CYAN,      C_CYAN,
				C_CYAN_PRESS,
				Color(0.90, 0.98, 1.00), 13)
		else:
			btn.text     = "%d %s" % [cost, Locale.t("coins_label")]
			btn.text_direction = Control.TEXT_DIRECTION_AUTO
			btn.disabled = true
			_style_btn(btn,
				Color(0.10, 0.07, 0.13), Color(0.20, 0.15, 0.26),
				Color(0.10, 0.07, 0.13), Color(0.20, 0.15, 0.26),
				Color(0.10, 0.07, 0.13),
				C_MUTED, 12)

# ---- Touch scroll -----------------------------------------------------------
func _process(delta: float) -> void:
	if _touch_id != -1:
		return   # finger down — no inertia
	if abs(_velocity) < 4.0:
		_velocity = 0.0
		return
	_scroll.scroll_vertical += int(_velocity * delta)
	_velocity *= 0.88   # friction — feels like natural momentum

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_scroll):
		return
	# Scale factor: touch events arrive in physical pixels, scroll is in canvas pixels
	var win_h: float = float(DisplayServer.window_get_size().y)
	var canvas_h: float = get_viewport_rect().size.y
	var sy: float = canvas_h / win_h if win_h > 0.0 else 1.0

	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_y  = event.position.y
			_scroll_start   = _scroll.scroll_vertical
			_touch_id       = event.index
			_velocity       = 0.0
			_last_y         = event.position.y
			_last_t         = Time.get_ticks_msec()
			_vel_samples.clear()
		elif event.index == _touch_id:
			_touch_id = -1
			# Compute fling velocity from averaged recent samples
			if _vel_samples.size() > 0:
				var sum_dy: float = 0.0
				var sum_dt: float = 0.0
				for s in _vel_samples:
					sum_dy += float(s[0])
					sum_dt += float(s[1])
				if sum_dt > 0.0:
					_velocity = (sum_dy / sum_dt) * sy
			_vel_samples.clear()

	elif event is InputEventScreenDrag and event.index == _touch_id:
		# Direct scroll during drag
		var dy: int = int((_touch_start_y - event.position.y) * sy)
		_scroll.scroll_vertical = _scroll_start + dy

		# Sample velocity for fling
		var now_t: int  = Time.get_ticks_msec()
		var dt_ms: int  = now_t - _last_t
		if dt_ms >= 8:   # at least 8 ms between samples
			_vel_samples.append([_last_y - event.position.y, float(dt_ms) / 1000.0])
			if _vel_samples.size() > 5:   # keep last 5 samples only
				_vel_samples.pop_front()
			_last_y = event.position.y
			_last_t = now_t
		get_viewport().set_input_as_handled()

# ---- Handlers ---------------------------------------------------------------
func _on_upgrade(key: String) -> void:
	GameState.buy_upgrade(key)
	_refresh()

func _on_play() -> void:
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
