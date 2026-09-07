extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 800.0
var damage: int = 25
var shooter: Node2D = null

var lifetime: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	# Check terrain collision
	var terrain = get_node_or_null("/root/Main/DestructibleTerrain")
	if terrain and terrain.is_solid_at(global_position):
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if body.is_in_group("soldiers"):
		body.take_damage(damage)
		queue_free()

func _explode() -> void:
	# Small terrain destruction
	var terrain = get_node_or_null("/root/Main/DestructibleTerrain")
	if terrain:
		terrain.destroy_circle(global_position, 10)
	
	queue_free()
