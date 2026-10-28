extends CanvasLayer

# perk_chosen(new_perk, dropped_perk)  — dropped_perk is "" when slot was free
signal perk_chosen(new_perk: String, dropped_perk: String)

const MAX_PERK_SLOTS: int = 3

const ALL_PERKS: Array = [
	# ── Original 9 ──────────────────────────────────────────────────────────────
	{"name": "Ricochet Shots",   "desc": "Bullets bounce to a nearby enemy"},
	{"name": "Chain Explosion",  "desc": "Enemies explode on death, damaging nearby foes"},
	{"name": "Lifesteal",        "desc": "Bullets heal you for 5% of damage dealt"},
	{"name": "Double Coins",     "desc": "All coin pickups are doubled"},
	{"name": "Shield Bubble",    "desc": "Generate a recharging energy shield"},
	{"name": "Afterburner",      "desc": "Boost 20% faster, lasts 40% longer"},
	{"name": "Rapid Fire",       "desc": "Fire rate +25%"},
	{"name": "Magnet Aura",      "desc": "Coins are pulled toward you"},
	{"name": "Ram Fury",         "desc": "Boost-ramming deals major damage (+50% bonus)"},
	# ── New 15 ──────────────────────────────────────────────────────────────────
	{"name": "Homing Shots",     "desc": "Bullets steer toward the nearest enemy"},
	{"name": "Explosive Rounds", "desc": "Bullets detonate on impact, damaging nearby foes"},
	{"name": "Piercing Shot",    "desc": "Bullets pierce through one extra enemy"},
	{"name": "Overload",         "desc": "Every 10th bullet deals triple damage"},
	{"name": "Twin Barrels",     "desc": "Fire two center bullets per burst"},
	{"name": "Adrenaline",       "desc": "Below 25% HP, deal double damage"},
	{"name": "Iron Skin",        "desc": "Take 20% less damage from all sources"},
	{"name": "Nano Repair",      "desc": "Regenerate 2 HP every 3 seconds"},
	{"name": "Battle Hardened",  "desc": "Maximum HP increased by 40"},
	{"name": "Scavenger",        "desc": "Coin pickups restore 1 HP"},
	{"name": "Turbo Engine",     "desc": "Boost recharge time reduced by 35%"},
	{"name": "Lucky Strike",     "desc": "20% chance each kill instantly resets boost"},
	{"name": "Coin Rush",        "desc": "Every kill drops 2 guaranteed extra coins"},
	{"name": "Nemesis",          "desc": "Deal 50% more damage to bosses"},
	{"name": "Executioner",      "desc": "Bosses drop triple coins on defeat"},
]

var offered_perks: Array = []
var phase: int = 1          # 1 = pick new perk,  2 = drop existing perk
var chosen_new_perk: String = ""
var _slot_vis: Array = []   # [{panel, label}, ...]

@onready var panel: Panel           = $Panel
@onready var title_label: Label     = $Panel/VBox/TitleLabel
@onready var slot_bar: Label        = $Panel/VBox/SlotBar
@onready var sub_label: Label       = $Panel/VBox/SubLabel
@onready var perk_buttons: VBoxContainer = $Panel/VBox/PerkButtons
@onready var btn1: Button           = $Panel/VBox/PerkButtons/Btn1
@onready var btn2: Button           = $Panel/VBox/PerkButtons/Btn2
@onready var btn3: Button           = $Panel/VBox/PerkButtons/Btn3
@onready var desc1: Label           = $Panel/VBox/PerkButtons/Desc1
@onready var desc2: Label           = $Panel/VBox/PerkButtons/Desc2
@onready var desc3: Label           = $Panel/VBox/PerkButtons/Desc3
@onready var drop_section: VBoxContainer = $Panel/VBox/DropSection
@onready var drop_label: Label      = $Panel/VBox/DropSection/DropLabel
@onready var drop_btn1: Button      = $Panel/VBox/DropSection/DropBtns/DropBtn1
@onready var drop_btn2: Button      = $Panel/VBox/DropSection/DropBtns/DropBtn2
@onready var drop_btn3: Button      = $Panel/VBox/DropSection/DropBtns/DropBtn3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	_pick_perks()
	_apply_styles()      # must run first — builds _slot_vis
	_update_slot_bar()   # now _slot_vis is populated, slots render correctly

	btn1.pressed.connect(_on_perk_chosen.bind(0))
	btn2.pressed.connect(_on_perk_chosen.bind(1))
	btn3.pressed.connect(_on_perk_chosen.bind(2))
	drop_btn1.pressed.connect(_on_drop_chosen.bind(0))
	drop_btn2.pressed.connect(_on_drop_chosen.bind(1))
	drop_btn3.pressed.connect(_on_drop_chosen.bind(2))
	# Click SFX on every choice button
	for b in [btn1, btn2, btn3, drop_btn1, drop_btn2, drop_btn3]:
		b.pressed.connect(SFX.play_click)

