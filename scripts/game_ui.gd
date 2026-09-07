extends CanvasLayer

@onready var turn_label: Label = $TurnLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var movement_bar: ProgressBar = $MovementBar
@onready var controls_label: Label = $ControlsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var winner_label: Label = $GameOverPanel/WinnerLabel

var game_manager: Node = null
var current_soldier: Node2D = null

func _ready() -> void:
	game_over_panel.visible = false
	
	await get_tree().process_frame
	game_manager = get_node_or_null("/root/Main/GameManager")
	
	if game_manager:
		game_manager.turn_changed.connect(_on_turn_changed)
		game_manager.game_over.connect(_on_game_over)

func _on_turn_changed(team: int, soldier_index: int) -> void:
	var team_name = "Red Team" if team == 0 else "Blue Team"
	var team_color = Color.RED if team == 0 else Color.BLUE
	
	turn_label.text = "%s - Soldier %d" % [team_name, soldier_index + 1]
	turn_label.modulate = team_color
	
	# Connect to new soldier
	if current_soldier:
		if current_soldier.health_changed.is_connected(_on_health_changed):
			current_soldier.health_changed.disconnect(_on_health_changed)
		if current_soldier.movement_changed.is_connected(_on_movement_changed):
			current_soldier.movement_changed.disconnect(_on_movement_changed)
	
	current_soldier = game_manager.current_soldier
	if current_soldier:
		current_soldier.health_changed.connect(_on_health_changed)
		current_soldier.movement_changed.connect(_on_movement_changed)
		health_bar.value = current_soldier.health
		movement_bar.value = current_soldier.movement_remaining

func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health

func _on_movement_changed(remaining: float) -> void:
	movement_bar.value = remaining

func _process(_delta: float) -> void:
	if current_soldier:
		var weapon_names = ["Gun", "Rocket Launcher", "Grenade"]
		weapon_label.text = "Weapon: " + weapon_names[current_soldier.current_weapon]

func _on_game_over(winning_team: int) -> void:
	game_over_panel.visible = true
	var team_name = "Red Team" if winning_team == 0 else "Blue Team"
	winner_label.text = team_name + " Wins!"
	winner_label.modulate = Color.RED if winning_team == 0 else Color.BLUE
