extends CanvasLayer

@onready var top_bar: Panel         = $TopBar
@onready var health_bar: ProgressBar = $TopBar/HBoxInner/HealthBar
@onready var coin_label: Label       = $TopBar/HBoxInner/CoinLabel
@onready var distance_label: Label   = $TopBar/HBoxInner/DistLabel

@onready var boss_section: Panel     = $BossSection
@onready var boss_name_label: Label  = $BossSection/BossVBox/BossNameLabel
@onready var boss_bar: ProgressBar   = $BossSection/BossVBox/BossBar

@onready var boss_warning: Label     = $BossWarning
@onready var perk_notif: Label       = $PerkNotif
@onready var perk_list: Label        = $PerkList

var notif_timer: float    = 0.0
var warning_timer: float  = 0.0
var warning_flash: float  = 0.0

# ─── Perk slot visual + damage flash ──────────────────────────────────────────
var _slot_panels: Array   = []   # [{panel, label}, ...]
var _damage_flash: ColorRect = null
var _flash_alpha: float   = 0.0
var _tracked_hp: float    = -1.0
var _parry_flash: ColorRect  = null
var _parry_flash_alpha: float = 0.0

# ─── HP overlay + shield ──────────────────────────────────────────────────────
var _hp_text: Label              = null
var _shield_bar: ProgressBar     = null
var _shield_row: HBoxContainer   = null
var _hp_pulse: float             = 0.0
var _best_dist_label: Label      = null

# ─── Colors ───────────────────────────────────────────────────────────────────
const C_BG        = Color(0.02, 0.05, 0.12, 0.96)   # deep space navy
const C_BORDER    = Color(0.00, 0.78, 1.00, 1.0)     # neon cyan
const C_HP_FILL   = Color(0.08, 0.95, 0.45, 1.0)     # neon green (full HP)
const C_HP_BG     = Color(0.02, 0.12, 0.06, 1.0)     # dark green bg
const C_BOSS_FILL = Color(1.00, 0.48, 0.00, 1.0)     # neon orange
const C_BOSS_BG   = Color(0.12, 0.05, 0.00, 1.0)
const C_GOLD      = Color(1.00, 0.90, 0.18, 1.0)     # bright gold
const C_WHITE     = Color(0.88, 0.96, 1.00, 1.0)     # ice white
const C_WARN      = Color(1.00, 0.32, 0.05, 1.0)     # neon orange-red

# ─── Ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	perk_notif.visible   = false
	boss_warning.visible = false
	boss_section.visible = false
	perk_notif.modulate.a = 0.0
	perk_list.visible    = false   # replaced by _build_perk_slots()

	_apply_top_bar_style()
	_apply_health_bar_style()
	_apply_boss_bar_style()
	_apply_label_styles()
	_build_perk_slots()
	_build_damage_flash()
	_enhance_top_bar()

