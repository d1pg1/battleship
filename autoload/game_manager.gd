extends Node

enum State { PLACEMENT, PLAYER_TURN, AI_TURN, RESULT_PAUSE, HANDOFF, GAME_OVER }
enum GameMode { VS_AI, LOCAL_PVP, AI_VS_AI, CAMPAIGN }
enum AIDifficulty { EASY, MEDIUM, HARD, IMPOSSIBLE }

signal turn_changed(new_state: State)
signal shot_fired(cell: Vector2i, result: Dictionary)
signal ship_placed(data: ShipData)
signal ship_sunk(data: ShipData, owner: String)
signal campaign_event(text: String)
signal game_ended(winner: String)

const AI_DELAY_SEC := 0.8
const PVP_RESULT_DELAY_SEC := 1.1
const HARE_PLAYER_TURN_LIMIT_SEC := 10.0

const CAMPAIGN_LEVELS := [
	{
		"name": "Grandparents",
		"title": "Level 1 - Grandparents",
		"theme": "Tutorial waters",
		"ai_profile": "random",
		"ai_delay": 1.0,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/Grandparents.png",
		"portrait_color": Color(0.72, 0.55, 0.38, 1.0),
		"intro": "We built him... but he slipped away.",
		"victory": "Careful now, commander. You have learned the waters first.",
		"dialogue": [
			{ "speaker": "Grandparents", "text": "Commander, thank the tides you came. Our little experimental vessel, Kolobok, has escaped the yard." },
			{ "speaker": "{player}", "text": "Give me a fleet and a heading. I will bring Kolobok back." },
			{ "speaker": "Grandparents", "text": "First, place your fleet. Ships can face sideways or forward, but they cannot touch, even by corners." },
			{ "speaker": "Grandparents", "text": "In battle, choose a square on the enemy waters. A hit lets you fire again. A miss gives the enemy a turn." },
			{ "speaker": "{player}", "text": "Understood. I will read the water one shot at a time." },
			{ "speaker": "Grandparents", "text": "We will fire slowly and without tricks. Learn the grid, commander. Then follow Kolobok's wake." }
		]
	},
	{
		"name": "Hare",
		"title": "Level 2 - Hare",
		"theme": "Speed vs precision",
		"ai_profile": "hare",
		"ability": "hare_timer",
		"ai_delay": 0.45,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/Hare.png",
		"portrait_color": Color(0.62, 0.72, 0.88, 1.0),
		"intro": "Too slow! Too slow! I will find him first!",
		"victory": "Fast is not the same as accurate.",
		"dialogue": [
			{ "speaker": "Hare", "text": "Too slow! Too slow! Kolobok is already beyond your spyglass." },
			{ "speaker": "{player}", "text": "Then I will make each shot count." },
			{ "speaker": "Hare", "text": "You get ten seconds for each shot. I will pepper the waters until something cracks." }
		]
	},
	{
		"name": "Wolf",
		"title": "Level 3 - Wolf",
		"theme": "Hunting behavior",
		"ai_profile": "wolf",
		"ai_delay": 0.8,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/Wolf.png",
		"portrait_color": Color(0.42, 0.48, 0.55, 1.0),
		"intro": "Once I see blood... I do not stop.",
		"victory": "The hunter loses the trail.",
		"dialogue": [
			{ "speaker": "Wolf", "text": "Random waves are for frightened crews. I hunt patterns." },
			{ "speaker": "{player}", "text": "Patterns can be broken." },
			{ "speaker": "Wolf", "text": "Once I strike steel, I search around the wound until the whole ship goes under." }
		]
	},
	{
		"name": "Bear",
		"title": "Level 4 - Bear",
		"theme": "Power vs efficiency",
		"ai_profile": "wolf",
		"ability": "bear_area",
		"ai_delay": 0.95,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/Bear.png",
		"portrait_color": Color(0.50, 0.36, 0.25, 1.0),
		"intro": "No need to aim... I crush everything.",
		"victory": "The sea is still again.",
		"dialogue": [
			{ "speaker": "Bear", "text": "Little shots. Little guesses. The sea trembles when I move." },
			{ "speaker": "{player}", "text": "Then I will stay ahead of the tremor." },
			{ "speaker": "Bear", "text": "Every few turns I strike a whole cross of water. Hide well, commander." }
		]
	},
	{
		"name": "Kolobok",
		"title": "Level 5 - Kolobok",
		"theme": "First encounter",
		"ai_profile": "wolf",
		"ability": "relocate",
		"ai_delay": 0.75,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/Kolobok.png",
		"portrait_color": Color(0.86, 0.68, 0.28, 1.0),
		"intro": "I sailed from them, I will sail from you!",
		"victory": "Kolobok slips away beyond the smoke.",
		"dialogue": [
			{ "speaker": "Kolobok", "text": "I sailed from the old hands. I sailed from the fast one. I sailed from the hunter." },
			{ "speaker": "{player}", "text": "And now you sail into my grid." },
			{ "speaker": "Kolobok", "text": "Strike me and I may shift what you have not yet found. Catch me if you can, commander." }
		]
	},
	{
		"name": "Fox",
		"title": "Level 6 - Fox",
		"theme": "Deception",
		"ai_profile": "wolf",
		"ability": "decoy",
		"ai_delay": 0.7,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/Fox.png",
		"portrait_color": Color(0.86, 0.42, 0.22, 1.0),
		"intro": "Come closer, commander... just a little closer.",
		"victory": "The fox's whisper fades under the waves.",
		"dialogue": [
			{ "speaker": "Fox", "text": "You have become clever. That is dangerous. Clever captains trust what they think they see." },
			{ "speaker": "{player}", "text": "Then I will trust the pattern, not the whisper." },
			{ "speaker": "Fox", "text": "Some signals will lie. Come closer, commander. Just a little closer." }
		]
	},
	{
		"name": "True Kolobok",
		"title": "Final Level - True Kolobok",
		"theme": "Adaptation",
		"ai_profile": "wolf",
		"ability": "true_mix",
		"ai_delay": 0.65,
		"portrait_path": "res://assets/Naval Battle Assets/Characters/True_Kolobok.png",
		"portrait_color": Color(0.95, 0.82, 0.32, 1.0),
		"intro": "You have learned from them... now learn from me.",
		"victory": "You have grown... enough to stop me.",
		"dialogue": [
			{ "speaker": "True Kolobok", "text": "You have learned from them. Speed. Hunger. Pressure. Doubt." },
			{ "speaker": "{player}", "text": "I learned enough to end the chase." },
			{ "speaker": "True Kolobok", "text": "I can shift, deceive, and strike wide. I am not running. I am choosing." }
		]
	},
]

