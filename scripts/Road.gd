extends Node2D

var scroll_offset: float = 0.0
var env_index: int = 0
var speed_ref: float = 300.0   # set by Main each frame for speed-streak intensity

const ROAD_LEFT:    float = 80.0
const ROAD_RIGHT:   float = 400.0
const ROAD_W:       float = 320.0
const SCREEN_H:     float = 854.0
const LINE_SPACING: float = 120.0
const LINE_H:       float = 60.0

# 10 environment color themes — one per 1500 m zone
const ENVS: Array = [
    # 0  City Highway
    {"road": Color(0.18,0.18,0.20), "bg":   Color(0.08,0.08,0.10),
     "curb": Color(0.80,0.80,0.10), "walk": Color(0.25,0.22,0.20),
     "dash": Color(0.90,0.90,0.90,0.60),
     "dl":   Color(0.00,0.60,1.00,0.50), "dr": Color(1.00,0.10,0.50,0.50)},
    # 1  Desert Road
    {"road": Color(0.30,0.24,0.16), "bg":   Color(0.42,0.32,0.18),
     "curb": Color(0.90,0.70,0.20), "walk": Color(0.48,0.36,0.20),
     "dash": Color(0.95,0.85,0.60,0.70),
     "dl":   Color(1.00,0.60,0.10,0.50), "dr": Color(0.90,0.50,0.00,0.50)},
    # 2  Night City
    {"road": Color(0.07,0.07,0.11), "bg":   Color(0.03,0.03,0.07),
     "curb": Color(0.10,0.20,1.00), "walk": Color(0.10,0.08,0.16),
     "dash": Color(0.00,1.00,0.90,0.80),
     "dl":   Color(0.50,0.00,1.00,0.60), "dr": Color(0.00,0.90,1.00,0.60)},
    # 3  Ice Road
    {"road": Color(0.60,0.72,0.82), "bg":   Color(0.75,0.85,0.92),
     "curb": Color(0.88,0.94,1.00), "walk": Color(0.50,0.60,0.72),
     "dash": Color(1.00,1.00,1.00,0.90),
     "dl":   Color(0.50,0.80,1.00,0.50), "dr": Color(0.60,0.90,1.00,0.50)},
    # 4  Volcano Pass
    {"road": Color(0.14,0.07,0.05), "bg":   Color(0.10,0.04,0.02),
     "curb": Color(0.90,0.35,0.00), "walk": Color(0.22,0.10,0.05),
     "dash": Color(1.00,0.55,0.00,0.70),
     "dl":   Color(1.00,0.20,0.00,0.60), "dr": Color(0.90,0.40,0.00,0.60)},
    # 5  Forest Track
    {"road": Color(0.10,0.14,0.08), "bg":   Color(0.05,0.10,0.04),
     "curb": Color(0.25,0.55,0.08), "walk": Color(0.14,0.20,0.08),
     "dash": Color(0.50,0.85,0.30,0.70),
     "dl":   Color(0.10,0.70,0.10,0.50), "dr": Color(0.20,0.80,0.10,0.50)},
    # 6  Industrial Zone
    {"road": Color(0.28,0.26,0.24), "bg":   Color(0.16,0.15,0.14),
     "curb": Color(1.00,0.80,0.00), "walk": Color(0.24,0.22,0.20),
     "dash": Color(1.00,0.85,0.00,0.80),
     "dl":   Color(1.00,0.70,0.00,0.50), "dr": Color(0.90,0.60,0.00,0.50)},
    # 7  Coastal Road
    {"road": Color(0.14,0.18,0.24), "bg":   Color(0.06,0.10,0.18),
     "curb": Color(0.15,0.70,0.85), "walk": Color(0.18,0.24,0.32),
     "dash": Color(0.80,0.95,1.00,0.70),
     "dl":   Color(0.00,0.70,0.90,0.50), "dr": Color(0.10,0.80,0.80,0.50)},
    # 8  Underground Tunnel
    {"road": Color(0.08,0.05,0.12), "bg":   Color(0.04,0.02,0.08),
     "curb": Color(0.55,0.08,0.88), "walk": Color(0.12,0.06,0.18),
     "dash": Color(0.70,0.20,1.00,0.70),
     "dl":   Color(0.60,0.00,0.90,0.60), "dr": Color(0.50,0.00,0.80,0.60)},
    # 9  Space Highway
    {"road": Color(0.05,0.04,0.10), "bg":   Color(0.02,0.02,0.06),
     "curb": Color(0.35,0.75,1.00), "walk": Color(0.08,0.06,0.14),
     "dash": Color(0.60,0.85,1.00,0.80),
     "dl":   Color(0.20,0.60,1.00,0.60), "dr": Color(0.40,0.80,1.00,0.60)},
    # 10 Neon Wasteland
    {"road": Color(0.15,0.13,0.18), "bg":   Color(0.07,0.04,0.12),
     "curb": Color(1.00,0.10,0.80), "walk": Color(0.12,0.08,0.16),
     "dash": Color(1.00,0.00,0.90,0.80),
     "dl":   Color(0.90,0.00,0.70,0.60), "dr": Color(1.00,0.20,0.90,0.60)},
    # 11 Crimson Badlands
    {"road": Color(0.16,0.06,0.06), "bg":   Color(0.10,0.03,0.03),
     "curb": Color(0.95,0.30,0.05), "walk": Color(0.20,0.08,0.06),
     "dash": Color(1.00,0.50,0.20,0.70),
     "dl":   Color(1.00,0.15,0.05,0.60), "dr": Color(0.85,0.10,0.00,0.60)},
    # 12 Crystal Caverns
    {"road": Color(0.62,0.78,0.88), "bg":   Color(0.75,0.90,0.98),
     "curb": Color(0.92,0.98,1.00), "walk": Color(0.52,0.68,0.80),
     "dash": Color(1.00,1.00,1.00,0.90),
     "dl":   Color(0.60,0.90,1.00,0.60), "dr": Color(0.70,0.95,1.00,0.60)},
    # 13 Toxic Swamp
    {"road": Color(0.08,0.12,0.06), "bg":   Color(0.04,0.09,0.03),
     "curb": Color(0.60,0.95,0.10), "walk": Color(0.12,0.18,0.06),
     "dash": Color(0.70,1.00,0.20,0.75),
     "dl":   Color(0.30,0.90,0.10,0.55), "dr": Color(0.40,0.95,0.15,0.55)},
    # 14 Arctic Tundra
    {"road": Color(0.78,0.84,0.90), "bg":   Color(0.88,0.92,0.96),
     "curb": Color(0.70,0.88,1.00), "walk": Color(0.65,0.72,0.80),
     "dash": Color(1.00,1.00,1.00,0.95),
     "dl":   Color(0.55,0.80,1.00,0.55), "dr": Color(0.65,0.90,1.00,0.55)},
    # 15 Storm Corridor
    {"road": Color(0.18,0.20,0.26), "bg":   Color(0.10,0.12,0.18),
     "curb": Color(0.80,0.85,1.00), "walk": Color(0.14,0.16,0.22),
     "dash": Color(0.85,0.90,1.00,0.80),
     "dl":   Color(0.70,0.80,1.00,0.60), "dr": Color(0.60,0.70,1.00,0.60)},
    # 16 Cyberpunk Slums
    {"road": Color(0.06,0.07,0.09), "bg":   Color(0.03,0.04,0.06),
     "curb": Color(0.00,0.95,0.55), "walk": Color(0.08,0.09,0.12),
     "dash": Color(0.00,1.00,0.60,0.80),
     "dl":   Color(0.00,0.90,0.50,0.60), "dr": Color(0.10,0.95,0.60,0.60)},
    # 17 Lava Fields
    {"road": Color(0.12,0.06,0.04), "bg":   Color(0.16,0.05,0.02),
     "curb": Color(1.00,0.45,0.00), "walk": Color(0.20,0.08,0.03),
     "dash": Color(1.00,0.60,0.10,0.75),
     "dl":   Color(1.00,0.30,0.00,0.65), "dr": Color(0.95,0.25,0.00,0.65)},
    # 18 Sky Bridge
    {"road": Color(0.55,0.70,0.88), "bg":   Color(0.55,0.75,0.98),
     "curb": Color(0.95,0.98,1.00), "walk": Color(0.45,0.60,0.80),
     "dash": Color(1.00,1.00,1.00,0.85),
     "dl":   Color(0.50,0.80,1.00,0.55), "dr": Color(0.60,0.85,1.00,0.55)},
    # 19 Haunted Highway
    {"road": Color(0.09,0.11,0.09), "bg":   Color(0.05,0.08,0.05),
     "curb": Color(0.28,0.82,0.40), "walk": Color(0.10,0.14,0.10),
     "dash": Color(0.40,0.90,0.50,0.70),
     "dl":   Color(0.20,0.75,0.30,0.55), "dr": Color(0.25,0.80,0.35,0.55)},
    # 20 Blood Moon Pass
    {"road": Color(0.12,0.04,0.04), "bg":   Color(0.20,0.04,0.03),
     "curb": Color(0.90,0.05,0.08), "walk": Color(0.16,0.05,0.04),
     "dash": Color(1.00,0.35,0.20,0.75),
     "dl":   Color(0.90,0.08,0.05,0.65), "dr": Color(0.85,0.05,0.03,0.65)},
    # 21 Quantum Grid
    {"road": Color(0.06,0.04,0.12), "bg":   Color(0.03,0.02,0.08),
     "curb": Color(0.65,0.20,1.00), "walk": Color(0.08,0.05,0.16),
     "dash": Color(0.75,0.25,1.00,0.80),
     "dl":   Color(0.55,0.10,0.95,0.65), "dr": Color(0.65,0.15,1.00,0.65)},
    # 22 Shadow Realm
    {"road": Color(0.04,0.02,0.06), "bg":   Color(0.02,0.01,0.04),
     "curb": Color(0.28,0.05,0.45), "walk": Color(0.06,0.03,0.09),
     "dash": Color(0.40,0.08,0.60,0.70),
     "dl":   Color(0.25,0.02,0.40,0.60), "dr": Color(0.22,0.02,0.35,0.60)},
    # 23 Chrome City
    {"road": Color(0.58,0.60,0.64), "bg":   Color(0.72,0.74,0.78),
     "curb": Color(0.92,0.94,0.98), "walk": Color(0.48,0.50,0.55),
     "dash": Color(1.00,1.00,1.00,0.90),
     "dl":   Color(0.85,0.88,0.95,0.60), "dr": Color(0.88,0.90,0.95,0.60)},
    # 24 Void Corridor
    {"road": Color(0.02,0.01,0.03), "bg":   Color(0.00,0.00,0.02),
     "curb": Color(0.25,0.25,0.35), "walk": Color(0.04,0.02,0.06),
     "dash": Color(0.40,0.40,0.55,0.60),
     "dl":   Color(0.20,0.20,0.30,0.50), "dr": Color(0.18,0.18,0.28,0.50)},
]

