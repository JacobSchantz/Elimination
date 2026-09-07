extends Node2D

func _draw() -> void:
	# Rocket body
	draw_rect(Rect2(-10, -4, 20, 8), Color.DARK_GRAY)
	# Rocket tip
	draw_polygon(PackedVector2Array([Vector2(10, -4), Vector2(15, 0), Vector2(10, 4)]), PackedColorArray([Color.RED]))
	# Rocket fins
	draw_polygon(PackedVector2Array([Vector2(-10, -4), Vector2(-15, -8), Vector2(-10, -2)]), PackedColorArray([Color.ORANGE]))
	draw_polygon(PackedVector2Array([Vector2(-10, 4), Vector2(-15, 8), Vector2(-10, 2)]), PackedColorArray([Color.ORANGE]))
