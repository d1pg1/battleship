extends Node

enum State { PLACEMENT, PLAYER_TURN, AI_TURN, GAME_OVER }

signal turn_changed(new_state: State)
signal shot_fired(cell: Vector2i, result: Dictionary)
signal ship_placed(data: ShipData)
signal ship_sunk(data: ShipData, owner: String)
signal game_ended(winner: String)

const AI_DELAY_SEC := 0.8

var state: State = State.PLACEMENT
var player_board: BoardState
var ai_board: BoardState
var last_winner: String = ""

var _ai  # AIController — set by start_battle()
var _timer: Timer

func _ready() -> void:
	player_board = BoardState.new()
	ai_board = BoardState.new()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = AI_DELAY_SEC
	_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(_timer)

func reset() -> void:
	_timer.stop()
	player_board = BoardState.new()
	ai_board = BoardState.new()
	state = State.PLACEMENT
	last_winner = ""
	_ai = null

# ── Placement phase ──────────────────────────────────────────────────────────

func place_ship(data: ShipData) -> bool:
	if player_board.place_ship(data):
		ship_placed.emit(data)
		return true
	return false

func remove_ship(data: ShipData) -> void:
	player_board.remove_ship(data)

func can_place(data: ShipData) -> bool:
	return player_board.can_place(data)

func start_battle(ai_node) -> void:
	_ai = ai_node
	state = State.PLAYER_TURN
	turn_changed.emit(state)

# ── Combat ───────────────────────────────────────────────────────────────────

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
	state = State.AI_TURN
	turn_changed.emit(state)
	_timer.start()

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
	state = State.PLAYER_TURN
	turn_changed.emit(state)

func _end_game(winner: String) -> void:
	state = State.GAME_OVER
	last_winner = winner
	game_ended.emit(winner)
