# EntitySpriteConfig.gd
# ─────────────────────────────────────────────────────────────────────────────
# HOW TO USE (no code required):
#   1. Open Godot → FileSystem panel
#   2. Double-click  res://resources/entity_sprites.tres
#   3. The Inspector shows every sprite slot grouped by category
#   4. Drag a Texture2D from FileSystem into any slot to assign it
#
# Drop your sprites into  res://assets/sprites/  first, then assign here.
# ─────────────────────────────────────────────────────────────────────────────
class_name EntitySpriteConfig
extends Resource

# ── Player skins (one slot per skin key in GameState.SKINS) ──────────────────
@export_group("Player Skins")
@export var skin_default:     Texture2D  ## STEEL BLUE  (free starter skin)
@export var skin_crimson:     Texture2D  ## CRIMSON
@export var skin_inferno:     Texture2D  ## INFERNO
@export var skin_stealth:     Texture2D  ## STEALTH
@export var skin_forest:      Texture2D  ## FOREST GHOST
@export var skin_neon:        Texture2D  ## NEON PHANTOM
@export var skin_ice:         Texture2D  ## ICE BLADE
@export var skin_rose:        Texture2D  ## ROSE
@export var skin_gold:        Texture2D  ## GOLD RUSH
@export var skin_toxic:       Texture2D  ## TOXIC
@export var skin_chrome:      Texture2D  ## CHROME
@export var skin_obsidian:    Texture2D  ## OBSIDIAN
@export var skin_void:        Texture2D  ## VOID WALKER
@export var skin_coral:       Texture2D  ## CORAL
@export var skin_ultraviolet: Texture2D  ## ULTRAVIOLET

# ── Enemy sprites ─────────────────────────────────────────────────────────────
@export_group("Enemies")
@export var enemy_grunt:    Texture2D
@export var enemy_speeder:  Texture2D
@export var enemy_kamikaze: Texture2D
@export var enemy_shooter:  Texture2D
@export var enemy_tank:     Texture2D

# ── Boss shapes (5 archetypes, cycling every 5 boss fights) ──────────────────
@export_group("Bosses")
@export var boss_shape_0: Texture2D  ## Shape 0 — Armored Behemoth   (bosses 1,6,11,16,21…)
@export var boss_shape_1: Texture2D  ## Shape 1 — Velocity Racer     (bosses 2,7,12,17,22…)
@export var boss_shape_2: Texture2D  ## Shape 2 — Hex Sentinel        (bosses 3,8,13,18,23…)
@export var boss_shape_3: Texture2D  ## Shape 3 — Iron Juggernaut     (bosses 4,9,14,19,24…)
@export var boss_shape_4: Texture2D  ## Shape 4 — Phantom Wraith      (bosses 5,10,15,20,25…)

# ── Scale overrides ──────────────────────────────────────────────────────────
# All Gemini sprites use canvas 2600×1418 px, vehicle facing RIGHT.
# They are auto-rotated –90° so the car faces up in the game.
# After rotation: image HEIGHT (1418 px) → screen width.
# Vehicle occupies ~35% of canvas height → ~496 px of image.
# Formula:  scale = desired_screen_width_px ÷ 496
#   e.g.  36 px wide in-game  →  36 ÷ 496 ≈ 0.073
#         30 px wide in-game  →  30 ÷ 496 ≈ 0.060
#         55 px wide in-game  →  55 ÷ 496 ≈ 0.111
@export_group("Scale Overrides")
@export var scale_player: float = 0.073   ## Player car  — targets ~36 px screen width
@export var scale_enemy:  float = 0.060   ## Regular enemy — targets ~30 px screen width
@export var scale_tank:   float = 0.077   ## Tank enemy  — targets ~38 px screen width
@export var scale_boss:   float = 0.111   ## Boss        — targets ~55 px screen width

# ── Ads / Monetization ────────────────────────────────────────────────────────
# Ad IDs are now configured directly in AdiveryManager.gd (the autoload).
# Open res://scripts/AdiveryManager.gd and set adivery_app_id and rewarded_zone_id.
