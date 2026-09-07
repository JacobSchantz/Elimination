extends RigidBody2D

var direction: Vector2 = Vector2.RIGHT
var throw_force: float = 500.0
var damage: int = 40
var explosion_radius: float = 80.0
var knockback_force: float = 500.0
var shooter: Node2D = null

var fuse_time: float = 2.5
var has_exploded: bool = false

func _ready() -> void:
	linear_velocity = direction * throw_force
	
	# Add some arc
	linear_velocity.y -= 200

func _physics_process(delta: float) -> void:
	fuse_time -= delta
	
	if fuse_time <= 0 and not has_exploded:
		_explode()
	
	# Check if out of bounds
	if global_position.y > 800:
		queue_free()

func _explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
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
