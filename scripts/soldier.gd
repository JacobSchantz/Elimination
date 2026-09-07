extends CharacterBody2D

signal eliminated(soldier: Node2D)
signal health_changed(new_health: int)
signal movement_changed(remaining: float)

@export var team: int = 0  # 0 = Red, 1 = Blue
@export var max_health: int = 100
@export var max_movement: float = 200.0
@export var move_speed: float = 150.0
@export var jump_force: float = 400.0

var health: int = 100
var movement_remaining: float = 200.0
var turn_start_position: Vector2 = Vector2.ZERO
var is_active: bool = false
var is_aiming: bool = false
var has_attacked: bool = false
var facing_right: bool = true

var aim_angle: float = 0.0
const AIM_SPEED: float = 2.0

enum WeaponType { GUN, ROCKET, GRENADE }
var current_weapon: WeaponType = WeaponType.GUN

var gravity: float = 980.0

@onready var sprite: Node2D = $StickFigure
@onready var aim_line: Line2D = $AimLine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel

var game_manager: Node = null

func _ready() -> void:
	health = max_health
	movement_remaining = max_movement
	add_to_group("soldiers")
	
	await get_tree().process_frame
	game_manager = get_node_or_null("/root/Main/GameManager")
	
	_update_team_color()
	_update_health_display()
	aim_line.visible = false

func _update_team_color() -> void:
	var color = Color.RED if team == 0 else Color.BLUE
	if sprite:
		sprite.modulate = color

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if not is_active:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		move_and_slide()
		_check_out_of_bounds()
		return
	
	if is_aiming:
		_handle_aiming(delta)
	else:
		_handle_movement(delta)
	
	move_and_slide()
	_check_out_of_bounds()

func _handle_movement(delta: float) -> void:
	if has_attacked:
		return
	
	# Calculate distance from turn start position
	var distance_from_origin = global_position.distance_to(turn_start_position)
	movement_remaining = max(0, max_movement - distance_from_origin)
	movement_changed.emit(movement_remaining)
	
	var direction = 0.0
	if Input.is_action_pressed("move_left") and movement_remaining > 0:
		direction = -1.0
		facing_right = false
	elif Input.is_action_pressed("move_right") and movement_remaining > 0:
		direction = 1.0
		facing_right = true
	
	if direction != 0:
		velocity.x = direction * move_speed
		_update_sprite_direction()
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and movement_remaining > 30:
		velocity.y = -jump_force
	
	# Switch to aiming mode
	if Input.is_action_just_pressed("attack") and not has_attacked:
		is_aiming = true
		aim_line.visible = true
		if game_manager:
			game_manager.set_state(game_manager.GameState.AIMING)
	
	# Weapon selection
	if Input.is_action_just_pressed("weapon_1"):
		current_weapon = WeaponType.GUN
	elif Input.is_action_just_pressed("weapon_2"):
		current_weapon = WeaponType.ROCKET
	elif Input.is_action_just_pressed("weapon_3"):
		current_weapon = WeaponType.GRENADE
	
	# End turn early
	if Input.is_action_just_pressed("end_turn"):
		if game_manager:
			game_manager.end_turn()

func _handle_aiming(delta: float) -> void:
	# Aim up/down
	if Input.is_action_pressed("aim_up"):
		aim_angle -= AIM_SPEED * delta
	elif Input.is_action_pressed("aim_down"):
		aim_angle += AIM_SPEED * delta
	
	aim_angle = clamp(aim_angle, -PI/2, PI/2)
	
	# Update aim line
	var aim_direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	aim_direction = aim_direction.rotated(aim_angle if facing_right else -aim_angle)
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(aim_direction * 100)
	
	# Fire weapon
	if Input.is_action_just_pressed("attack"):
		_fire_weapon()
	
	# Cancel aiming
	if Input.is_action_just_pressed("end_turn"):
		is_aiming = false
		aim_line.visible = false
		if game_manager:
			game_manager.set_state(game_manager.GameState.MOVING)

func _fire_weapon() -> void:
	is_aiming = false
	has_attacked = true
	aim_line.visible = false
	
	var aim_direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	aim_direction = aim_direction.rotated(aim_angle if facing_right else -aim_angle)
	
	var projectile_scene: PackedScene
	match current_weapon:
		WeaponType.GUN:
			projectile_scene = preload("res://scenes/bullet.tscn")
		WeaponType.ROCKET:
			projectile_scene = preload("res://scenes/rocket.tscn")
		WeaponType.GRENADE:
			projectile_scene = preload("res://scenes/grenade.tscn")
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position + aim_direction * 30
	projectile.direction = aim_direction
	projectile.shooter = self
	get_tree().root.get_node("Main").add_child(projectile)
	
	if game_manager:
		game_manager.set_state(game_manager.GameState.ATTACKING)
	
	# End turn after a delay
	await get_tree().create_timer(1.5).timeout
	if game_manager and game_manager.game_state != game_manager.GameState.GAME_OVER:
		game_manager.end_turn()

func _update_sprite_direction() -> void:
	if sprite:
		sprite.scale.x = 1 if facing_right else -1

func _check_out_of_bounds() -> void:
	if global_position.y > 800 or global_position.x < -100 or global_position.x > 1400:
		take_damage(health)  # Instant elimination

func take_damage(amount: int) -> void:
	health -= amount
	health = max(0, health)
	health_changed.emit(health)
	_update_health_display()
	
	if health <= 0:
		_die()

func _die() -> void:
	is_active = false
	eliminated.emit(self)
	
	# Death animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func start_turn() -> void:
	is_active = true
	has_attacked = false
	turn_start_position = global_position
	movement_remaining = max_movement
	movement_changed.emit(movement_remaining)

func end_turn() -> void:
	is_active = false
	is_aiming = false
	aim_line.visible = false

func apply_knockback(force: Vector2) -> void:
	velocity += force

func _update_health_display() -> void:
	if health_bar:
		health_bar.value = health
	if health_label:
		health_label.text = str(health)
