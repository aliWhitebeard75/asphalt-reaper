extends Node2D

signal collected(value)

var value: int = 1
var fall_speed: float = 80.0
var collected_flag: bool = false
var _spin: float = 0.0   # drives 3D-rotation illusion and shine angle

func _process(delta: float) -> void:
	_spin += delta * 4.5
	position.y += fall_speed * delta
	queue_redraw()

	# Check collection by player
	var main = get_parent().get_parent() if get_parent() else null
	if main:
		var player = main.get_node_or_null("Player")
		if player and is_instance_valid(player) and not collected_flag:
			if position.distance_to(player.position) < 32.0:
				_collect()

func _collect() -> void:
	if collected_flag:
		return
	collected_flag = true
	emit_signal("collected", value)
	queue_free()

func _draw() -> void:
	# Outer glow
	draw_circle(Vector2.ZERO, 13.5, Color(1.0, 0.84, 0.0, 0.22))
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.90, 0.15, 0.15))

	# 3D spin illusion: x-radius oscillates between 8 and 0.5 (looks like it's flipping)
	var coin_rx: float = abs(cos(_spin)) * 7.5 + 0.5
	var facing_front: bool = cos(_spin) >= 0.0
	var face_col := Color(1.0, 0.88, 0.10) if facing_front else Color(0.80, 0.65, 0.05)
	var edge_col := Color(0.70, 0.52, 0.02)

	# Build ellipse polygon (coin face)
	var pts := PackedVector2Array()
	var segs := 20
	for i in segs:
		var a := float(i) / float(segs) * TAU
		pts.append(Vector2(cos(a) * coin_rx, sin(a) * 8.0))
	draw_colored_polygon(pts, face_col)

	# Edge highlight
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, edge_col, 1.2)

	# Spinning shine strip
	var shine_x := cos(_spin + 0.5) * coin_rx * 0.55
	var shine_y := sin(_spin + 0.5) * 4.5
	draw_line(
		Vector2(-shine_x * 0.5, -shine_y * 0.5),
		Vector2( shine_x * 0.8,  shine_y * 0.8),
		Color(1.0, 1.0, 0.88, 0.75), 2.0
	)

	# "$" mark on front face
	if facing_front:
		draw_line(
			Vector2(0, -3) * Vector2(coin_rx / 8.0, 1.0),
			Vector2(0,  3) * Vector2(coin_rx / 8.0, 1.0),
			Color(0.62, 0.44, 0.02, 0.85), 1.5
		)
