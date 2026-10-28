extends CanvasLayer
# Full-screen settings overlay.
# Add as a child of any scene; it removes itself when closed.
# Reads/writes GameState.language, GameState.music_volume, GameState.sfx_volume.

const C_BG      := Color(0.02, 0.04, 0.10, 0.97)
const C_CYAN    := Color(0.00, 0.88, 1.00)
const C_CYAN_D  := Color(0.00, 0.14, 0.26)
const C_MAGENTA := Color(0.85, 0.00, 0.58)
const C_TEXT    := Color(0.82, 0.96, 1.00)
const C_MUTED   := Color(0.38, 0.65, 0.82)
const C_DIM     := Color(0.10, 0.18, 0.28)

var _music_slider: HSlider = null
var _sfx_slider:   HSlider = null
var _lang_en_btn:  Button  = null
var _lang_fa_btn:  Button  = null

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	# Fullscreen tinted backdrop
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# Card panel (centred, fixed width)
	var card := Panel.new()
	card.anchor_left   = 0.5;  card.anchor_right  = 0.5
	card.anchor_top    = 0.5;  card.anchor_bottom = 0.5
	card.offset_left   = -200; card.offset_right  =  200
	card.offset_top    = -260; card.offset_bottom =  260
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.03, 0.07, 0.16, 1.0)
	cs.set_border_width_all(2)
	cs.border_color = C_CYAN
	cs.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel", cs)
	root.add_child(card)

	# VBox inside card
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left   =  20;  vb.offset_right  = -20
	vb.offset_top    =  18;  vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 18)
	card.add_child(vb)

	# Title
	var title := Label.new()
	title.text = Locale.t("settings_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", C_CYAN)
	title.add_theme_font_size_override("font_size", 30)
	title.text_direction = Control.TEXT_DIRECTION_AUTO
	vb.add_child(title)

	# Divider
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(C_CYAN, 0.4)
	vb.add_child(div)

	# Music volume
	vb.add_child(_section_label(Locale.t("music_volume")))
	_music_slider = _make_slider(GameState.music_volume)
	_music_slider.value_changed.connect(_on_music_changed)
	vb.add_child(_music_slider)

	# SFX volume
	vb.add_child(_section_label(Locale.t("sfx_volume")))
	_sfx_slider = _make_slider(GameState.sfx_volume)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	vb.add_child(_sfx_slider)

	# Language toggle
	vb.add_child(_section_label(Locale.t("language_label")))
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 10)
	vb.add_child(lang_row)

	_lang_en_btn = _make_lang_btn(Locale.t("lang_en"))
	_lang_fa_btn = _make_lang_btn(Locale.t("lang_fa"))
	_lang_en_btn.pressed.connect(func(): _set_language("en"))
	_lang_fa_btn.pressed.connect(func(): _set_language("fa"))
	lang_row.add_child(_lang_en_btn)
	lang_row.add_child(_lang_fa_btn)
	_refresh_lang_buttons()

	# Spacer
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	# Back button
	var back := Button.new()
	back.text = Locale.t("btn_back")
	back.custom_minimum_size = Vector2(0, 50)
	back.text_direction = Control.TEXT_DIRECTION_AUTO
	_style_btn(back, C_DIM, C_CYAN_D, C_CYAN, C_MUTED, 20)
	back.pressed.connect(_close)
	vb.add_child(back)