# ─────────────────────────── Style helpers ────────────────────────────────────
func _make_flat(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left   = bw
	s.border_width_top    = bw
	s.border_width_right  = bw
	s.border_width_bottom = bw
	s.border_color = border
	s.corner_radius_top_left    = radius
	s.corner_radius_top_right   = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s

func _make_bar_style(bg: Color, fill: Color, radius: int = 5) -> Array:
	var bg_s = StyleBoxFlat.new()
	bg_s.bg_color = bg
	bg_s.corner_radius_top_left    = radius
	bg_s.corner_radius_top_right   = radius
	bg_s.corner_radius_bottom_left = radius
	bg_s.corner_radius_bottom_right = radius

	var fill_s = StyleBoxFlat.new()
	fill_s.bg_color = fill
	fill_s.corner_radius_top_left    = radius
	fill_s.corner_radius_top_right   = radius
	fill_s.corner_radius_bottom_left = radius
	fill_s.corner_radius_bottom_right = radius
	return [bg_s, fill_s]

func _apply_top_bar_style() -> void:
	pass   # style applied in _enhance_top_bar() after layout is final

func _apply_health_bar_style() -> void:
	var styles = _make_bar_style(C_HP_BG, C_HP_FILL, 5)
	health_bar.add_theme_stylebox_override("background", styles[0])
	health_bar.add_theme_stylebox_override("fill", styles[1])

func _apply_boss_bar_style() -> void:
	var panel_s = StyleBoxFlat.new()
	panel_s.bg_color = Color(0.02, 0.06, 0.14, 0.96)
	panel_s.border_color = C_WARN
	panel_s.set_border_width_all(2)
	panel_s.border_width_top = 0
	panel_s.set_corner_radius_all(6)
	boss_section.add_theme_stylebox_override("panel", panel_s)

	var styles = _make_bar_style(C_BOSS_BG, C_BOSS_FILL, 4)
	boss_bar.add_theme_stylebox_override("background", styles[0])
	boss_bar.add_theme_stylebox_override("fill", styles[1])

	boss_name_label.add_theme_color_override("font_color", Color(1.00, 0.60, 0.10))
	boss_name_label.add_theme_font_size_override("font_size", 12)

func _apply_label_styles() -> void:
	coin_label.add_theme_color_override("font_color", Color(1.00, 0.90, 0.18, 1.0))
	coin_label.add_theme_font_size_override("font_size", 22)

	distance_label.add_theme_color_override("font_color", Color(0.30, 1.00, 0.78, 1.0))
	distance_label.add_theme_font_size_override("font_size", 22)

	perk_notif.add_theme_color_override("font_color", Color(0.00, 0.92, 1.00))
	perk_notif.add_theme_font_size_override("font_size", 20)

	boss_warning.add_theme_color_override("font_color", C_WARN)
	boss_warning.add_theme_font_size_override("font_size", 26)

	perk_list.add_theme_color_override("font_color", Color(0.40, 0.75, 0.90, 0.80))
	perk_list.add_theme_font_size_override("font_size", 12)

# ─── Process ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Perk notification fade
	if notif_timer > 0.0:
		notif_timer -= delta
		perk_notif.modulate.a = min(notif_timer / 0.5, 1.0)
		if notif_timer <= 0.0:
			perk_notif.visible = false

	# Boss warning flash
	if warning_timer > 0.0:
		warning_timer -= delta
		warning_flash += delta * 8.0
		boss_warning.modulate.a = clamp((sin(warning_flash) + 1.0) * 0.5 + 0.3, 0.0, 1.0)
		if warning_timer <= 0.0:
			boss_warning.visible = false

	# Damage flash fade
	if _flash_alpha > 0.0:
		_flash_alpha -= delta * 5.0
		if _damage_flash:
			_damage_flash.color = Color(0.85, 0.0, 0.0, maxf(0.0, _flash_alpha))

	# Parry flash fade
	if _parry_flash_alpha > 0.0:
		_parry_flash_alpha -= delta * 3.5
		if _parry_flash:
			_parry_flash.color = Color(0.0, 0.85, 1.0, maxf(0.0, _parry_flash_alpha))

	# Low-HP pulse (< 28% health)
	var hp_ratio: float = health_bar.value / health_bar.max_value if health_bar.max_value > 0 else 1.0
	if hp_ratio < 0.28:
		_hp_pulse += delta * 6.0
		var alpha: float = clamp(0.55 + sin(_hp_pulse) * 0.45, 0.10, 1.0)
		health_bar.modulate.a = alpha
		if _hp_text:
			_hp_text.modulate.a = alpha
	else:
		health_bar.modulate.a = 1.0
		_hp_pulse = 0.0
		if _hp_text:
			_hp_text.modulate.a = 1.0

# ─── Public API ───────────────────────────────────────────────────────────────
func update_health(hp: float, max_hp: float) -> void:
	# Detect damage for flash + SFX
	if _tracked_hp >= 0.0 and hp < _tracked_hp:
		_flash_alpha = 0.50
		SFX.play_damage()
	_tracked_hp = hp
	health_bar.max_value = max_hp
	health_bar.value = hp
	# Tint bar neon-green → yellow → neon-red as HP drops
	var ratio = hp / max_hp if max_hp > 0 else 1.0
	if _hp_text:
		_hp_text.text = "%d / %d" % [int(hp), int(max_hp)]
		var nc: Color = C_HP_FILL if ratio > 0.55 else (Color(1.00, 0.80, 0.00) if ratio > 0.28 else Color(1.00, 0.50, 0.50))
		_hp_text.add_theme_color_override("font_color", nc)
	var fill_col: Color
	if   ratio > 0.55: fill_col = C_HP_FILL
	elif ratio > 0.28: fill_col = Color(1.00, 0.80, 0.00)
	else:              fill_col = Color(1.00, 0.18, 0.08)
	var fill_s = _make_flat(fill_col, fill_col, 0, 5)
	health_bar.add_theme_stylebox_override("fill", fill_s)

func update_coins(amount: int) -> void:
	coin_label.text = "%d" % amount

func update_distance(dist: float) -> void:
	distance_label.text = "%.0f m" % dist

# ── Boss bar ──────────────────────────────────────────────────────────────────
func show_zone_banner(zone_name: String) -> void:
	boss_warning.add_theme_color_override("font_color", Color(0.00, 0.92, 1.00))
	boss_warning.add_theme_font_size_override("font_size", 20)
	boss_warning.text    = "◈  " + zone_name + "  ◈"
	boss_warning.visible = true
	warning_timer = 2.5
	warning_flash = 0.0

func show_boss_warning(boss_name: String) -> void:
	boss_section.visible = true
	boss_name_label.text = boss_name
	boss_warning.add_theme_color_override("font_color", C_WARN)
	boss_warning.add_theme_font_size_override("font_size", 24)
	boss_warning.text    = "⟨⟨  " + boss_name + "  ⟩⟩"
	boss_warning.visible = true
	warning_timer = 3.5
	warning_flash = 0.0

func update_boss_health(hp: float, max_hp: float) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = hp
	# Color shifts as boss loses health
	var ratio = hp / max_hp if max_hp > 0 else 1.0
	var fill_col: Color
	if   ratio > 0.55: fill_col = C_BOSS_FILL
	elif ratio > 0.25: fill_col = Color(1.00, 0.78, 0.00)
	else:              fill_col = Color(1.00, 0.14, 0.08)
	var fill_s = _make_flat(fill_col, fill_col, 0, 4)
	boss_bar.add_theme_stylebox_override("fill", fill_s)

func show_boss_phase(phase: int) -> void:
	boss_warning.text    = "◤ " + Locale.t("phase_label") + " " + str(phase) + " ◥"
	boss_warning.visible = true
	warning_timer = 2.5
	warning_flash = 0.0

func hide_boss_bar() -> void:
	boss_section.visible  = false
	boss_warning.visible  = false

# ── Perk notification ─────────────────────────────────────────────────────────
func show_perk_notification(perk_name: String) -> void:
	perk_notif.text = "✦ " + perk_name + " ✦"
	perk_notif.add_theme_color_override("font_color", Color(0.00, 0.92, 1.00))
	perk_notif.add_theme_font_size_override("font_size", 20)
	perk_notif.visible = true
	perk_notif.modulate.a = 1.0
	notif_timer = 2.5
	_refresh_perk_list()

func _refresh_perk_list() -> void:
	if _slot_panels.is_empty():
		return
	var perks = GameState.current_perks
	for i in 3:
		var d  = _slot_panels[i]
		var sp: Panel = d["panel"]
		var lbl: Label = d["label"]
		if i < perks.size():
			sp.add_theme_stylebox_override("panel",
				_make_flat(Color(0.02, 0.15, 0.24), Color(0.00, 0.82, 1.00), 1, 5))
			lbl.text = Locale.t("perk_" + perks[i])
			lbl.text_direction = Control.TEXT_DIRECTION_AUTO
			lbl.add_theme_color_override("font_color", Color(0.80, 0.97, 1.00))
		else:
			sp.add_theme_stylebox_override("panel",
				_make_flat(Color(0.02, 0.06, 0.10), Color(0.06, 0.28, 0.40), 1, 5))
			lbl.text = "—"
			lbl.add_theme_color_override("font_color", Color(0.20, 0.40, 0.52))

# ─── Perk slot panel builder ──────────────────────────────────────────────────
func _build_perk_slots() -> void:
	# Outer dark bar pinned to bottom of screen
	var outer := Panel.new()
	outer.anchor_left   = 0.0;  outer.anchor_right  = 1.0
	outer.anchor_top    = 1.0;  outer.anchor_bottom = 1.0
	outer.offset_left   = 0.0;  outer.offset_right  = 0.0
	outer.offset_top    = -56.0; outer.offset_bottom = 0.0
	outer.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var os := StyleBoxFlat.new()
	os.bg_color = Color(0.02, 0.05, 0.12, 0.92)
	os.border_color = Color(0.00, 0.55, 0.80, 1.0)
	os.border_width_top = 2
	outer.add_theme_stylebox_override("panel", os)
	add_child(outer)

	# Header label "PERKS"
	var hdr := Label.new()
	hdr.text = Locale.t("perks_label")
	hdr.text_direction = Control.TEXT_DIRECTION_AUTO
	hdr.anchor_left   = 0.0;  hdr.anchor_right  = 1.0
	hdr.anchor_top    = 0.0;  hdr.anchor_bottom = 0.0
	hdr.offset_left   = 8.0;  hdr.offset_top    = 3.0
	hdr.offset_right  = -8.0; hdr.offset_bottom = 16.0
	hdr.add_theme_color_override("font_color", Color(0.00, 0.75, 0.95))
	hdr.add_theme_font_size_override("font_size", 9)
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(hdr)

	# Three slot boxes side by side
	var hbox := HBoxContainer.new()
	hbox.anchor_left    = 0.0;  hbox.anchor_right  = 1.0
	hbox.anchor_top     = 0.0;  hbox.anchor_bottom = 1.0
	hbox.offset_left    = 6.0;  hbox.offset_right  = -6.0
	hbox.offset_top     = 16.0; hbox.offset_bottom = -5.0
	hbox.add_theme_constant_override("separation", 5)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(hbox)

	_slot_panels = []
	for _i in 3:
		var sp := Panel.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(sp)

		var lbl := Label.new()
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.offset_left = 4; lbl.offset_right = -4
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.add_child(lbl)

		_slot_panels.append({"panel": sp, "label": lbl})

	_refresh_perk_list()

# ─── Damage flash builder ─────────────────────────────────────────────────────
func _build_damage_flash() -> void:
	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.85, 0.0, 0.0, 0.0)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_damage_flash)

	_parry_flash = ColorRect.new()
	_parry_flash.color = Color(0.0, 0.85, 1.0, 0.0)
	_parry_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parry_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_parry_flash)

