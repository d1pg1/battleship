extends Node2D

const FLEET := [
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
]

@onready var _ai_controller: AIController    = $AIController
@onready var _ai_controller_p2: AIController = $AIControllerP2
@onready var _enemy_grid: GridDisplay        = $EnemyGridDisplay
@onready var _player_grid: GridDisplay       = $PlayerGridDisplay
@onready var _menu_btn: Button               = $UILayer/HUD/MenuButton
@onready var _enemy_label: Label             = $UILayer/HUD/EnemyLabel
@onready var _player_label: Label            = $UILayer/HUD/PlayerLabel
@onready var _handoff_overlay: Control       = $UILayer/HandoffOverlay
@onready var _handoff_label: Label           = $UILayer/HandoffOverlay/Panel/VBox/HandoffLabel
@onready var _ready_btn: Button              = $UILayer/HandoffOverlay/Panel/VBox/ReadyButton

func _ready() -> void:
	# Wire boards to grid displays
	_enemy_grid.set_board_state(GameManager.ai_board)
	_player_grid.set_board_state(GameManager.player_board)

	if GameManager.mode == GameManager.GameMode.VS_AI:
		# Place AI ships randomly (invisible to player)
		GameManager.ai_board.random_place_all(FLEET)
		_enemy_grid.set_board_state(GameManager.ai_board)
	elif GameManager.mode == GameManager.GameMode.AI_VS_AI:
		GameManager.player_board.random_place_all(FLEET)
		GameManager.ai_board.random_place_all(FLEET)
		_enemy_grid.hide_ships = false
		_enemy_grid.interactive = false
		_enemy_grid.set_process(false)
		_enemy_grid.set_board_state(GameManager.ai_board)
		_player_grid.set_board_state(GameManager.player_board)
		_enemy_label.text = "AI 2 FLEET"
		_player_label.text = "AI 1 FLEET"

	# Connect fire input
	_enemy_grid.cell_tapped.connect(GameManager.fire_at_target)

	# Connect game-over transition and menu button
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.turn_changed.connect(_on_turn_changed)
	_menu_btn.pressed.connect(_on_menu_pressed)
	_ready_btn.pressed.connect(_on_ready_pressed)

	# Start the battle (PLAYER_TURN state + signal)
	match GameManager.mode:
		GameManager.GameMode.VS_AI:
			GameManager.start_battle(_ai_controller)
		GameManager.GameMode.AI_VS_AI:
			GameManager.start_battle(_ai_controller, _ai_controller_p2)
		_:
			GameManager.start_battle()
			_show_handoff()

func _apply_pvp_perspective() -> void:
	_enemy_grid.set_board_state(GameManager.current_target_board())
	_player_grid.set_board_state(GameManager.current_player_board())
	_enemy_label.text = "OPPONENT WATERS - click to fire"
	_player_label.text = "%s FLEET" % GameManager.active_player_label()

func _show_handoff() -> void:
	_handoff_label.text = "PASS TO %s" % GameManager.active_player_label()
	_handoff_overlay.visible = true
	_enemy_grid.visible = false
	_player_grid.visible = false
	_enemy_grid.interactive = false
	_enemy_grid.set_process(false)

func _hide_handoff() -> void:
	_apply_pvp_perspective()
	_handoff_overlay.visible = false
	_enemy_grid.visible = true
	_player_grid.visible = true
	_enemy_grid.interactive = GameManager.state == GameManager.State.PLAYER_TURN
	_enemy_grid.set_process(_enemy_grid.interactive)

func _on_ready_pressed() -> void:
	_hide_handoff()
	if GameManager.state == GameManager.State.HANDOFF:
		GameManager.begin_pvp_turn()

func _on_turn_changed(new_state: GameManager.State) -> void:
	if GameManager.mode != GameManager.GameMode.LOCAL_PVP:
		return
	if new_state == GameManager.State.HANDOFF:
		_show_handoff()
	elif new_state == GameManager.State.PLAYER_TURN and not _handoff_overlay.visible:
		_apply_pvp_perspective()

func _on_game_ended(_winner: String) -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/result_screen.tscn")

func _on_menu_pressed() -> void:
	GameManager.reset()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
