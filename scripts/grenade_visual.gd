extends Node2D

func _draw() -> void:
	# Grenade body
	draw_circle(Vector2.ZERO, 8, Color.DARK_GREEN)
	# Pin/top
	draw_rect(Rect2(-3, -12, 6, 4), Color.GRAY)
