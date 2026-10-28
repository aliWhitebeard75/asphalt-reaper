extends Control

# ---- Palette -----------------------------------------------------------------
const C_BG      := Color(0.06, 0.04, 0.08)
const C_CARD    := Color(0.10, 0.06, 0.14)
const C_BORDER  := Color(0.28, 0.09, 0.36)
const C_GOLD    := Color(1.00, 0.82, 0.10)
const C_GEM     := Color(0.30, 0.90, 1.00)
const C_TEXT    := Color(0.93, 0.89, 0.96)
const C_MUTED   := Color(0.54, 0.47, 0.62)
const C_RED     := Color(0.80, 0.10, 0.10)
const C_GREEN   := Color(0.20, 0.85, 0.35)
const C_DIM     := Color(0.25, 0.20, 0.32)
const C_TAB_ON  := Color(0.28, 0.08, 0.44)
const C_TAB_OFF := Color(0.10, 0.06, 0.16)

var current_tab: String = "skins"
var coins_lbl: Label = null
var gems_lbl: Label  = null
var item_list: VBoxContainer = null
var tab_btns: Dictionary = {}
var _scroll: ScrollContainer = null

# Touch scroll state
var _touch_start_y: float = 0.0
var _scroll_start: int = 0
var _touch_id: int = -1
var _velocity: float = 0.0
var _last_y: float = 0.0
var _last_t: int = 0
var _vel_samples: Array = []

# ---- Build -------------------------------------------------------------------
func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _flat(C_BG, C_BG, 0.0, 0))
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12;  vbox.offset_right  = -12
	vbox.offset_top  = 14;  vbox.offset_bottom  = -12
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	vbox.add_child(_build_header())
	vbox.add_child(_build_tabs())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_scroll = scroll

	item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 8)
	scroll.add_child(item_list)

	var back := Button.new()
	back.text = Locale.t("btn_back")
	back.text_direction = Control.TEXT_DIRECTION_AUTO
	back.custom_minimum_size = Vector2(0, 46)
	_style_btn(back,
		Color(0.10, 0.06, 0.16), C_BORDER,
		Color(0.16, 0.09, 0.24), C_BORDER,
		Color(0.07, 0.04, 0.11), C_MUTED, 15)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(back)

	_build_content()

func _build_header() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 58)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.09, 0.05, 0.13)
	ps.border_color = C_RED
	ps.border_width_bottom = 2
	ps.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", ps)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 16; hbox.offset_right = -16
	hbox.offset_top  = 8;  hbox.offset_bottom = -8
	panel.add_child(hbox)

	var title := Label.new()
	title.text = Locale.t("shop_title")
	title.text_direction = Control.TEXT_DIRECTION_AUTO
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color",    C_RED)
	title.add_theme_font_size_override("font_size", 28)
	hbox.add_child(title)

	coins_lbl = Label.new()
	coins_lbl.add_theme_color_override("font_color",    C_GOLD)
	coins_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(coins_lbl)

	var sp := Control.new(); sp.custom_minimum_size = Vector2(14, 0)
	hbox.add_child(sp)

	gems_lbl = Label.new()
	gems_lbl.add_theme_color_override("font_color",    C_GEM)
	gems_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(gems_lbl)

	_refresh_header()
	return panel

func _refresh_header() -> void:
	if coins_lbl: coins_lbl.text = "◆ %d" % GameState.coins
	if gems_lbl:
		gems_lbl.text = "♦ %d %s" % [GameState.gems, Locale.t("gems_label")]
		gems_lbl.text_direction = Control.TEXT_DIRECTION_AUTO

func _build_tabs() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 38)
	hbox.add_theme_constant_override("separation", 6)
	for k in ["skins", "boosts", "premium"]:
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = Locale.t("tab_" + k)
		btn.text_direction = Control.TEXT_DIRECTION_AUTO
		btn.pressed.connect(_on_tab.bind(k))
		tab_btns[k] = btn
		hbox.add_child(btn)
	_refresh_tabs()
	return hbox

func _refresh_tabs() -> void:
	for k in tab_btns:
		var btn: Button = tab_btns[k]
		var on: bool = k == current_tab
		var border: Color = Color(0.65, 0.20, 0.90) if on else C_BORDER
		btn.add_theme_stylebox_override("normal",  _flat(C_TAB_ON if on else C_TAB_OFF, border, 8.0))
		btn.add_theme_stylebox_override("hover",   _flat(Color(0.20, 0.08, 0.32), border, 8.0))
		btn.add_theme_stylebox_override("pressed", _flat(C_TAB_ON, border, 8.0))
		btn.add_theme_stylebox_override("focus",   _flat(C_TAB_ON if on else C_TAB_OFF, border, 8.0))
		btn.add_theme_color_override("font_color",       C_TEXT if on else C_MUTED)
		btn.add_theme_color_override("font_hover_color", C_TEXT)
		btn.add_theme_font_size_override("font_size", 14)

func _on_tab(k: String) -> void:
	current_tab = k
	_refresh_tabs()
	_build_content()

