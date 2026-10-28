extends Control

# ---- Palette -----------------------------------------------------------------
const C_BG      := Color(0.02, 0.04, 0.10)   # deep space navy
const C_CYAN    := Color(0.00, 0.88, 1.00)   # neon cyan — primary accent
const C_CYAN_D  := Color(0.00, 0.18, 0.32)
const C_CYAN_P  := Color(0.00, 0.10, 0.20)
const C_MAGENTA := Color(0.85, 0.00, 0.58)   # neon magenta — secondary
const C_MAG_D   := Color(0.22, 0.00, 0.18)
const C_MAG_P   := Color(0.12, 0.00, 0.10)
const C_MUTED   := Color(0.38, 0.68, 0.82)   # teal-muted
const C_DIM     := Color(0.12, 0.20, 0.26)

# ---- Build -------------------------------------------------------------------
func _ready() -> void:
	# Apply saved volume settings on every menu visit
	Music.set_volume(GameState.music_volume)
	Music.set_menu_theme()
	SFX.sfx_volume = GameState.sfx_volume

	var vh: float = get_viewport_rect().size.y

	# Full-screen background
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Scanline overlay — single node drawn via _draw(), no per-line ColorRect nodes
	var scan_overlay := _ScanlineOverlay.new()
	scan_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scan_overlay)

	# Vertical lane glows (teal, subtle)
	for lane_x in [130.0, 240.0, 350.0]:
		var stripe := ColorRect.new()
		stripe.color = Color(0.00, 0.78, 1.00, 0.03)
		stripe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stripe.offset_left  = lane_x - 1.5
		stripe.offset_right = -(480.0 - lane_x - 1.5)
		add_child(stripe)

	# Top horizontal accent line
	var top_line := ColorRect.new()
	top_line.color = Color(0.00, 0.82, 1.00, 0.55)
	top_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_line.offset_top    = 0.0
	top_line.offset_bottom = -(vh - 2.0)
	add_child(top_line)

	# Bottom horizontal accent line
	var bot_line := ColorRect.new()
	bot_line.color = Color(0.00, 0.82, 1.00, 0.55)
	bot_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bot_line.offset_top    = vh - 2.0
	bot_line.offset_bottom = 0.0
	add_child(bot_line)

	# Outer vbox — full screen, centers content vertically
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)

	# Top flex spacer
	var sp_top := Control.new()
	sp_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sp_top)

	# Title
	var title := Label.new()
	title.text = "ASPHALT\nREAPER"   # keep brand name always English
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", C_CYAN)
	title.add_theme_font_size_override("font_size", 54)
	outer.add_child(title)

	_add_gap(outer, 6)

	# Cyan divider under title
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(200, 2)
	div.color = Color(0.00, 0.82, 1.00, 0.65)
	_add_centred(outer, div)

	_add_gap(outer, 10)

	# Tagline
	var tag := Label.new()
	tag.text = Locale.t("tagline")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color", C_MUTED)
	tag.add_theme_font_size_override("font_size", 12)
	tag.text_direction = Control.TEXT_DIRECTION_AUTO
	outer.add_child(tag)

	_add_gap(outer, 40)

	# ── Buttons (fixed width, centred horizontally) ───────────────────────────
	var run_btn := _make_btn(
		Locale.t("btn_engage"),
		Color(0.90, 0.98, 1.00), C_CYAN_D, C_CYAN, C_CYAN, C_CYAN_P, 28)
	run_btn.pressed.connect(func(): SFX.play_click(); GameState.start_run(); get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	_add_centred(outer, run_btn)

	_add_gap(outer, 12)

	var shop_btn := _make_btn(
		Locale.t("btn_armory"),
		Color(1.00, 0.75, 1.00), C_MAG_D, C_MAGENTA, C_MAGENTA, C_MAG_P, 22)
	shop_btn.pressed.connect(func(): SFX.play_click(); get_tree().change_scene_to_file("res://scenes/Shop.tscn"))
	_add_centred(outer, shop_btn)

	_add_gap(outer, 10)

	# Settings button
	var settings_btn := _make_btn(
		Locale.t("btn_settings"),
		Color(0.70, 0.90, 1.00), Color(0.02, 0.10, 0.18),
		Color(0.06, 0.25, 0.42), Color(0.18, 0.50, 0.72),
		Color(0.02, 0.06, 0.12), 17)
	settings_btn.pressed.connect(func():
		SFX.play_click()
		var s: CanvasLayer = load("res://scripts/Settings.gd").new()
		add_child(s))
	_add_centred(outer, settings_btn)

	_add_gap(outer, 10)

	var quit_btn := _make_btn(
		Locale.t("btn_disconnect"),
		C_MUTED, C_DIM, Color(0.08, 0.18, 0.24), Color(0.15, 0.40, 0.55),
		Color(0.04, 0.10, 0.14), 18)
	quit_btn.pressed.connect(func(): SFX.play_click(); get_tree().quit())
	_add_centred(outer, quit_btn)

	# Bottom flex spacer + hint
	var sp_bot := Control.new()
	sp_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sp_bot)

	var hint := Label.new()
	hint.text = Locale.t("hint_controls")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.25, 0.50, 0.62, 0.75))
	hint.add_theme_font_size_override("font_size", 11)
	hint.text_direction = Control.TEXT_DIRECTION_AUTO
	outer.add_child(hint)

	_add_gap(outer, 18)


# ---- Helpers -----------------------------------------------------------------
func _add_gap(parent: VBoxContainer, px: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	parent.add_child(c)

func _add_centred(parent: VBoxContainer, ctrl: Control) -> void:
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(centre)
	centre.add_child(ctrl)

# Single-node scanline renderer — replaces ~142 individual ColorRect nodes
class _ScanlineOverlay extends Control:
	func _draw() -> void:
		var h: float = size.y
		var w: float = size.x
		var line_color := Color(0.00, 0.60, 1.00, 0.018)
		var y: float = 0.0
		while y < h:
			draw_line(Vector2(0.0, y), Vector2(w, y), line_color)
			y += 6.0

func _flat(bg: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	return s

func _make_btn(txt: String, font_col: Color,
		bg_n: Color, bg_h: Color, bd_h: Color,
		bg_p: Color, font_sz: int) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(270, 58)
	btn.add_theme_stylebox_override("normal",  _flat(bg_n, bd_h))
	btn.add_theme_stylebox_override("hover",   _flat(bg_h, bd_h))
	btn.add_theme_stylebox_override("pressed", _flat(bg_p, bd_h))
	btn.add_theme_stylebox_override("focus",   _flat(bg_n, bd_h))
	btn.add_theme_color_override("font_color",         font_col)
	btn.add_theme_color_override("font_hover_color",   font_col)
	btn.add_theme_color_override("font_pressed_color", font_col)
	btn.add_theme_font_size_override("font_size", font_sz)
	return btn
