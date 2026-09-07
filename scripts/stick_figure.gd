extends Node2D

# Draw a stick figure
func _draw() -> void:
	var line_width = 3.0
	var color = Color.WHITE
	
	# Head (circle)
	draw_arc(Vector2(0, -45), 8, 0, TAU, 32, color, line_width)
	
	# Body (vertical line)
	draw_line(Vector2(0, -37), Vector2(0, -10), color, line_width)
	
	# Arms (horizontal line with slight angle)
	draw_line(Vector2(-15, -30), Vector2(15, -30), color, line_width)
	
	# Left leg
	draw_line(Vector2(0, -10), Vector2(-10, 0), color, line_width)
	
	# Right leg
	draw_line(Vector2(0, -10), Vector2(10, 0), color, line_width)