func _process(delta: float) -> void:
	if _touch_id != -1:
		return
	if abs(_velocity) < 4.0:
		_velocity = 0.0
		return
	_scroll.scroll_vertical += int(_velocity * delta)
	_velocity *= 0.88

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_scroll):
		return
	var win_h: float = float(DisplayServer.window_get_size().y)
	var canvas_h: float = get_viewport_rect().size.y
	var sy: float = canvas_h / win_h if win_h > 0.0 else 1.0

	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_y = event.position.y
			_scroll_start  = _scroll.scroll_vertical
			_touch_id      = event.index
			_velocity      = 0.0
			_last_y        = event.position.y
			_last_t        = Time.get_ticks_msec()
			_vel_samples.clear()
		elif event.index == _touch_id:
			_touch_id = -1
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
		var dy: int = int((_touch_start_y - event.position.y) * sy)
		_scroll.scroll_vertical = _scroll_start + dy

		var now_t: int = Time.get_ticks_msec()
		var dt_ms: int = now_t - _last_t
		if dt_ms >= 8:
			_vel_samples.append([_last_y - event.position.y, float(dt_ms) / 1000.0])
			if _vel_samples.size() > 5:
				_vel_samples.pop_front()
			_last_y = event.position.y
			_last_t = now_t
		get_viewport().set_input_as_handled()

func _build_content() -> void:
	for c in item_list.get_children():
		c.queue_free()
	match current_tab:
		"skins":
			for skin in GameState.SKINS:
				item_list.add_child(_skin_card(skin))
		"boosts":
			item_list.add_child(_note(Locale.t("single_use_note")))
			for boost in GameState.BOOSTS:
				item_list.add_child(_consumable_card(boost, "coins"))
		"premium":
			item_list.add_child(_gems_banner())
			for prem in GameState.PREMIUM:
				item_list.add_child(_consumable_card(prem, "gems"))

# ---- Skin card ---------------------------------------------------------------
func _skin_card(skin: Dictionary) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 80)
	card.add_theme_stylebox_override("panel", _flat(C_CARD, C_BORDER, 10.0))

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12; hbox.offset_right = -12
	hbox.offset_top  = 10; hbox.offset_bottom = -10
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Color swatch
	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(46, 58)
	var sw := StyleBoxFlat.new()
	sw.bg_color = skin["color"]
	sw.border_color = skin["color"].lightened(0.35)
	sw.set_border_width_all(2)
	sw.set_corner_radius_all(6)
	swatch.add_theme_stylebox_override("panel", sw)
	hbox.add_child(swatch)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 5)
	hbox.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = Locale.t("skin_" + skin["key"])
	name_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	name_lbl.add_theme_color_override("font_color",    C_TEXT)
	name_lbl.add_theme_font_size_override("font_size", 16)
	info.add_child(name_lbl)

	var owned: bool = GameState.owned_skins.has(skin["key"])
	var active: bool = GameState.active_skin == skin["key"]

	var sub := Label.new()
	if active:
		sub.text = Locale.t("equipped")
		sub.add_theme_color_override("font_color", C_GREEN)
	elif owned:
		sub.text = Locale.t("owned")
		sub.add_theme_color_override("font_color", C_MUTED)
	elif skin["price"] == 0:
		sub.text = Locale.t("free_label")
		sub.add_theme_color_override("font_color", C_GREEN)
	else:
		sub.text = "◆ %d %s" % [skin["price"], Locale.t("coins_label")]
		sub.add_theme_color_override("font_color", C_GOLD)
	sub.text_direction = Control.TEXT_DIRECTION_AUTO
	sub.add_theme_font_size_override("font_size", 13)
	info.add_child(sub)

	# Action button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 0)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text_direction = Control.TEXT_DIRECTION_AUTO

	if active:
		btn.text = Locale.t("active_label")
		btn.disabled = true
		_style_btn(btn, C_DIM, C_DIM, C_DIM, C_DIM, C_DIM, C_MUTED, 13)
	elif owned:
		btn.text = Locale.t("btn_equip")
		_style_btn(btn,
			Color(0.08, 0.26, 0.10), C_GREEN,
			Color(0.12, 0.36, 0.14), C_GREEN,
			Color(0.05, 0.18, 0.08), C_GREEN, 13)
		btn.pressed.connect(func():
			GameState.set_active_skin(skin["key"])
			_build_content())
	elif GameState.coins >= skin["price"] or skin["price"] == 0:
		btn.text = Locale.t("btn_buy")
		_style_btn(btn,
			Color(0.50, 0.06, 0.06), C_RED,
			Color(0.65, 0.10, 0.10), C_RED,
			Color(0.32, 0.04, 0.04), Color.WHITE, 13)
		btn.pressed.connect(func():
			GameState.buy_skin(skin["key"])
			_build_content()
			_refresh_header())
	else:
		btn.text = Locale.t("locked_label")
		btn.disabled = true
		_style_btn(btn, C_DIM, C_DIM, C_DIM, C_DIM, C_DIM, C_MUTED, 13)

	hbox.add_child(btn)
	return card

