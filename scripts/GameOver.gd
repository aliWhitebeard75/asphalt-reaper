extends CanvasLayer

signal revive_requested   # emitted when the player earns a revival via ad

@onready var panel: Panel          = $Panel
@onready var dist_label: Label     = $Panel/VBox/DistLabel
@onready var coins_label: Label    = $Panel/VBox/CoinsLabel
@onready var kills_label: Label    = $Panel/VBox/KillsLabel
@onready var best_label: Label     = $Panel/VBox/BestLabel
@onready var achiev_label: Label   = $Panel/VBox/AchievLabel
@onready var restart_btn: Button   = $Panel/VBox/RestartBtn
@onready var garage_btn: Button    = $Panel/VBox/GarageBtn
@onready var title_label: Label    = $Panel/VBox/TitleLabel

var _ad_btn: Button = null      # "Watch Ad • Continue" button
var _ad_sep: HSeparator = null  # separator above ad button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_over_screen")
	get_tree().paused = true
	restart_btn.pressed.connect(_on_restart)
	garage_btn.pressed.connect(_on_garage)
	_apply_styles()
	_make_achiev_scrollable()
	_build_ad_button()

func _make_achiev_scrollable() -> void:
	# Wrap achiev_label in a ScrollContainer so a long achievement list
	# doesn't overflow the fixed-height Panel.
	var vbox: VBoxContainer = achiev_label.get_parent() as VBoxContainer
	if vbox == null:
		return
	var idx := achiev_label.get_index()

	var scroll := ScrollContainer.new()
	scroll.name                   = "AchievScroll"
	scroll.process_mode           = Node.PROCESS_MODE_ALWAYS
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size    = Vector2(0.0, 48.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO

	vbox.add_child(scroll)
	vbox.move_child(scroll, idx)
	achiev_label.reparent(scroll)
	achiev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achiev_label.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART

func _build_ad_button() -> void:
	# Only offer once per run
	if GameState.run_ad_used:
		return

	# ── Always build the button — its state reflects AdiveryManager status ────
	var vbox: VBoxContainer = restart_btn.get_parent() as VBoxContainer

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.10, 0.95, 0.35, 0.35))
	sep.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(sep)
	vbox.move_child(sep, restart_btn.get_index())
	_ad_sep = sep

	_ad_btn = Button.new()
	_ad_btn.name = "WatchAdBtn"
	vbox.add_child(_ad_btn)
	vbox.move_child(_ad_btn, restart_btn.get_index())

	_style_button(_ad_btn,
		Color(0.04, 0.20, 0.06), Color(0.06, 0.30, 0.08),
		Color(0.10, 0.95, 0.35), Color(0.20, 1.00, 0.50),
		Color(0.85, 1.00, 0.88), 19)
	_ad_btn.add_theme_stylebox_override("disabled", _flat(
		Color(0.04, 0.14, 0.06), Color(0.08, 0.55, 0.20)))
	_ad_btn.add_theme_color_override("font_disabled_color", Color(0.60, 0.80, 0.65, 0.80))
	_ad_btn.add_theme_font_size_override("font_size", 19)

	# ── Connect to AdiveryManager if available ────────────────────────────────
	var am = get_node_or_null("/root/AdiveryManager")
	if am == null:
		# Plugin not installed or not on Android — button visible but unusable
		_ad_btn.text = Locale.t("ad_btn_unavailable")
		_ad_btn.disabled = true
		return

	# ── Set initial state ─────────────────────────────────────────────────────
	if not am.is_plugin_initialized():
		# JNI singleton never loaded — plugin AAR is missing from this build.
		# Distinct message from "ad unavailable" so it's diagnosable on-device.
		_ad_btn.text = Locale.t("ad_btn_no_plugin")
		_ad_btn.disabled = true
		return
	elif am.is_ad_ready():
		_set_ad_btn_ready(true)
	else:
		_set_ad_btn_ready(false)
		# am.ad_loaded fires when AdiveryManager finishes loading the ad
		am.ad_loaded.connect(_on_ad_loaded_for_btn, CONNECT_ONE_SHOT)
		# Safety: give up after 30 s if signal never fires
		get_tree().create_timer(30.0).timeout.connect(func():
			if is_instance_valid(_ad_btn) and _ad_btn.disabled:
				_ad_btn.text = Locale.t("ad_btn_timeout")
		)

	# ── Reward outcome signals ────────────────────────────────────────────────
	am.ad_reward_granted.connect(func():
		revive_requested.emit()
	, CONNECT_ONE_SHOT)

	am.ad_closed_without_reward.connect(func():
		# Ad was closed without reward — remove the button entirely so only
		# "Drive Again" and "Garage" remain.
		if is_instance_valid(_ad_btn):
			_ad_btn.queue_free()
			_ad_btn = null
		if is_instance_valid(_ad_sep):
			_ad_sep.queue_free()
			_ad_sep = null
	, CONNECT_ONE_SHOT)

	# ── Press → show ad ───────────────────────────────────────────────────────
	_ad_btn.pressed.connect(func():
		if not is_instance_valid(_ad_btn):
			return
		_ad_btn.text = Locale.t("ad_btn_watching")
		_ad_btn.disabled = true
		am.show_rewarded_now()
	)