func set_environment(index: int) -> void:
    env_index = index % ENVS.size()
    queue_redraw()

func _draw() -> void:
    var e: Dictionary = ENVS[env_index]
    var h: float = get_viewport_rect().size.y

    # Off-road background — fills full viewport height
    draw_rect(Rect2(0, 0, 480, h), e["bg"])

    # Sidewalks
    draw_rect(Rect2(0,              0, ROAD_LEFT - 8,         h), e["walk"])
    draw_rect(Rect2(ROAD_RIGHT + 8, 0, 480 - ROAD_RIGHT - 8, h), e["walk"])

    # Road surface
    draw_rect(Rect2(ROAD_LEFT, 0, ROAD_W, h), e["road"])

    # Curb lines
    draw_rect(Rect2(ROAD_LEFT - 8, 0, 8, h), e["curb"])
    draw_rect(Rect2(ROAD_RIGHT,    0, 8, h), e["curb"])

    # Scrolling lane dashes
    for lane_div in [185.0, 295.0]:
        var y: float = fmod(scroll_offset, LINE_SPACING) - LINE_SPACING
        while y < h:
            draw_rect(Rect2(lane_div - 2, y, 4, LINE_H), e["dash"])
            y += LINE_SPACING

    # Side decoration strips (scroll at 40% speed)
    for i in range(0, int(h / 80) + 2):
        var y: float = fmod(scroll_offset * 0.4, 80.0) + i * 80.0 - 80.0
        draw_rect(Rect2(2,   y, 6, 30), e["dl"])
        draw_rect(Rect2(472, y, 6, 30), e["dr"])

    # ── Speed streaks — thin vertical lines that intensify at high speed ────
    var streak_a: float = clamp((speed_ref - 300.0) / 600.0, 0.0, 1.0) * 0.22
    if streak_a > 0.005:
        # Streaks scroll at 2× road speed for strong motion-blur feel
        var fast_scroll: float = fmod(scroll_offset * 2.0, 65.0)
        for sx in [112.0, 148.0, 185.0, 225.0, 265.0, 305.0, 345.0, 382.0]:
            var oy: float = fast_scroll - 65.0
            while oy < h:
                draw_line(Vector2(sx, oy), Vector2(sx, oy + 42.0),
                    Color(1.0, 1.0, 1.0, streak_a), 1.0)
                oy += 65.0