# ---- Consumable card (boosts + premium) -------------------------------------
func _consumable_card(item: Dictionary, currency: String) -> Panel:
	var is_gems: bool = currency == "gems"
	var border_col: Color = C_GEM if is_gems else C_BORDER
	var bg_col: Color = Color(0.06, 0.09, 0.16) if is_gems else C_CARD

	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 76)
	card.add_theme_stylebox_override("panel", _flat(bg_col, border_col, 10.0))

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 14; hbox.offset_right = -14
	hbox.offset_top  = 10; hbox.offset_bottom = -10
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	hbox.add_child(info)

	var name_lbl := Label.new()
	var name_key: String = ("prem_" if is_gems else "boost_") + item["key"]
	name_lbl.text = Locale.t(name_key)
	name_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	name_lbl.add_theme_color_override("font_color",    C_GEM if is_gems else C_TEXT)
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = Locale.t("desc_" + item["key"])
	desc_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	desc_lbl.add_theme_color_override("font_color",    C_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(desc_lbl)

	# Right column
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(88, 0)
	right.add_theme_constant_override("separation", 4)
	hbox.add_child(right)

	var stock: int = GameState.consumables.get(item["key"], 0)
	var stock_lbl := Label.new()
	stock_lbl.text = "x%d %s" % [stock, Locale.t("owned")]
	stock_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	stock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_lbl.add_theme_color_override("font_color",    C_GREEN if stock > 0 else C_MUTED)
	stock_lbl.add_theme_font_size_override("font_size", 12)
	right.add_child(stock_lbl)

	var price_lbl := Label.new()
	price_lbl.text = "♦ %d %s" % [item["price"], Locale.t("gems_label")] if is_gems else "◆ %d" % item["price"]
	price_lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_color_override("font_color",    C_GEM if is_gems else C_GOLD)
	price_lbl.add_theme_font_size_override("font_size", 12)
	right.add_child(price_lbl)

	var btn := Button.new()
	btn.text = Locale.t("btn_buy")
	btn.text_direction = Control.TEXT_DIRECTION_AUTO
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var balance: int = GameState.gems if is_gems else GameState.coins
	if balance >= item["price"]:
		if is_gems:
			_style_btn(btn,
				Color(0.04, 0.18, 0.30), C_GEM,
				Color(0.06, 0.26, 0.42), C_GEM,
				Color(0.02, 0.12, 0.20), C_GEM, 13)
		else:
			_style_btn(btn,
				Color(0.50, 0.06, 0.06), C_RED,
				Color(0.65, 0.10, 0.10), C_RED,
				Color(0.32, 0.04, 0.04), Color.WHITE, 13)
		btn.pressed.connect(func():
			if is_gems: GameState.buy_premium(item["key"])
			else:       GameState.buy_boost(item["key"])
			_build_content()
			_refresh_header())
	else:
		btn.disabled = true
		_style_btn(btn, C_DIM, C_DIM, C_DIM, C_DIM, C_DIM, C_MUTED, 13)

	right.add_child(btn)
	return card

# ---- Helper nodes ------------------------------------------------------------
func _note(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color",    C_MUTED)
	lbl.add_theme_font_size_override("font_size", 12)
	return lbl

func _gems_banner() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 60)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.09, 0.17)
	ps.border_color = C_GEM
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", ps)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 16; hbox.offset_right = -16
	hbox.offset_top  = 8;  hbox.offset_bottom = -8
	panel.add_child(hbox)

	var bal := Label.new()
	bal.text = "♦ %d %s" % [GameState.gems, Locale.t("gems_label")]
	bal.text_direction = Control.TEXT_DIRECTION_AUTO
	bal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bal.add_theme_color_override("font_color",    C_GEM)
	bal.add_theme_font_size_override("font_size", 20)
	hbox.add_child(bal)

	var hint := Label.new()
	hint.text = Locale.t("gems_earn_note")
	hint.text_direction = Control.TEXT_DIRECTION_AUTO
	hint.add_theme_color_override("font_color",    C_MUTED)
	hint.add_theme_font_size_override("font_size", 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(hint)

	return panel

# ---- Style helpers -----------------------------------------------------------
func _flat(bg: Color, border: Color, r: float = 8.0, bw: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(int(r))
	return s

func _style_btn(btn: Button,
		bg_n: Color, bd_n: Color,
		bg_h: Color, bd_h: Color,
		bg_p: Color, font_col: Color, font_sz: int) -> void:
	btn.add_theme_stylebox_override("normal",   _flat(bg_n, bd_n, 8.0))
	btn.add_theme_stylebox_override("hover",    _flat(bg_h, bd_h, 8.0))
	btn.add_theme_stylebox_override("pressed",  _flat(bg_p, bd_n, 8.0))
	btn.add_theme_stylebox_override("disabled", _flat(C_DIM, C_DIM, 8.0))
	btn.add_theme_stylebox_override("focus",    _flat(bg_n, bd_n, 8.0))
	btn.add_theme_color_override("font_color",          font_col)
	btn.add_theme_color_override("font_hover_color",    font_col.lightened(0.15))
	btn.add_theme_color_override("font_pressed_color",  font_col.darkened(0.10))
	btn.add_theme_color_override("font_disabled_color", C_MUTED)
	btn.add_theme_font_size_override("font_size", font_sz)