func _set_ad_btn_ready(is_ready: bool) -> void:
	if not is_instance_valid(_ad_btn):
		return
	if is_ready:
		_ad_btn.text = Locale.t("ad_btn_ready")
		_ad_btn.disabled = false
	else:
		_ad_btn.text = Locale.t("ad_btn_loading")
		_ad_btn.disabled = true

func _on_ad_loaded_for_btn() -> void:
	_set_ad_btn_ready(true)

func setup(distance: float, coins_earned: int, kills: int, new_achievements: Array) -> void:
	dist_label.text  = Locale.t("distance_lbl") + "    %.0f m" % distance
	coins_label.text = Locale.t("coins_lbl") + "         %d" % coins_earned
	kills_label.text = Locale.t("kills_lbl") + "           %d" % kills
	best_label.text  = Locale.t("best_lbl") + "           %.0f m" % GameState.best_distance

	# Apply RTL direction for Persian
	for lbl in [dist_label, coins_label, kills_label, best_label]:
		lbl.text_direction = Control.TEXT_DIRECTION_AUTO

	title_label.text = Locale.t("wrecked")
	title_label.text_direction = Control.TEXT_DIRECTION_AUTO
	restart_btn.text = Locale.t("btn_restart")
	restart_btn.text_direction = Control.TEXT_DIRECTION_AUTO
	garage_btn.text  = Locale.t("btn_garage")
	garage_btn.text_direction = Control.TEXT_DIRECTION_AUTO

	# Achievement banner — also hide the scroll container itself when empty
	# (it has SIZE_EXPAND_FILL which causes a large blank space if left visible)
	if new_achievements.is_empty():
		achiev_label.visible = false
		var scroll_parent = achiev_label.get_parent()
		if scroll_parent != null:
			scroll_parent.visible = false
	else:
		var lines: Array = [Locale.t("achievements_banner")]
		for key in new_achievements:
			var ach_name: String = Locale.t("ach_" + key)
			var reward: int      = GameState.get_achievement_reward(key)
			lines.append("  * %s   %s" % [ach_name, Locale.t("achievement_reward") % reward])
		achiev_label.text    = "\n".join(lines)
		achiev_label.text_direction = Control.TEXT_DIRECTION_AUTO
		achiev_label.visible = true

# ─── Styling ──────────────────────────────────────────────────────────────────
func _apply_styles() -> void:
	# Panel — deep navy with neon cyan border
	var panel_s = StyleBoxFlat.new()
	panel_s.bg_color       = Color(0.02, 0.05, 0.12, 0.97)
	panel_s.set_border_width_all(2)
	panel_s.border_color = Color(0.00, 0.78, 1.00, 1.0)
	panel_s.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", panel_s)

	# Title — neon pink-red
	title_label.add_theme_color_override("font_color",    Color(1.00, 0.18, 0.30, 1.0))
	title_label.add_theme_font_size_override("font_size", 44)

	# Stat labels — ice white
	for lbl in [dist_label, coins_label, kills_label]:
		lbl.add_theme_color_override("font_color",    Color(0.82, 0.96, 1.00, 1.0))
		lbl.add_theme_font_size_override("font_size", 20)

	best_label.add_theme_color_override("font_color",    Color(1.00, 0.90, 0.18, 1.0))
	best_label.add_theme_font_size_override("font_size", 17)

	# Achievement label — bright gold
	achiev_label.add_theme_color_override("font_color",    Color(1.00, 0.90, 0.18, 1.0))
	achiev_label.add_theme_font_size_override("font_size", 13)

	# Restart — neon cyan
	_style_button(restart_btn,
		Color(0.00, 0.14, 0.26), Color(0.00, 0.20, 0.36),
		Color(0.00, 0.78, 1.00), Color(0.00, 0.90, 1.00),
		Color(0.88, 0.98, 1.00), 22)

	# Garage — neon magenta
	_style_button(garage_btn,
		Color(0.16, 0.02, 0.14), Color(0.22, 0.04, 0.18),
		Color(0.85, 0.00, 0.58), Color(0.95, 0.10, 0.65),
		Color(1.00, 0.78, 1.00), 17)

func _style_button(btn: Button,
		bg_n: Color, bg_h: Color,
		border_n: Color, border_h: Color,
		font_col: Color, font_sz: int) -> void:
	var n = _flat(bg_n, border_n)
	var h = _flat(bg_h, border_h)
	var p = _flat(bg_h.darkened(0.12), border_h)
	btn.add_theme_stylebox_override("normal",   n)
	btn.add_theme_stylebox_override("hover",    h)
	btn.add_theme_stylebox_override("pressed",  p)
	btn.add_theme_stylebox_override("focus",    n)
	btn.add_theme_color_override("font_color",  font_col)
	btn.add_theme_color_override("font_hover_color",   font_col.lightened(0.15))
	btn.add_theme_color_override("font_pressed_color", font_col.darkened(0.10))
	btn.add_theme_font_size_override("font_size", font_sz)

func _flat(bg: Color, border: Color, r: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left   = 2; s.border_width_top    = 2
	s.border_width_right  = 2; s.border_width_bottom = 2
	s.border_color = border
	s.corner_radius_top_left    = r; s.corner_radius_top_right   = r
	s.corner_radius_bottom_left = r; s.corner_radius_bottom_right = r
	return s

func _on_restart() -> void:
	get_tree().paused = false
	GameState.start_run()
	get_tree().reload_current_scene()

func _on_garage() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Garage.tscn")