var mode: GameMode = GameMode.VS_AI
var ai_difficulty: int = AIDifficulty.MEDIUM
var state: State = State.PLACEMENT
var player_board: BoardState
var ai_board: BoardState
var last_winner: String = ""
var active_player: int = 1
var campaign_level_index: int = 0
var campaign_player_name: String = "Commander"
var campaign_in_progress := false

var _ai  # AIController — set by start_battle()
var _ai_player_1
var _ai_player_2
var _timer: Timer
var _pvp_handoff_timer: Timer
var _player_turn_timer: Timer
var _pending_active_player: int = 1
var _kolobok_relocation_used := false
var _fox_decoys_remaining := 0
var _bear_area_cooldown := 0

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

	_player_turn_timer = Timer.new()
	_player_turn_timer.one_shot = true
	_player_turn_timer.wait_time = HARE_PLAYER_TURN_LIMIT_SEC
	_player_turn_timer.timeout.connect(_on_player_turn_timer_timeout)
	add_child(_player_turn_timer)

func reset() -> void:
	_timer.stop()
	_pvp_handoff_timer.stop()
	_player_turn_timer.stop()
	_timer.wait_time = AI_DELAY_SEC
	player_board = BoardState.new()
	ai_board = BoardState.new()
	state = State.PLACEMENT
	last_winner = ""
	active_player = 1
	_pending_active_player = 1
	_ai = null
	_ai_player_1 = null
	_ai_player_2 = null
	_kolobok_relocation_used = false
	_fox_decoys_remaining = 0
	_bear_area_cooldown = 0

func start_new_game(new_mode: GameMode) -> void:
	mode = new_mode
	reset()

func start_campaign(player_name: String = "") -> void:
	mode = GameMode.CAMPAIGN
	campaign_level_index = 0
	campaign_player_name = _clean_campaign_name(player_name)
	campaign_in_progress = true
	reset()

func continue_campaign() -> void:
	mode = GameMode.CAMPAIGN
	campaign_in_progress = true
	reset()

func has_campaign_progress() -> bool:
	return campaign_in_progress and campaign_level_index >= 0 and campaign_level_index < CAMPAIGN_LEVELS.size()

func complete_campaign() -> void:
	campaign_in_progress = false

func campaign_level() -> Dictionary:
	return CAMPAIGN_LEVELS[campaign_level_index]

func campaign_ability() -> String:
	var level := campaign_level()
	return level["ability"] if level.has("ability") else ""

func campaign_opponent_name() -> String:
	return campaign_level()["name"]

func campaign_title() -> String:
	return campaign_level()["title"]

func campaign_intro() -> String:
	return campaign_level()["intro"]