# ─── Enhanced top bar ─────────────────────────────────────────────────────────
func _enhance_top_bar() -> void:
	const BAR_TOP:    float = 0.0
	const BAR_BOTTOM: float = 94.0    # 94 px tall, flush with screen top
	const PAD:        float = 10.0
	const DIV_X:      float = 286.0   # left/right split

	# ── Re-parent @onready labels out of HBoxContainer into top_bar ──────────
	# (HBoxContainer overrides child positions; we need free placement)
	var hbi := $TopBar/HBoxInner
	hbi.remove_child(health_bar)
	top_bar.add_child(health_bar)
	hbi.remove_child(coin_label)
	top_bar.add_child(coin_label)
	hbi.remove_child(distance_label)
	top_bar.add_child(distance_label)
	hbi.visible = false

	# ── Bar background — layered for depth ───────────────────────────────────
	top_bar.anchor_top    = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_top    = BAR_TOP
	top_bar.offset_bottom = BAR_BOTTOM

	var bar_s := StyleBoxFlat.new()
	bar_s.bg_color = Color(0.03, 0.06, 0.14, 0.98)
	bar_s.border_color = Color(0.00, 0.70, 1.00, 1.0)
	bar_s.border_width_bottom = 2
	bar_s.corner_radius_bottom_left  = 8
	bar_s.corner_radius_bottom_right = 8
	top_bar.add_theme_stylebox_override("panel", bar_s)

	# Subtle highlight stripe at very top of bar
	var top_stripe := ColorRect.new()
	top_stripe.color = Color(0.00, 0.75, 1.00, 0.18)
	top_stripe.anchor_left = 0.0;  top_stripe.anchor_right = 1.0
	top_stripe.anchor_top  = 0.0;  top_stripe.anchor_bottom = 0.0
	top_stripe.offset_top  = 0.0;  top_stripe.offset_bottom = 3.0
	top_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(top_stripe)

	# ── LEFT ZONE — heart + HP text + HP bar ─────────────────────────────────
	# ♥ heart
	var heart := Label.new()
	heart.text = "♥"
	heart.add_theme_color_override("font_color", Color(1.00, 0.18, 0.35))
	heart.add_theme_font_size_override("font_size", 28)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart.anchor_left = 0.0; heart.anchor_right  = 0.0
	heart.anchor_top  = 0.0; heart.anchor_bottom = 0.0
	heart.offset_left = PAD;       heart.offset_top    = 6.0
	heart.offset_right = PAD + 30.0; heart.offset_bottom = 38.0
	top_bar.add_child(heart)

	# HP text "175 / 175"
	_hp_text = Label.new()
	_hp_text.text = "%d / %d" % [int(health_bar.value), int(health_bar.max_value)]
	_hp_text.add_theme_color_override("font_color", C_HP_FILL)
	_hp_text.add_theme_font_size_override("font_size", 19)
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_text.anchor_left = 0.0; _hp_text.anchor_right  = 0.0
	_hp_text.anchor_top  = 0.0; _hp_text.anchor_bottom = 0.0
	_hp_text.offset_left  = PAD + 32.0; _hp_text.offset_top    = 4.0
	_hp_text.offset_right = DIV_X - 4.0; _hp_text.offset_bottom = 36.0
	top_bar.add_child(_hp_text)

	# HP bar — thick, prominent
	health_bar.show_percentage = false
	health_bar.anchor_left = 0.0; health_bar.anchor_right  = 0.0
	health_bar.anchor_top  = 0.0; health_bar.anchor_bottom = 0.0
	health_bar.offset_left   = PAD + 32.0
	health_bar.offset_right  = DIV_X - 4.0
	health_bar.offset_top    = 42.0
	health_bar.offset_bottom = 68.0   # 26 px tall

	# Shield row below HP bar
	_shield_row = HBoxContainer.new()
	_shield_row.anchor_left = 0.0; _shield_row.anchor_right  = 0.0
	_shield_row.anchor_top  = 0.0; _shield_row.anchor_bottom = 0.0
	_shield_row.offset_left   = PAD + 32.0; _shield_row.offset_right  = DIV_X - 4.0
	_shield_row.offset_top    = 72.0;       _shield_row.offset_bottom = 88.0
	_shield_row.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_shield_row.visible = false
	top_bar.add_child(_shield_row)

	var s_icon := Label.new()
	s_icon.text = "🛡"; s_icon.add_theme_font_size_override("font_size", 12)
	s_icon.add_theme_color_override("font_color", Color(0.40, 0.85, 1.00))
	s_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	s_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_row.add_child(s_icon)

	_shield_bar = ProgressBar.new()
	_shield_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shield_bar.min_value = 0.0; _shield_bar.max_value = 50.0; _shield_bar.value = 50.0
	_shield_bar.show_percentage = false; _shield_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_bg := StyleBoxFlat.new(); sb_bg.bg_color = Color(0.04, 0.14, 0.24); sb_bg.set_corner_radius_all(3)
	var sb_fill := StyleBoxFlat.new(); sb_fill.bg_color = Color(0.28, 0.78, 1.00); sb_fill.set_corner_radius_all(3)
	_shield_bar.add_theme_stylebox_override("background", sb_bg)
	_shield_bar.add_theme_stylebox_override("fill", sb_fill)
	_shield_row.add_child(_shield_bar)

	# ── Divider ───────────────────────────────────────────────────────────────
	var div := ColorRect.new()
	div.color = Color(0.00, 0.60, 0.90, 0.45)
	div.anchor_left = 0.0; div.anchor_right  = 0.0
	div.anchor_top  = 0.0; div.anchor_bottom = 1.0
	div.offset_left = DIV_X; div.offset_right = DIV_X + 2.0
	div.offset_top  = 6.0;   div.offset_bottom = -6.0
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(div)

	# ── RIGHT ZONE — coin icon + value, distance icon + value ────────────────
	# Coin icon
	var coin_icon := Label.new()
	coin_icon.text = "◆"
	coin_icon.add_theme_color_override("font_color", C_GOLD)
	coin_icon.add_theme_font_size_override("font_size", 20)
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_icon.anchor_left = 0.0; coin_icon.anchor_right  = 0.0
	coin_icon.anchor_top  = 0.0; coin_icon.anchor_bottom = 0.0
	coin_icon.offset_left = DIV_X + 8.0; coin_icon.offset_top    = 6.0
	coin_icon.offset_right = DIV_X + 34.0; coin_icon.offset_bottom = 44.0
	top_bar.add_child(coin_icon)

	# Coin value (the @onready label, now a free child of top_bar)
	coin_label.text = "◆ 0"
	coin_label.anchor_left = 0.0; coin_label.anchor_right  = 1.0
	coin_label.anchor_top  = 0.0; coin_label.anchor_bottom = 0.0
	coin_label.offset_left   = DIV_X + 36.0; coin_label.offset_right  = -PAD
	coin_label.offset_top    = 4.0;           coin_label.offset_bottom = 46.0
	coin_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Remove the ◆ prefix from update_coins — label now shows only the number
	coin_label.add_theme_color_override("font_color", C_GOLD)
	coin_label.add_theme_font_size_override("font_size", 22)

	# Distance icon (compressed to make room for BEST row)
	var dist_icon := Label.new()
	dist_icon.text = "↑"
	dist_icon.add_theme_color_override("font_color", Color(0.30, 1.00, 0.78))
	dist_icon.add_theme_font_size_override("font_size", 17)
	dist_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dist_icon.anchor_left = 0.0; dist_icon.anchor_right  = 0.0
	dist_icon.anchor_top  = 0.0; dist_icon.anchor_bottom = 0.0
	dist_icon.offset_left  = DIV_X + 8.0; dist_icon.offset_top    = 48.0
	dist_icon.offset_right = DIV_X + 34.0; dist_icon.offset_bottom = 68.0
	top_bar.add_child(dist_icon)

	# Distance value (current run)
	distance_label.text = "0 m"
	distance_label.anchor_left = 0.0; distance_label.anchor_right  = 1.0
	distance_label.anchor_top  = 0.0; distance_label.anchor_bottom = 0.0
	distance_label.offset_left   = DIV_X + 36.0; distance_label.offset_right  = -PAD
	distance_label.offset_top    = 46.0;          distance_label.offset_bottom = 68.0
	distance_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	distance_label.add_theme_color_override("font_color", Color(0.30, 1.00, 0.78))
	distance_label.add_theme_font_size_override("font_size", 18)

	# Best distance row
	_best_dist_label = Label.new()
	_best_dist_label.text = Locale.t("best_none")
	_best_dist_label.anchor_left = 0.0; _best_dist_label.anchor_right  = 0.0
	_best_dist_label.anchor_top  = 0.0; _best_dist_label.anchor_bottom = 0.0
	_best_dist_label.offset_left   = DIV_X + 8.0; _best_dist_label.offset_right  = -PAD
	_best_dist_label.offset_top    = 70.0;          _best_dist_label.offset_bottom = 90.0
	_best_dist_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_best_dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_best_dist_label.add_theme_color_override("font_color", Color(0.18, 0.65, 0.52, 0.82))
	_best_dist_label.add_theme_font_size_override("font_size", 12)
	_best_dist_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(_best_dist_label)

# ─── Shield HUD update ────────────────────────────────────────────────────────
func flash_parry() -> void:
	_parry_flash_alpha = 0.85

# Show a brief in-game event notification (heals, perks triggering, etc.)
# Uses the same perk_notif label but shorter duration + custom color/size.
func show_event_notif(text: String, col: Color = Color(1.0, 0.9, 0.18), size: int = 22) -> void:
	perk_notif.text = text
	perk_notif.add_theme_color_override("font_color", col)
	perk_notif.add_theme_font_size_override("font_size", size)
	perk_notif.visible = true
	perk_notif.modulate.a = 1.0
	notif_timer = 1.5

func update_best_distance(best: float) -> void:
	if not _best_dist_label:
		return
	if best > 0.0:
		_best_dist_label.text = Locale.t("best_value") % best
	else:
		_best_dist_label.text = Locale.t("best_none")

func update_shield(shield: float, max_shield: float) -> void:
	if not _shield_bar or not _shield_row:
		return
	_shield_bar.max_value = max_shield
	_shield_bar.value     = shield
	_shield_row.visible   = shield > 0.0