# ── Phase 1 : pick new perk ───────────────────────────────────────────────────
func _pick_perks() -> void:
	var pool = ALL_PERKS.filter(
		func(p): return not GameState.has_perk(p["name"]) or p["name"] == "Double Coins")
	pool.shuffle()
	offered_perks = pool.slice(0, 3)
	while offered_perks.size() < 3:
		offered_perks.append(ALL_PERKS[randi() % ALL_PERKS.size()])

	btn1.text = offered_perks[0]["name"];  desc1.text = offered_perks[0]["desc"]
	btn2.text = offered_perks[1]["name"];  desc2.text = offered_perks[1]["desc"]
	btn3.text = offered_perks[2]["name"];  desc3.text = offered_perks[2]["desc"]

func _on_perk_chosen(index: int) -> void:
	var chosen = offered_perks[index]["name"]
	if GameState.current_perks.size() < MAX_PERK_SLOTS:
		# Slot available — add immediately
		_finish(chosen, "")
	else:
		# All slots full — enter replace phase
		chosen_new_perk = chosen
		phase = 2
		_show_drop_phase()

# ── Phase 2 : drop existing perk ─────────────────────────────────────────────
func _show_drop_phase() -> void:
	title_label.text = Locale.t("perk_replace_title")
	sub_label.text   = Locale.t("perk_adding_prefix") + chosen_new_perk
	perk_buttons.visible = false
	drop_section.visible = true

	var perks      = GameState.current_perks
	var drop_btns  = [drop_btn1, drop_btn2, drop_btn3]
	for i in 3:
		if i < perks.size():
			drop_btns[i].text    = perks[i]
			drop_btns[i].visible = true
			_style_drop_button(drop_btns[i])
		else:
			drop_btns[i].visible = false

	drop_label.add_theme_color_override("font_color", Color(1.00, 0.30, 0.10))
	drop_label.add_theme_font_size_override("font_size", 20)

func _on_drop_chosen(index: int) -> void:
	var dropped = GameState.current_perks[index]
	_finish(chosen_new_perk, dropped)

# ── Shared finish ─────────────────────────────────────────────────────────────
func _finish(new_perk: String, dropped: String) -> void:
	SFX.play_perk()
	get_tree().paused = false
	emit_signal("perk_chosen", new_perk, dropped)
	queue_free()

# ── Slot visual ───────────────────────────────────────────────────────────────
func _build_slot_vis() -> void:
	slot_bar.visible = false   # hide old text label

	var vbox = slot_bar.get_parent()
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 44)
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)
	vbox.move_child(hbox, slot_bar.get_index())

	_slot_vis = []
	for _i in MAX_PERK_SLOTS:
		var sp := Panel.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(sp)
		var lbl := Label.new()
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.offset_left  = 4; lbl.offset_right  = -4
		lbl.offset_top   = 2; lbl.offset_bottom = -2
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		sp.add_child(lbl)
		_slot_vis.append({"panel": sp, "label": lbl})

