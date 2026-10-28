extends CanvasLayer

# ─── State ────────────────────────────────────────────────────────────────────
var _page: int = 0
var _pages: Array = []

# Interactive state for page 0 (controls demo)
var _demo_lane:   float = 240.0   # current car X in lane demo
var _demo_target: float = 240.0
var _demo_boost:  bool  = false
var _demo_boost_t:float = 0.0
var _demo_auto_t: float = 0.0    # timer for auto-lane-change
var _demo_seq:    int   = 0      # sequence index
const DEMO_LANES := [130.0, 240.0, 350.0]
const DEMO_SEQ   := [1, 0, 2, 1]   # lane indices to visit in order

var _lane_canvas: Control = null   # page-0 animated canvas

# ─── Build ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Dim backdrop
	var bg := ColorRect.new()
	bg.color = Color(0.00, 0.02, 0.08, 0.90)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_pages.append(_build_page_controls())
	_pages.append(_build_page_enemies())
	_pages.append(_build_page_ready())

	for p in _pages:
		add_child(p)
		p.visible = false

	_show_page(0)

func _show_page(n: int) -> void:
	for i in _pages.size():
		_pages[i].visible = (i == n)
	_page = n

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 0 — CONTROLS
# ─────────────────────────────────────────────────────────────────────────────
func _build_page_controls() -> Control:
	var root := _make_panel(Color(0.00, 0.28, 0.48), Locale.t("tut_controls_title"))
	var vbox: VBoxContainer = root.get_meta("vbox")

	# Animated lane demo
	_lane_canvas = Control.new()
	_lane_canvas.custom_minimum_size = Vector2(0, 150)
	_lane_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lane_canvas.draw.connect(_draw_lane_demo)
	vbox.add_child(_lane_canvas)

	_add_divider(vbox)

	# Swipe hint
	var row1 := _hint_row(Locale.t("tut_hint_swipe"), Locale.t("tut_hint_swipe_desc"), Color(0.35, 1.00, 0.80))
	vbox.add_child(row1)

	var row2 := _hint_row(Locale.t("tut_hint_boost"), Locale.t("tut_hint_boost_desc"), Color(1.00, 0.82, 0.10))
	vbox.add_child(row2)

	var row3 := _hint_row(Locale.t("tut_hint_coins"), Locale.t("tut_hint_coins_desc"), Color(1.00, 0.90, 0.18))
	vbox.add_child(row3)

	_add_btn_row(vbox, false, Locale.t("tut_btn_next_enemies"), func(): _show_page(1))
	return root