func campaign_victory_text() -> String:
	return campaign_level()["victory"]

func campaign_dialogue() -> Array:
	return campaign_level()["dialogue"]

func campaign_display_text(text: String) -> String:
	return text.replace("{player}", campaign_player_name)

func campaign_portrait_color() -> Color:
	return campaign_level()["portrait_color"]

func campaign_portrait_path() -> String:
	return campaign_level()["portrait_path"]

func campaign_player_portrait_color() -> Color:
	return Color(0.30, 0.58, 0.86, 1.0)

func campaign_is_tutorial() -> bool:
	return campaign_level_index == 0

func campaign_is_final_level() -> bool:
	return campaign_level_index >= CAMPAIGN_LEVELS.size() - 1

func advance_campaign_level() -> void:
	if not campaign_is_final_level():
		campaign_level_index += 1

func start_vs_ai_game(difficulty: int) -> void:
	mode = GameMode.VS_AI
	reset()
	ai_difficulty = difficulty

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

func start_battle(ai_node = null, ai_player_2_node = null) -> void:
	_ai = ai_node
	_ai_player_1 = ai_node
	_ai_player_2 = ai_player_2_node
	if mode == GameMode.CAMPAIGN:
		var level := campaign_level()
		_timer.wait_time = level["ai_delay"]
		_fox_decoys_remaining = 2 if campaign_ability() in ["decoy", "true_mix"] else 0
		_bear_area_cooldown = 0
	if mode == GameMode.VS_AI and _ai != null:
		_ai.set_difficulty(ai_difficulty)
		_ai.set_target_board(player_board)
	elif mode == GameMode.CAMPAIGN and _ai != null:
		_ai.set_difficulty(AIDifficulty.HARD)
		_ai.set_target_board(player_board)
	elif mode == GameMode.AI_VS_AI:
		if _ai_player_1 != null:
			_ai_player_1.set_difficulty(AIDifficulty.HARD)
			_ai_player_1.set_target_board(ai_board)
		if _ai_player_2 != null:
			_ai_player_2.set_difficulty(AIDifficulty.HARD)
			_ai_player_2.set_target_board(player_board)
	active_player = 1
	state = State.AI_TURN if mode == GameMode.AI_VS_AI else State.PLAYER_TURN
	turn_changed.emit(state)
	_start_campaign_player_timer_if_needed()
	if mode == GameMode.AI_VS_AI:
		_timer.start()

# ── Combat ───────────────────────────────────────────────────────────────────

func current_player_board() -> BoardState:
	return player_board if active_player == 1 else ai_board

func current_target_board() -> BoardState:
	return ai_board if active_player == 1 else player_board

func player_label(player_number: int) -> String:
	if mode == GameMode.AI_VS_AI:
		return "AI %d" % player_number
	return "PLAYER %d" % player_number

func active_player_label() -> String:
	return player_label(active_player)

func target_owner_id() -> String:
	return "player2" if active_player == 1 else "player1"

func active_winner_id() -> String:
	return "player1" if active_player == 1 else "player2"

func fire_at_target(cell: Vector2i) -> void:
	match mode:
		GameMode.LOCAL_PVP:
			pvp_fire(cell)
		GameMode.VS_AI:
			player_fire(cell)
		GameMode.CAMPAIGN:
			player_fire(cell)

func player_fire(cell: Vector2i) -> void:
	if state != State.PLAYER_TURN:
		return
	_player_turn_timer.stop()
	var result := ai_board.fire(cell)
	_apply_campaign_player_deception(result)
	shot_fired.emit(cell, result)
	if result["sunk_ship"] != null:
		ai_board.reveal_surroundings(result["sunk_ship"])
		ship_sunk.emit(result["sunk_ship"], "ai")
	if ai_board.all_sunk():
		_end_game("player")
		return
	_try_campaign_relocation(result)
	if result["result"] == BoardState.Cell.HIT:
		turn_changed.emit(state)
		_start_campaign_player_timer_if_needed()
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
	_start_campaign_player_timer_if_needed()

func _on_player_turn_timer_timeout() -> void:
	if mode != GameMode.CAMPAIGN or state != State.PLAYER_TURN:
		return
	if not (campaign_ability() in ["hare_timer", "true_mix"]):
		return
	campaign_event.emit("Time expired. The turn passes to the enemy.")
	state = State.AI_TURN
	turn_changed.emit(state)
	_timer.start()

func _start_campaign_player_timer_if_needed() -> void:
	_player_turn_timer.stop()
	if mode != GameMode.CAMPAIGN or state != State.PLAYER_TURN:
		return
	if not (campaign_ability() in ["hare_timer", "true_mix"]):
		return
	_player_turn_timer.wait_time = HARE_PLAYER_TURN_LIMIT_SEC
	_player_turn_timer.start()