func _section_label(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.text_direction = Control.TEXT_DIRECTION_AUTO
	return lbl

func _make_slider(initial: float) -> HSlider:
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step      = 0.01
	sl.value     = initial
	sl.custom_minimum_size = Vector2(0, 32)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Style the slider track
	var track := StyleBoxFlat.new()
	track.bg_color = C_DIM
	track.set_corner_radius_all(4)
	track.content_margin_top    = 10
	track.content_margin_bottom = 10
	var fill := StyleBoxFlat.new()
	fill.bg_color = C_CYAN
	fill.set_corner_radius_all(4)
	fill.content_margin_top    = 10
	fill.content_margin_bottom = 10
	sl.add_theme_stylebox_override("slider",    track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_icon_override("grabber", _make_grabber_icon())
	return sl

func _make_grabber_icon() -> ImageTexture:
	# 24×24 circle grabber
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	for y in 24:
		for x in 24:
			var dx := x - 11.5
			var dy := y - 11.5
			if dx*dx + dy*dy <= 11.5*11.5:
				img.set_pixel(x, y, Color(0.00, 0.88, 1.00, 1.0))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _make_lang_btn(txt: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(120, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text_direction = Control.TEXT_DIRECTION_AUTO
	btn.add_theme_font_size_override("font_size", 16)
	return btn

func _refresh_lang_buttons() -> void:
	var is_en := GameState.language == "en"
	# Active lang = neon cyan fill; inactive = dark outline
	_style_btn(_lang_en_btn,
		C_CYAN if is_en else C_DIM,
		C_CYAN if is_en else C_DIM,
		C_CYAN,
		Color(0.02, 0.05, 0.12) if is_en else C_TEXT,
		14)
	_style_btn(_lang_fa_btn,
		Color(0.18, 0.00, 0.14) if not is_en else C_DIM,
		C_MAGENTA if not is_en else C_DIM,
		C_MAGENTA,
		Color(1.00, 0.78, 1.00) if not is_en else C_TEXT,
		14)

func _style_btn(btn: Button, bg: Color, bg_h: Color, border: Color, font_col: Color, fsz: int) -> void:
	var n := _flat(bg,   border)
	var h := _flat(bg_h, border)
	var p := _flat(bg_h.darkened(0.15), border)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus",   n)
	btn.add_theme_color_override("font_color",         font_col)
	btn.add_theme_color_override("font_hover_color",   font_col)
	btn.add_theme_color_override("font_pressed_color", font_col)
	btn.add_theme_font_size_override("font_size", fsz)

func _flat(bg: Color, border: Color, r: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(r)
	return s

# ── Callbacks ─────────────────────────────────────────────────────────────────
func _on_music_changed(val: float) -> void:
	GameState.music_volume = val
	Music.set_volume(val)
	GameState.save()

func _on_sfx_changed(val: float) -> void:
	GameState.sfx_volume = val
	SFX.sfx_volume = val
	GameState.save()

func _set_language(lang: String) -> void:
	if GameState.language == lang:
		return  # already selected, nothing to do
	SFX.play_click()
	_show_language_confirm(lang)

func _show_language_confirm(lang: String) -> void:
	# Dim overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Confirmation card
	var card := Panel.new()
	card.anchor_left = 0.5; card.anchor_right  = 0.5
	card.anchor_top  = 0.5; card.anchor_bottom = 0.5
	card.offset_left = -165; card.offset_right  =  165
	card.offset_top  = -90;  card.offset_bottom =  90
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.03, 0.07, 0.16, 1.0)
	cs.set_border_width_all(2)
	cs.border_color = C_CYAN
	cs.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel", cs)
	overlay.add_child(card)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 16; vb.offset_right = -16
	vb.offset_top  = 16; vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	var msg := Label.new()
	msg.text = Locale.t("lang_confirm")
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_color_override("font_color", C_TEXT)
	msg.add_theme_font_size_override("font_size", 16)
	msg.text_direction = Control.TEXT_DIRECTION_AUTO
	vb.add_child(msg)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)

	var yes_btn := Button.new()
	yes_btn.text = Locale.t("btn_yes")
	yes_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes_btn.custom_minimum_size = Vector2(0, 44)
	yes_btn.text_direction = Control.TEXT_DIRECTION_AUTO
	_style_btn(yes_btn, C_CYAN_D, C_CYAN_D, C_CYAN, Color(0.88, 0.98, 1.00), 16)
	row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = Locale.t("btn_no")
	no_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no_btn.custom_minimum_size = Vector2(0, 44)
	no_btn.text_direction = Control.TEXT_DIRECTION_AUTO
	_style_btn(no_btn, C_DIM, C_DIM, C_MUTED, C_TEXT, 16)
	row.add_child(no_btn)

	yes_btn.pressed.connect(func():
		GameState.language = lang
		GameState.save()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	no_btn.pressed.connect(func():
		overlay.queue_free()
		_refresh_lang_buttons()
	)

func _close() -> void:
	SFX.play_click()
	GameState.save()
	queue_free()
