extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: int = 50
var explosion_radius: float = 60.0
var knockback_force: float = 400.0
var shooter: Node2D = null

var lifetime: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		_explode()
	
	# Check terrain collision
	var terrain = get_node_or_null("/root/Main/DestructibleTerrain")
	if terrain and terrain.is_solid_at(global_position):
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if body.is_in_group("soldiers"):
		_explode()

func _explode() -> void:
	# Destroy terrain
	var terrain = get_node_or_null("/root/Main/DestructibleTerrain")
	if terrain:
		terrain.destroy_circle(global_position, explosion_radius)
	
	# Damage and knockback nearby soldiers
	var soldiers = get_tree().get_nodes_in_group("soldiers")
	for soldier in soldiers:
		var dist = global_position.distance_to(soldier.global_position)
		if dist < explosion_radius * 1.5:
			var damage_mult = 1.0 - (dist / (explosion_radius * 1.5))
			soldier.take_damage(int(damage * damage_mult))
			
			var knockback_dir = (soldier.global_position - global_position).normalized()
			soldier.apply_knockback(knockback_dir * knockback_force * damage_mult)
	
	# Spawn explosion effect
	_spawn_explosion_effect()
	
	queue_free()

func _spawn_explosion_effect() -> void:
	var explosion = preload("res://scenes/explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_tree().root.get_node("Main").add_child(explosion)