func _hint_row(key: String, value: String, key_col: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var k := Label.new()
	k.text = key
	k.custom_minimum_size = Vector2(90, 0)
	k.add_theme_color_override("font_color", key_col)
	k.add_theme_font_size_override("font_size", 14)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(k)

	var v := Label.new()
	v.text = value
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_color_override("font_color", Color(0.82, 0.95, 1.00))
	v.add_theme_font_size_override("font_size", 13)
	row.add_child(v)
	return row

# Animated lane demo drawing
func _draw_lane_demo() -> void:
	if _lane_canvas == null:
		return
	var w := _lane_canvas.size.x
	var h := _lane_canvas.size.y

	# Road background
	_lane_canvas.draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.08, 0.10))

	# Road border lines
	_lane_canvas.draw_line(Vector2(80, 0), Vector2(80, h),    Color(1.0, 1.0, 1.0, 0.12), 2)
	_lane_canvas.draw_line(Vector2(w-80, 0), Vector2(w-80, h), Color(1.0, 1.0, 1.0, 0.12), 2)

	# Dashed lane dividers
	var dash_h := 22.0; var gap_h := 14.0
	var y := fmod(-_demo_auto_t * 60.0, dash_h + gap_h)
	while y < h + dash_h:
		var lx := w * 0.5 - 55.0
		var rx := w * 0.5 + 55.0
		_lane_canvas.draw_line(Vector2(lx, y), Vector2(lx, y + dash_h), Color(1.0, 1.0, 1.0, 0.25), 2)
		_lane_canvas.draw_line(Vector2(rx, y), Vector2(rx, y + dash_h), Color(1.0, 1.0, 1.0, 0.25), 2)
		y += dash_h + gap_h

	# Swipe arrows when changing lane
	var dx := _demo_target - _demo_lane
	if abs(dx) > 5.0:
		var arrow_x: float = _demo_lane + sign(dx) * 48.0
		var arrow_alpha: float = clamp(abs(dx) / 60.0, 0.0, 1.0)
		_lane_canvas.draw_string(
			ThemeDB.fallback_font,
			Vector2(arrow_x - 12, h * 0.5 + 24),
			"▶" if dx > 0 else "◀",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 28,
			Color(0.00, 0.90, 1.00, arrow_alpha))

	# Boost trail when boosting
	if _demo_boost:
		for i in 5:
			var alpha := (1.0 - float(i) * 0.18) * 0.55
			_lane_canvas.draw_rect(
				Rect2(_demo_lane - 12, h * 0.5 + 18 + float(i) * 10, 24, 10),
				Color(1.0, 0.60, 0.05, alpha))

	# Player car (simple but readable)
	var cy := h * 0.5
	var cx := _demo_lane
	# Body
	_lane_canvas.draw_rect(Rect2(cx - 14, cy - 28, 28, 56), Color(0.20, 0.60, 1.00))
	# Windshield
	_lane_canvas.draw_rect(Rect2(cx - 10, cy - 20, 20, 14), Color(0.15, 0.35, 0.70, 0.85))
	# Roof
	_lane_canvas.draw_rect(Rect2(cx -  7, cy -  6, 14, 14), Color(0.12, 0.30, 0.58))
	# Headlights
	_lane_canvas.draw_rect(Rect2(cx - 13, cy - 28,  6,  4), Color(1.0, 0.96, 0.78))
	_lane_canvas.draw_rect(Rect2(cx +  7, cy - 28,  6,  4), Color(1.0, 0.96, 0.78))
	# Taillights
	_lane_canvas.draw_circle(Vector2(cx - 8, cy + 26), 3.5, Color(0.9, 0.08, 0.08))
	_lane_canvas.draw_circle(Vector2(cx + 8, cy + 26), 3.5, Color(0.9, 0.08, 0.08))
	# Wheels
	for wxoff in [-13.0, 13.0]:
		for wyoff in [-14.0, 16.0]:
			_lane_canvas.draw_circle(Vector2(cx + wxoff, cy + wyoff), 6.0, Color(0.10, 0.10, 0.12))
			_lane_canvas.draw_circle(Vector2(cx + wxoff, cy + wyoff), 3.5, Color(0.50, 0.62, 0.80))

	# Boost glow ring
	if _demo_boost:
		var pulse := (sin(_demo_boost_t * 12.0) + 1.0) * 0.5
		_lane_canvas.draw_arc(Vector2(cx, cy), 22.0 + pulse * 4.0, 0, TAU, 32,
			Color(0.40, 0.85, 1.00, 0.55 + pulse * 0.35), 2.5)

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 1 — ENEMY FIELD GUIDE
# ─────────────────────────────────────────────────────────────────────────────
func _build_page_enemies() -> Control:
	var root := _make_panel(Color(0.32, 0.06, 0.04), Locale.t("tut_enemies_title"))
	var vbox: VBoxContainer = root.get_meta("vbox")

	# Subtitle
	var sub := Label.new()
	sub.text = Locale.t("tut_page1_sub")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.55, 0.75, 0.85))
	sub.add_theme_font_size_override("font_size", 12)
	vbox.add_child(sub)

	# 2-column grid of 6 enemy cards
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(grid)

	var enemies := [
		{"type": "grunt",    "name": Locale.t("tut_name_grunt"),    "warn": Locale.t("tut_warn_grunt"),    "col": Color(0.90, 0.20, 0.20)},
		{"type": "shooter",  "name": Locale.t("tut_name_shooter"),  "warn": Locale.t("tut_warn_shooter"),  "col": Color(0.90, 0.50, 0.10)},
		{"type": "speeder",  "name": Locale.t("tut_name_speeder"),  "warn": Locale.t("tut_warn_speeder"),  "col": Color(0.20, 0.90, 0.40)},
		{"type": "kamikaze", "name": Locale.t("tut_name_kamikaze"), "warn": Locale.t("tut_warn_kamikaze"), "col": Color(1.00, 0.20, 0.60)},
		{"type": "tank",     "name": Locale.t("tut_name_tank"),     "warn": Locale.t("tut_warn_tank"),     "col": Color(0.55, 0.75, 1.00)},
		{"type": "boss",     "name": Locale.t("tut_name_boss"),     "warn": Locale.t("tut_warn_boss"),     "col": Color(1.00, 0.48, 0.10)},
	]

	for e in enemies:
		grid.add_child(_enemy_card(e["type"], e["name"], e["warn"], e["col"]))

	_add_btn_row(vbox, true, Locale.t("tut_btn_next_gotime"), func(): _show_page(2))
	return root