func _update_slot_bar() -> void:
	if _slot_vis.is_empty():
		return
	var perks = GameState.current_perks
	for i in MAX_PERK_SLOTS:
		var d   = _slot_vis[i]
		var sp: Panel  = d["panel"]
		var lbl: Label = d["label"]
		if i < perks.size():
			sp.add_theme_stylebox_override("panel",
				_flat(Color(0.02, 0.14, 0.24), Color(0.00, 0.80, 1.00), 7))
			lbl.text = perks[i]
			lbl.add_theme_color_override("font_color", Color(0.80, 0.97, 1.00))
		else:
			sp.add_theme_stylebox_override("panel",
				_flat(Color(0.02, 0.06, 0.12), Color(0.06, 0.28, 0.42), 7))
			lbl.text = Locale.t("perk_slot_open")
			lbl.add_theme_color_override("font_color", Color(0.20, 0.42, 0.55))

# ─── Styling ──────────────────────────────────────────────────────────────────
func _apply_styles() -> void:
	_build_slot_vis()   # must run before slot_bar styling so the hbox is ready

	# Panel — deep navy with neon cyan border
	var ps = StyleBoxFlat.new()
	ps.bg_color    = Color(0.02, 0.05, 0.12, 0.97)
	ps.border_color = Color(0.00, 0.80, 1.00, 1.0)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", ps)

	# Title — neon cyan
	title_label.add_theme_color_override("font_color",    Color(0.00, 0.90, 1.00))
	title_label.add_theme_font_size_override("font_size", 28)

	# Slot bar
	slot_bar.add_theme_color_override("font_color", Color(0.38, 0.72, 0.88))
	slot_bar.add_theme_font_size_override("font_size", 13)

	# Sub label — ice white-blue
	sub_label.add_theme_color_override("font_color",    Color(0.78, 0.94, 1.00))
	sub_label.add_theme_font_size_override("font_size", 13)

	# Desc labels — teal muted
	for d in [desc1, desc2, desc3]:
		d.add_theme_color_override("font_color",    Color(0.42, 0.72, 0.82))
		d.add_theme_font_size_override("font_size", 12)

	# Perk choice buttons
	for btn in [btn1, btn2, btn3]:
		_style_perk_button(btn)

func _style_perk_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal",  _flat(Color(0.02, 0.10, 0.20), Color(0.00, 0.55, 0.82)))
	btn.add_theme_stylebox_override("hover",   _flat(Color(0.02, 0.18, 0.30), Color(0.00, 0.88, 1.00)))
	btn.add_theme_stylebox_override("pressed", _flat(Color(0.02, 0.12, 0.22), Color(0.00, 1.00, 1.00)))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0.02, 0.10, 0.20), Color(0.00, 0.55, 0.82)))
	btn.add_theme_color_override("font_color",         Color(0.82, 0.96, 1.00))
	btn.add_theme_color_override("font_hover_color",   Color(1.00, 1.00, 1.00))
	btn.add_theme_color_override("font_pressed_color", Color(0.70, 0.92, 1.00))
	btn.add_theme_font_size_override("font_size", 18)

func _style_drop_button(btn: Button) -> void:
	# Red-tinted: "danger" — you're discarding this perk
	btn.add_theme_stylebox_override("normal",  _flat(Color(0.18, 0.04, 0.04), Color(0.70, 0.12, 0.12)))
	btn.add_theme_stylebox_override("hover",   _flat(Color(0.30, 0.06, 0.06), Color(0.90, 0.18, 0.18)))
	btn.add_theme_stylebox_override("pressed", _flat(Color(0.22, 0.04, 0.04), Color(0.95, 0.25, 0.25)))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0.18, 0.04, 0.04), Color(0.70, 0.12, 0.12)))
	btn.add_theme_color_override("font_color",         Color(1.00, 0.70, 0.70))
	btn.add_theme_color_override("font_hover_color",   Color(1.00, 0.85, 0.85))
	btn.add_theme_color_override("font_pressed_color", Color(0.90, 0.60, 0.60))
	btn.add_theme_font_size_override("font_size", 17)

func _flat(bg: Color, border: Color, r: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(r)
	return s
