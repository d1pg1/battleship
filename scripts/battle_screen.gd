extends Node2D

@onready var _ai_controller: AIController    = $AIController
@onready var _enemy_grid: GridDisplay        = $EnemyGridDisplay
@onready var _player_grid: GridDisplay       = $PlayerGridDisplay

func _ready() -> void:
	# Wire boards to grid displays
	_enemy_grid.board_state  = GameManager.ai_board
	_player_grid.board_state = GameManager.player_board

	# Place AI ships randomly (invisible to player)
	GameManager.ai_board.random_place_all([
		{ "name": "Battleship",  "size": 4 },
		{ "name": "Cruiser 1",   "size": 3 },
		{ "name": "Cruiser 2",   "size": 3 },
		{ "name": "Destroyer 1", "size": 2 },
		{ "name": "Destroyer 2", "size": 2 },
		{ "name": "Destroyer 3", "size": 2 },
		{ "name": "Patrol 1",    "size": 1 },
		{ "name": "Patrol 2",    "size": 1 },
		{ "name": "Patrol 3",    "size": 1 },
		{ "name": "Patrol 4",    "size": 1 },
	])

	# Connect fire input
	_enemy_grid.cell_tapped.connect(GameManager.player_fire)

	# Connect game-over transition
	GameManager.game_ended.connect(_on_game_ended)

	# Start the battle (PLAYER_TURN state + signal)
	GameManager.start_battle(_ai_controller)

func _on_game_ended(_winner: String) -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/result_screen.tscn")
