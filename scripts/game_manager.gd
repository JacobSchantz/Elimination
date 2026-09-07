extends Node

signal turn_changed(team: int, soldier_index: int)
signal game_over(winning_team: int)
signal soldier_eliminated(soldier: Node2D)

enum GameState { MOVING, AIMING, ATTACKING, TURN_ENDING, GAME_OVER }
enum Team { RED, BLUE }

var current_team: int = Team.RED
var current_soldier_index: int = 0
var game_state: GameState = GameState.MOVING

var team_red: Array[Node2D] = []
var team_blue: Array[Node2D] = []

var current_soldier: Node2D = null

@onready var terrain: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	_find_soldiers()
	_start_turn()

func _find_soldiers() -> void:
	var soldiers = get_tree().get_nodes_in_group("soldiers")
	for soldier in soldiers:
		if soldier.team == Team.RED:
			team_red.append(soldier)
		else:
			team_blue.append(soldier)
		soldier.eliminated.connect(_on_soldier_eliminated)

func _start_turn() -> void:
	game_state = GameState.MOVING
	
	var team_array = team_red if current_team == Team.RED else team_blue
	if team_array.is_empty():
		return
	
	current_soldier_index = current_soldier_index % team_array.size()
	current_soldier = team_array[current_soldier_index]
	current_soldier.start_turn()
	
	turn_changed.emit(current_team, current_soldier_index)

func end_turn() -> void:
	if current_soldier:
		current_soldier.end_turn()
	
	game_state = GameState.TURN_ENDING
	
	# Switch teams
	current_team = Team.BLUE if current_team == Team.RED else Team.RED
	
	var team_array = team_red if current_team == Team.RED else team_blue
	if team_array.is_empty():
		_check_game_over()
		return
	
	current_soldier_index = (current_soldier_index + 1) % team_array.size()
	
	await get_tree().create_timer(0.5).timeout
	_start_turn()

func _on_soldier_eliminated(soldier: Node2D) -> void:
	soldier_eliminated.emit(soldier)
	
	if soldier.team == Team.RED:
		team_red.erase(soldier)
	else:
		team_blue.erase(soldier)
	
	_check_game_over()

func _check_game_over() -> void:
	if team_red.is_empty():
		game_state = GameState.GAME_OVER
		game_over.emit(Team.BLUE)
	elif team_blue.is_empty():
		game_state = GameState.GAME_OVER
		game_over.emit(Team.RED)

func set_state(new_state: GameState) -> void:
	game_state = new_state

func get_current_team_name() -> String:
	return "Red Team" if current_team == Team.RED else "Blue Team"
