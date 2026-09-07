extends Node2D

@onready var terrain_image: Image
@onready var terrain_texture: ImageTexture
@onready var terrain_sprite: Sprite2D = $TerrainSprite
@onready var collision_polygon: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D

var terrain_width: int = 1280
var terrain_height: int = 300
var terrain_y_offset: int = 420

func _ready() -> void:
	_generate_terrain()

func _generate_terrain() -> void:
	# Create terrain image
	terrain_image = Image.create(terrain_width, terrain_height, false, Image.FORMAT_RGBA8)
	
	# Fill with ground color
	var ground_color = Color(0.4, 0.3, 0.2, 1.0)  # Brown
	var grass_color = Color(0.2, 0.6, 0.2, 1.0)   # Green
	
	# Generate hills using sine waves
	for x in range(terrain_width):
		var hill_height = 50 + sin(x * 0.01) * 30 + sin(x * 0.02) * 20 + sin(x * 0.005) * 40
		hill_height = int(hill_height)
		
		for y in range(terrain_height):
			var terrain_y = terrain_height - hill_height
			if y >= terrain_y:
				if y == terrain_y or y == terrain_y + 1:
					terrain_image.set_pixel(x, y, grass_color)
				else:
					terrain_image.set_pixel(x, y, ground_color)
	
	_update_terrain_display()
	_update_collision()

func _update_terrain_display() -> void:
	terrain_texture = ImageTexture.create_from_image(terrain_image)
	terrain_sprite.texture = terrain_texture
	terrain_sprite.position = Vector2(terrain_width / 2, terrain_y_offset + terrain_height / 2)

func destroy_circle(center: Vector2, radius: float) -> void:
	# Convert world position to terrain image position
	var local_center = center - Vector2(0, terrain_y_offset)
	
	var start_x = int(max(0, local_center.x - radius))
	var end_x = int(min(terrain_width - 1, local_center.x + radius))
	var start_y = int(max(0, local_center.y - radius))
	var end_y = int(min(terrain_height - 1, local_center.y + radius))
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var dist = Vector2(x, y).distance_to(local_center)
			if dist <= radius:
				terrain_image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	_update_terrain_display()
	_update_collision()

func _update_collision() -> void:
	# Generate collision polygon from terrain
	# Using a simplified approach with multiple rectangles
	var polygons: Array[PackedVector2Array] = []
	
	# Scan columns and create collision shapes
	var column_heights: Array[int] = []
	
	for x in range(0, terrain_width, 4):  # Sample every 4 pixels for performance
		var top_y = -1
		var bottom_y = -1
		
		for y in range(terrain_height):
			var pixel = terrain_image.get_pixel(x, y)
			if pixel.a > 0.5:
				if top_y == -1:
					top_y = y
				bottom_y = y
		
		column_heights.append(top_y if top_y != -1 else terrain_height)
	
	# Create a simplified polygon
	var points: PackedVector2Array = []
	
	# Top edge (left to right)
	for i in range(column_heights.size()):
		var x = i * 4
		var y = column_heights[i] + terrain_y_offset
		if column_heights[i] < terrain_height:
			points.append(Vector2(x, y))
	
	# Bottom edge (right to left)
	points.append(Vector2(terrain_width, terrain_y_offset + terrain_height))
	points.append(Vector2(0, terrain_y_offset + terrain_height))
	
	if points.size() >= 3:
		collision_polygon.polygon = points

func get_height_at(x: float) -> float:
	var ix = int(clamp(x, 0, terrain_width - 1))
	
	for y in range(terrain_height):
		var pixel = terrain_image.get_pixel(ix, y)
		if pixel.a > 0.5:
			return y + terrain_y_offset
	
	return terrain_y_offset + terrain_height

func is_solid_at(pos: Vector2) -> bool:
	var local_pos = pos - Vector2(0, terrain_y_offset)
	
	if local_pos.x < 0 or local_pos.x >= terrain_width:
		return false
	if local_pos.y < 0 or local_pos.y >= terrain_height:
		return false
	
	var pixel = terrain_image.get_pixel(int(local_pos.x), int(local_pos.y))
	return pixel.a > 0.5