func _enemy_card(etype: String, ename: String, warn: String, col: Color) -> Panel:
	var card := Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 90)
	var cs := StyleBoxFlat.new()
	cs.bg_color    = Color(col.r*0.06, col.g*0.06, col.b*0.10, 1.0).clamp()
	cs.bg_color    = cs.bg_color.lerp(Color(0.02, 0.05, 0.12), 0.55)
	cs.border_color = Color(col.r*0.55, col.g*0.55, col.b*0.55)
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", cs)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 6; hbox.offset_right = -6
	hbox.offset_top  = 6; hbox.offset_bottom = -6
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	# Thumbnail
	var thumb_script := load("res://scripts/EnemyThumb.gd")
	var thumb: Control = thumb_script.new()
	thumb.set("enemy_type", etype)
	thumb.custom_minimum_size = Vector2(48, 78)
	hbox.add_child(thumb)

	# Name + warning
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	hbox.add_child(info)

	var nl := Label.new()
	nl.text = ename
	nl.add_theme_color_override("font_color", col.lightened(0.25))
	nl.add_theme_font_size_override("font_size", 14)
	info.add_child(nl)

	var wl := Label.new()
	wl.text = warn
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wl.add_theme_color_override("font_color", Color(0.78, 0.92, 1.00))
	wl.add_theme_font_size_override("font_size", 11)
	info.add_child(wl)

	# Danger tip
	var tip := Label.new()
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 10)
	tip.add_theme_color_override("font_color", Color(0.50, 0.70, 0.82))
	match etype:
		"grunt":    tip.text = Locale.t("tut_tip_grunt")
		"shooter":  tip.text = Locale.t("tut_tip_shooter")
		"speeder":  tip.text = Locale.t("tut_tip_speeder")
		"kamikaze": tip.text = Locale.t("tut_tip_kamikaze")
		"tank":     tip.text = Locale.t("tut_tip_tank")
		"boss":     tip.text = Locale.t("tut_tip_boss")
	info.add_child(tip)
	return card

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 2 — READY (Perks + Boss overview, then ENGAGE)
# ─────────────────────────────────────────────────────────────────────────────
func _build_page_ready() -> Control:
	var root := _make_panel(Color(0.00, 0.30, 0.22), Locale.t("tut_ready_title"))
	var vbox: VBoxContainer = root.get_meta("vbox")

	# ── Perks section ────────────────────────────────────────────────────────
	var perk_hdr := _section_header(Locale.t("tut_perks_header"), Color(0.72, 0.40, 1.00))
	vbox.add_child(perk_hdr)

	var perk_desc := Label.new()
	perk_desc.text = Locale.t("tut_perk_desc")
	perk_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	perk_desc.add_theme_color_override("font_color", Color(0.80, 0.94, 1.00))
	perk_desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(perk_desc)

	# Perk slot preview
	var pslots := HBoxContainer.new()
	pslots.add_theme_constant_override("separation", 6)
	pslots.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(pslots)

	var perk_examples := ["Shield Bubble", "Lifesteal", "Double Coins"]
	for i in 3:
		var ps := Panel.new()
		ps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pss := StyleBoxFlat.new()
		pss.bg_color     = Color(0.02, 0.14, 0.24)
		pss.border_color = Color(0.00, 0.80, 1.00)
		pss.set_border_width_all(1)
		pss.set_corner_radius_all(5)
		ps.add_theme_stylebox_override("panel", pss)
		var pl := Label.new()
		pl.text = perk_examples[i]
		pl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		pl.add_theme_color_override("font_color", Color(0.80, 0.97, 1.00))
		pl.add_theme_font_size_override("font_size", 10)
		ps.add_child(pl)
		pslots.add_child(ps)

	_add_divider(vbox)

	# ── Boss section ─────────────────────────────────────────────────────────
	var boss_hdr := _section_header(Locale.t("tut_boss_header"), Color(1.00, 0.42, 0.10))
	vbox.add_child(boss_hdr)

	var boss_row := HBoxContainer.new()
	boss_row.add_theme_constant_override("separation", 12)
	boss_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(boss_row)

	# Mini boss thumbnail
	var bt_script := load("res://scripts/EnemyThumb.gd")
	var boss_thumb: Control = bt_script.new()
	boss_thumb.set("enemy_type", "boss")
	boss_thumb.custom_minimum_size = Vector2(60, 90)
	boss_row.add_child(boss_thumb)

	var boss_info := VBoxContainer.new()
	boss_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_info.add_theme_constant_override("separation", 5)
	boss_row.add_child(boss_info)

	var phases := [
		[Locale.t("tut_phase_1"), Color(0.10, 0.90, 0.15), Locale.t("tut_phase_1_desc")],
		[Locale.t("tut_phase_2"), Color(1.00, 0.80, 0.00), Locale.t("tut_phase_2_desc")],
		[Locale.t("tut_phase_3"), Color(1.00, 0.18, 0.08), Locale.t("tut_phase_3_desc")],
	]
	for ph in phases:
		var ph_row := HBoxContainer.new()
		ph_row.add_theme_constant_override("separation", 6)
		boss_info.add_child(ph_row)

		var ph_lbl := Label.new()
		ph_lbl.text = ph[0]
		ph_lbl.custom_minimum_size = Vector2(58, 0)
		ph_lbl.add_theme_color_override("font_color", ph[1])
		ph_lbl.add_theme_font_size_override("font_size", 12)
		ph_row.add_child(ph_lbl)

		var ph_desc := Label.new()
		ph_desc.text = ph[2]
		ph_desc.add_theme_color_override("font_color", Color(0.80, 0.94, 1.00))
		ph_desc.add_theme_font_size_override("font_size", 12)
		ph_row.add_child(ph_desc)

	var boost_tip := Label.new()
	boost_tip.text = Locale.t("tut_boost_tip")
	boost_tip.add_theme_color_override("font_color", Color(1.00, 0.90, 0.18))
	boost_tip.add_theme_font_size_override("font_size", 11)
	boss_info.add_child(boost_tip)

	# Back + Skip row (no "next" — ENGAGE is the main action)
	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 8)
	vbox.add_child(nav_row)
	var back_btn2 := _make_btn("◀  BACK", Color(0.45, 0.72, 0.88),
		Color(0.02, 0.10, 0.20), Color(0.06, 0.26, 0.42), 14)
	back_btn2.custom_minimum_size = Vector2(90, 42)
	back_btn2.pressed.connect(func(): _show_page(1))
	nav_row.add_child(back_btn2)
	var skip_btn2 := _make_btn(Locale.t("tut_btn_skip"), Color(0.30, 0.50, 0.62),
		Color(0.03, 0.08, 0.14), Color(0.08, 0.22, 0.34), 12)
	skip_btn2.custom_minimum_size = Vector2(62, 42)
	skip_btn2.pressed.connect(_finish_skip)
	nav_row.add_child(skip_btn2)

	# ENGAGE button — launches game directly
	var engage := _make_btn(Locale.t("tut_btn_engage"), Color(0.88, 0.98, 1.00),
		Color(0.00, 0.20, 0.36), Color(0.00, 0.82, 1.00), 17)
	engage.custom_minimum_size = Vector2(0, 50)
	engage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	engage.pressed.connect(_on_engage)
	vbox.add_child(engage)

	return root

