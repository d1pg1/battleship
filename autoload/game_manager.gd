extends Node

enum State { PLACEMENT, PLAYER_TURN, AI_TURN, RESULT_PAUSE, HANDOFF, GAME_OVER }
enum GameMode { VS_AI, LOCAL_PVP }

signal turn_changed(new_state: State)
signal shot_fired(cell: Vector2i, result: Dictionary)
signal ship_placed(data: ShipData)
signal ship_sunk(data: ShipData, owner: String)
signal game_ended(winner: String)

const AI_DELAY_SEC := 0.8
const PVP_RESULT_DELAY_SEC := 1.1

var mode: GameMode = GameMode.VS_AI
var state: State = State.PLACEMENT
var player_board: BoardState
var ai_board: BoardState
var last_winner: String = ""
var active_player: int = 1

var _ai  # AIController — set by start_battle()
var _timer: Timer
var _pvp_handoff_timer: Timer
var _pending_active_player: int = 1

func _ready() -> void:
	player_board = BoardState.new()
	ai_board = BoardState.new()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = AI_DELAY_SEC
	_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(_timer)

	_pvp_handoff_timer = Timer.new()
	_pvp_handoff_timer.one_shot = true
	_pvp_handoff_timer.wait_time = PVP_RESULT_DELAY_SEC
	_pvp_handoff_timer.timeout.connect(_on_pvp_handoff_timer_timeout)
	add_child(_pvp_handoff_timer)

func reset() -> void:
	_timer.stop()
	_pvp_handoff_timer.stop()
	player_board = BoardState.new()
	ai_board = BoardState.new()
	state = State.PLACEMENT
	last_winner = ""
	active_player = 1
	_pending_active_player = 1
	_ai = null

func start_new_game(new_mode: GameMode) -> void:
	mode = new_mode
	reset()

# ── Placement phase ──────────────────────────────────────────────────────────

func placement_board(player_number: int) -> BoardState:
	return player_board if player_number == 1 else ai_board

func place_ship(data: ShipData, player_number: int = 1) -> bool:
	if placement_board(player_number).place_ship(data):
		ship_placed.emit(data)
		return true
	return false

func remove_ship(data: ShipData, player_number: int = 1) -> void:
	placement_board(player_number).remove_ship(data)

func can_place(data: ShipData, player_number: int = 1) -> bool:
	return placement_board(player_number).can_place(data)

func start_battle(ai_node = null) -> void:
	_ai = ai_node
	active_player = 1
	state = State.PLAYER_TURN
	turn_changed.emit(state)

# ── Combat ───────────────────────────────────────────────────────────────────

func current_player_board() -> BoardState:
	return player_board if active_player == 1 else ai_board

func current_target_board() -> BoardState:
	return ai_board if active_player == 1 else player_board

func player_label(player_number: int) -> String:
	return "PLAYER %d" % player_number

func active_player_label() -> String:
	return player_label(active_player)

func target_owner_id() -> String:
	return "player2" if active_player == 1 else "player1"

func active_winner_id() -> String:
	return "player1" if active_player == 1 else "player2"

func fire_at_target(cell: Vector2i) -> void:
	if mode == GameMode.LOCAL_PVP:
		pvp_fire(cell)
	else:
		player_fire(cell)

func player_fire(cell: Vector2i) -> void:
	if state != State.PLAYER_TURN:
		return
	var result := ai_board.fire(cell)
	shot_fired.emit(cell, result)
	if result["sunk_ship"] != null:
		ai_board.reveal_surroundings(result["sunk_ship"])
		ship_sunk.emit(result["sunk_ship"], "ai")
	if ai_board.all_sunk():
		_end_game("player")
		return
	if result["result"] == BoardState.Cell.HIT:
		turn_changed.emit(state)
		return
	state = State.AI_TURN
	turn_changed.emit(state)
	_timer.start()

func pvp_fire(cell: Vector2i) -> void:
	if state != State.PLAYER_TURN:
		return
	var target_board := current_target_board()
	var result := target_board.fire(cell)
	shot_fired.emit(cell, result)
	if result["sunk_ship"] != null:
		target_board.reveal_surroundings(result["sunk_ship"])
		ship_sunk.emit(result["sunk_ship"], target_owner_id())
	if target_board.all_sunk():
		_end_game(active_winner_id())
		return
	if result["result"] == BoardState.Cell.HIT:
		turn_changed.emit(state)
		return
	_pending_active_player = 2 if active_player == 1 else 1
	state = State.RESULT_PAUSE
	turn_changed.emit(state)
	_pvp_handoff_timer.start()

func begin_pvp_turn() -> void:
	if mode != GameMode.LOCAL_PVP or state == State.GAME_OVER:
		return
	state = State.PLAYER_TURN
	turn_changed.emit(state)

func _on_pvp_handoff_timer_timeout() -> void:
	if mode != GameMode.LOCAL_PVP or state == State.GAME_OVER:
		return
	active_player = _pending_active_player
	state = State.HANDOFF
	turn_changed.emit(state)

func _on_ai_timer_timeout() -> void:
	var cell: Vector2i = _ai.choose_cell()
	var result := player_board.fire(cell)
	_ai.on_fire_result(cell, result)
	shot_fired.emit(cell, result)
	if result["sunk_ship"] != null:
		var revealed := player_board.reveal_surroundings(result["sunk_ship"])
		_ai.add_to_fired(revealed)
		ship_sunk.emit(result["sunk_ship"], "player")
	if player_board.all_sunk():
		_end_game("ai")
		return
	if result["result"] == BoardState.Cell.HIT:
		_timer.start()
		return
	state = State.PLAYER_TURN
	turn_changed.emit(state)

func _end_game(winner: String) -> void:
	state = State.GAME_OVER
	last_winner = winner
	game_ended.emit(winner)