func _on_pvp_handoff_timer_timeout() -> void:
	if mode != GameMode.LOCAL_PVP or state == State.GAME_OVER:
		return
	active_player = _pending_active_player
	state = State.HANDOFF
	turn_changed.emit(state)

func _on_ai_timer_timeout() -> void:
	if mode == GameMode.AI_VS_AI:
		_run_ai_vs_ai_turn()
		return
	if mode == GameMode.CAMPAIGN and _should_use_bear_area():
		_run_campaign_area_attack()
		return
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
	_start_campaign_player_timer_if_needed()

func _apply_campaign_player_deception(result: Dictionary) -> void:
	if mode != GameMode.CAMPAIGN:
		return
	if _fox_decoys_remaining <= 0:
		return
	if result["result"] != BoardState.Cell.MISS:
		return
	if randf() > 0.35:
		return
	_fox_decoys_remaining -= 1
	result["decoy"] = true
	result["message"] = "False signal. The fox made a miss look promising."

func _try_campaign_relocation(result: Dictionary) -> void:
	if mode != GameMode.CAMPAIGN:
		return
	if _kolobok_relocation_used:
		return
	if not (campaign_ability() in ["relocate", "true_mix"]):
		return
	if result["result"] != BoardState.Cell.HIT or result["sunk_ship"] != null:
		return
	if ai_board.relocate_random_unhit_ship():
		_kolobok_relocation_used = true
		campaign_event.emit("Kolobok shifted one hidden ship after the hit.")

func _should_use_bear_area() -> bool:
	if not (campaign_ability() in ["bear_area", "true_mix"]):
		return false
	if _bear_area_cooldown > 0:
		_bear_area_cooldown -= 1
		return false
	return true

func _run_campaign_area_attack() -> void:
	var center: Vector2i = _ai.choose_cell()
	var cells: Array[Vector2i] = _area_cells(center)
	var hit_any := false
	campaign_event.emit("%s launches an area strike." % campaign_opponent_name())
	_bear_area_cooldown = 3
	for cell in cells:
		if player_board.is_already_fired(cell):
			continue
		var result: Dictionary = player_board.fire(cell)
		var fired_cells: Array[Vector2i] = [cell]
		_ai.add_to_fired(fired_cells)
		_ai.on_fire_result(cell, result)
		shot_fired.emit(cell, result)
		if result["result"] == BoardState.Cell.HIT:
			hit_any = true
		if result["sunk_ship"] != null:
			var revealed := player_board.reveal_surroundings(result["sunk_ship"])
			_ai.add_to_fired(revealed)
			ship_sunk.emit(result["sunk_ship"], "player")
		if player_board.all_sunk():
			_end_game("ai")
			return
	if hit_any:
		_timer.start()
		return
	state = State.PLAYER_TURN
	turn_changed.emit(state)
	_start_campaign_player_timer_if_needed()

func _area_cells(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var deltas: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for delta in deltas:
		var cell := center + delta
		if cell.x >= 0 and cell.x < BoardState.GRID_SIZE and cell.y >= 0 and cell.y < BoardState.GRID_SIZE:
			cells.append(cell)
	return cells

func _run_ai_vs_ai_turn() -> void:
	if state == State.GAME_OVER:
		return
	var controller = _ai_player_1 if active_player == 1 else _ai_player_2
	var target_board := current_target_board()
	controller.set_target_board(target_board)
	var cell: Vector2i = controller.choose_cell()
	var result := target_board.fire(cell)
	controller.on_fire_result(cell, result)
	shot_fired.emit(cell, result)
	if result["sunk_ship"] != null:
		var revealed := target_board.reveal_surroundings(result["sunk_ship"])
		controller.add_to_fired(revealed)
		ship_sunk.emit(result["sunk_ship"], target_owner_id())
	if target_board.all_sunk():
		_end_game(active_winner_id())
		return
	if result["result"] != BoardState.Cell.HIT:
		active_player = 2 if active_player == 1 else 1
	turn_changed.emit(state)
	_timer.start()

func _end_game(winner: String) -> void:
	_player_turn_timer.stop()
	state = State.GAME_OVER
	last_winner = winner
	if mode == GameMode.CAMPAIGN and winner == "player" and campaign_is_final_level():
		complete_campaign()
	game_ended.emit(winner)

func _clean_campaign_name(player_name: String) -> String:
	var cleaned := player_name.strip_edges()
	if cleaned.is_empty():
		return campaign_player_name if not campaign_player_name.is_empty() else "Commander"
	return cleaned.substr(0, 18)