func _on_engage() -> void:
	GameState.tutorial_done = true
	GameState.save()
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# ANIMATION (_process)
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _page != 0 or _lane_canvas == null:
		return

	_demo_auto_t += delta

	# Auto-sequence: change lane every 1.4 s
	if abs(_demo_lane - _demo_target) < 4.0:
		_demo_auto_t += 0.0
		if _demo_auto_t > 1.4:
			_demo_auto_t = 0.0
			_demo_seq = (_demo_seq + 1) % DEMO_SEQ.size()
			_demo_target = DEMO_LANES[DEMO_SEQ[_demo_seq]]
			# Trigger a short boost every other move
			if _demo_seq % 2 == 1:
				_demo_boost    = true
				_demo_boost_t  = 0.0

	# Smooth lane slide
	_demo_lane = move_toward(_demo_lane, _demo_target, delta * 240.0)

	# Boost animation
	if _demo_boost:
		_demo_boost_t += delta
		if _demo_boost_t > 0.9:
			_demo_boost = false

	_lane_canvas.queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
# SKIP (always available via keyboard ESC)
# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_finish_skip()

func _finish_skip() -> void:
	GameState.tutorial_done = true
	GameState.save()
	queue_free()

# ─────────────────────────────────────────────────────────────────────────────
# SHARED UI HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _make_panel(band_col: Color, title: String) -> PanelContainer:
	# PanelContainer auto-sizes its height to match content — no dead space
	var panel := PanelContainer.new()
	panel.anchor_left  = 0.0; panel.anchor_right  = 1.0
	panel.anchor_top   = 0.0; panel.anchor_bottom = 0.0
	panel.offset_left  = 14;  panel.offset_right  = -14
	panel.offset_top   = 28
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.02, 0.05, 0.14, 0.98)
	ps.border_color = Color(0.00, 0.78, 1.00)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(16)
	# Zero out PanelContainer's own content margins so layout is explicit
	ps.content_margin_left  = 0; ps.content_margin_right  = 0
	ps.content_margin_top   = 0; ps.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", ps)

	# Outer VBox: header strip + content area (no gap between them)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	panel.add_child(outer)

	# Colour header strip
	var strip := Panel.new()
	strip.custom_minimum_size = Vector2(0, 52)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ss := StyleBoxFlat.new()
	ss.bg_color = band_col
	ss.corner_radius_top_left  = 14; ss.corner_radius_top_right = 14
	strip.add_theme_stylebox_override("panel", ss)
	outer.add_child(strip)

	# Title inside strip
	var tl := Label.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	tl.text = title
	tl.add_theme_color_override("font_color", Color(1.00, 1.00, 1.00, 0.95))
	tl.add_theme_font_size_override("font_size", 20)
	strip.add_child(tl)

	# Content margin
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom", 10)
	outer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Store reference so build functions can find it without fragile child paths
	panel.set_meta("vbox", vbox)
	return panel

