# SpriteRegistry.gd  — registered as an Autoload in project.godot
# ─────────────────────────────────────────────────────────────────────────────
# Loads (or auto-creates) entity_sprites.tres and exposes helper methods
# so Player, enemies, and bosses can look up their textures by name/index.
#
# The .tres file is created on first run (editor only — res:// is read-only
# on mobile, which is fine because the file is committed to the project).
# ─────────────────────────────────────────────────────────────────────────────
extends Node

const _RES_PATH := "res://resources/entity_sprites.tres"
var config: EntitySpriteConfig = null

func _ready() -> void:
	_load_or_create()

func _load_or_create() -> void:
	if ResourceLoader.exists(_RES_PATH):
		config = load(_RES_PATH) as EntitySpriteConfig
	if config == null:
		config = EntitySpriteConfig.new()
		# Attempt to persist so the user can edit slots in the Inspector.
		# Fails gracefully on mobile / read-only exports.
		var dir := DirAccess.open("res://")
		if dir:
			if not dir.dir_exists("resources"):
				dir.make_dir("resources")
			if not dir.dir_exists("assets/sprites"):
				dir.make_dir_recursive("assets/sprites")
		var err := ResourceSaver.save(config, _RES_PATH)
		if err != OK:
			push_warning("SpriteRegistry: could not save %s (expected on device/export). Sprites disabled this session." % _RES_PATH)

# ── Lookup helpers ────────────────────────────────────────────────────────────

# Loads a texture from a res:// path.
# Tries the Godot import system first; falls back to raw Image load
# (so files dropped into the folder mid-session work without re-importing).
func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		return load(res_path) as Texture2D
	# Raw fallback — works even before Godot imports the file
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.new()
		if img.load(abs_path) == OK:
			return ImageTexture.create_from_image(img)
	return null

func get_skin_texture(skin_key: String) -> Texture2D:
	if config == null: return null
	var tex: Texture2D = null
	match skin_key:
		"default":     tex = config.skin_default
		"crimson":     tex = config.skin_crimson
		"inferno":     tex = config.skin_inferno
		"stealth":     tex = config.skin_stealth
		"forest":      tex = config.skin_forest
		"neon":        tex = config.skin_neon
		"ice":         tex = config.skin_ice
		"rose":        tex = config.skin_rose
		"gold":        tex = config.skin_gold
		"toxic":       tex = config.skin_toxic
		"chrome":      tex = config.skin_chrome
		"obsidian":    tex = config.skin_obsidian
		"void":        tex = config.skin_void
		"coral":       tex = config.skin_coral
		"ultraviolet": tex = config.skin_ultraviolet
	# Auto-fallback: if no texture assigned in Inspector, try
	# res://assets/sprites/player_{skin_key}.png
	if tex == null:
		var auto_path := "res://assets/sprites/player_%s.png" % skin_key
		tex = _load_tex(auto_path)
	return tex

func get_enemy_texture(enemy_type: String) -> Texture2D:
	if config == null: return null
	var tex: Texture2D = null
	match enemy_type:
		"grunt":    tex = config.enemy_grunt
		"speeder":  tex = config.enemy_speeder
		"kamikaze": tex = config.enemy_kamikaze
		"shooter":  tex = config.enemy_shooter
		"tank":     tex = config.enemy_tank
	if tex == null:
		var auto_path := "res://assets/sprites/enemy_%s.png" % enemy_type
		tex = _load_tex(auto_path)
	return tex

func get_boss_texture(boss_num: int) -> Texture2D:
	if config == null: return null
	var shape := (boss_num - 1) % 5
	var tex: Texture2D = null
	match shape:
		0: tex = config.boss_shape_0
		1: tex = config.boss_shape_1
		2: tex = config.boss_shape_2
		3: tex = config.boss_shape_3
		_: tex = config.boss_shape_4
	if tex == null:
		var auto_path := "res://assets/sprites/boss_shape_%d.png" % shape
		tex = _load_tex(auto_path)
	return tex

func get_scale(entity: String) -> float:
	if config == null: return 0.025
	match entity:
		"player":  return config.scale_player
		"enemy":   return config.scale_enemy
		"tank":    return config.scale_tank
		"boss":    return config.scale_boss
	return 0.025