func _section_header(text: String, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 15)
	return l

func _add_divider(parent: VBoxContainer) -> void:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.00, 0.55, 0.80, 0.35)
	parent.add_child(div)

func _add_spacer(parent: VBoxContainer) -> void:
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(sp)

func _add_btn_row(parent: VBoxContainer, show_back: bool,
		next_txt: String, next_cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	if show_back:
		var back := _make_btn("◀  BACK", Color(0.45, 0.72, 0.88),
			Color(0.02, 0.10, 0.20), Color(0.06, 0.26, 0.42), 14)
		back.custom_minimum_size = Vector2(90, 42)
		back.pressed.connect(func(): _show_page(_page - 1))
		row.add_child(back)

	var skip := _make_btn(Locale.t("tut_btn_skip"), Color(0.30, 0.50, 0.62),
		Color(0.03, 0.08, 0.14), Color(0.08, 0.22, 0.34), 12)
	skip.custom_minimum_size = Vector2(62, 42)
	skip.pressed.connect(_finish_skip)
	row.add_child(skip)

	var nxt := _make_btn(next_txt, Color(0.88, 0.98, 1.00),
		Color(0.00, 0.14, 0.28), Color(0.00, 0.78, 1.00), 15)
	nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nxt.custom_minimum_size   = Vector2(0, 42)
	nxt.pressed.connect(next_cb)
	row.add_child(nxt)


func _make_btn(txt: String, font_col: Color, bg: Color, border: Color, sz: int) -> Button:
	var btn := Button.new()
	btn.text = txt
	var n := _flat(bg, border)
	var h := _flat(bg.lightened(0.14), border.lightened(0.22))
	var p := _flat(bg.darkened(0.10), border)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus",   n)
	btn.add_theme_color_override("font_color",         font_col)
	btn.add_theme_color_override("font_hover_color",   font_col.lightened(0.12))
	btn.add_theme_color_override("font_pressed_color", font_col.darkened(0.10))
	btn.add_theme_font_size_override("font_size", sz)
	return btn

func _flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	return s
