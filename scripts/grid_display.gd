class_name GridDisplay
extends Node2D

signal cell_tapped(cell: Vector2i)

@export var interactive: bool = false
@export var hide_ships: bool = false
# Whether this display is the enemy grid (gates sunk reveal and turn-based interactivity)
@export var is_enemy_grid: bool = false
@export var placement_player_number: int = 1

const GRID_SIZE := 10
const CELL_SIZE := 56.0
const LABEL_OFFSET := 20.0
const GRID_ORIGIN := Vector2(LABEL_OFFSET, LABEL_OFFSET)

const COL_EMPTY   := Color(0.10, 0.45, 0.65, 1.0)
const COL_SHIP    := Color(0.40, 0.40, 0.45, 1.0)
const COL_HIT     := Color(0.85, 0.15, 0.10, 1.0)
const COL_MISS    := Color(0.75, 0.80, 0.85, 0.85)
const COL_SUNK    := Color(1.00, 0.50, 0.05, 1.0)
const COL_GRID    := Color(0.05, 0.20, 0.38, 1.0)
const COL_HOVER   := Color(1.00, 1.00, 1.00, 0.22)
const COL_GHOST_OK  := Color(0.20, 1.00, 0.30, 0.45)
const COL_GHOST_BAD := Color(1.00, 0.10, 0.10, 0.45)
const COL_LABEL   := Color(0.90, 0.95, 1.00, 1.0)

var board_state: BoardState = null

var _hover_cell := Vector2i(-1, -1)
var _ghost_ship: ShipData = null
var _revealed_ships: Array[ShipData] = []
var _font: Font = null

func _ready() -> void:
	_font = ThemeDB.fallback_font
	set_process(interactive)

	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.ship_sunk.connect(_on_ship_sunk)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.shot_fired.connect(_on_shot_fired)

func _draw() -> void:
	if board_state == null:
		return

	var cols := "ABCDEFGHIJ"

	# ── Column labels (A–J) ──────────────────────────────────────────────────
	for c in range(GRID_SIZE):
		var x := GRID_ORIGIN.x + c * CELL_SIZE + CELL_SIZE * 0.5
		draw_string(_font, Vector2(x - 6, LABEL_OFFSET - 4), cols[c],
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14, COL_LABEL)

	# ── Row labels (1–10) ────────────────────────────────────────────────────
	for r in range(GRID_SIZE):
		var y := GRID_ORIGIN.y + r * CELL_SIZE + CELL_SIZE * 0.5 + 5
		draw_string(_font, Vector2(2, y), str(r + 1),
				HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, COL_LABEL)

	# ── Cell fills ──────────────────────────────────────────────────────────
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell := Vector2i(col, row)
			var rect := Rect2(_cell_to_local(cell), Vector2.ONE * CELL_SIZE)
			var cell_state: BoardState.Cell = board_state.get_cell(cell)
			var colour: Color
			match cell_state:
				BoardState.Cell.EMPTY:
					colour = COL_EMPTY
				BoardState.Cell.SHIP:
					colour = COL_EMPTY if hide_ships else COL_SHIP
				BoardState.Cell.HIT:
					colour = COL_HIT
				BoardState.Cell.MISS:
					colour = COL_MISS
				_:
					colour = COL_EMPTY
			draw_rect(rect, colour, true)

	# ── Sunk ship reveal ─────────────────────────────────────────────────────
	for data in _revealed_ships:
		for cell in data.cells():
			var rect := Rect2(_cell_to_local(cell), Vector2.ONE * CELL_SIZE)
			draw_rect(rect, COL_SUNK, true)
		# Draw outline around full ship footprint
		var first_local := _cell_to_local(data.cells()[0])
		var last_cell := data.cells()[-1]
		var last_end := _cell_to_local(last_cell) + Vector2.ONE * CELL_SIZE
		draw_rect(Rect2(first_local, last_end - first_local), Color.WHITE, false, 2.0)

	# ── Ghost ship preview ───────────────────────────────────────────────────
	if _ghost_ship != null:
		var is_valid := GameManager.can_place(_ghost_ship, placement_player_number)
		var ghost_col := COL_GHOST_OK if is_valid else COL_GHOST_BAD
		for cell in _ghost_ship.cells():
			if _in_bounds(cell):
				draw_rect(Rect2(_cell_to_local(cell), Vector2.ONE * CELL_SIZE), ghost_col, true)

	# ── Grid lines ───────────────────────────────────────────────────────────
	for i in range(GRID_SIZE + 1):
		var x := GRID_ORIGIN.x + i * CELL_SIZE
		draw_line(Vector2(x, GRID_ORIGIN.y),
				Vector2(x, GRID_ORIGIN.y + GRID_SIZE * CELL_SIZE), COL_GRID, 1.0)
		var y := GRID_ORIGIN.y + i * CELL_SIZE
		draw_line(Vector2(GRID_ORIGIN.x, y),
				Vector2(GRID_ORIGIN.x + GRID_SIZE * CELL_SIZE, y), COL_GRID, 1.0)

	# ── Hover highlight ──────────────────────────────────────────────────────
	if interactive and _in_bounds(_hover_cell):
		if board_state != null and not board_state.is_already_fired(_hover_cell):
			draw_rect(Rect2(_cell_to_local(_hover_cell), Vector2.ONE * CELL_SIZE), COL_HOVER, true)

func _process(_delta: float) -> void:
	if not interactive:
		return
	var new_hover := _world_to_cell(get_global_mouse_position())
	if new_hover != _hover_cell:
		_hover_cell = new_hover
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var cell := _world_to_cell(mb.global_position)
			if _in_bounds(cell) and board_state != null and not board_state.is_already_fired(cell):
				cell_tapped.emit(cell)

# ── Public API ───────────────────────────────────────────────────────────────

func refresh() -> void:
	queue_redraw()

func set_board_state(new_board_state: BoardState) -> void:
	board_state = new_board_state
	_revealed_ships = []
	if board_state != null and hide_ships:
		for ship in board_state.ships:
			if ship.is_sunk():
				_revealed_ships.append(ship)
	queue_redraw()

func set_ghost(data: ShipData) -> void:
	_ghost_ship = data
	queue_redraw()

# ── Signal handlers ──────────────────────────────────────────────────────────

func _on_turn_changed(new_state: GameManager.State) -> void:
	if is_enemy_grid:
		interactive = (new_state == GameManager.State.PLAYER_TURN)
		set_process(interactive)
	queue_redraw()

func _on_ship_sunk(data: ShipData, _owner: String) -> void:
	if is_enemy_grid and board_state != null and data in board_state.ships:
		_revealed_ships.append(data)
	queue_redraw()

func _on_game_ended(_winner: String) -> void:
	interactive = false
	set_process(false)
	queue_redraw()

func _on_shot_fired(_cell: Vector2i, _result: Dictionary) -> void:
	queue_redraw()

# ── Helpers ──────────────────────────────────────────────────────────────────

func _cell_to_local(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	var local := to_local(world_pos) - GRID_ORIGIN
	return Vector2i(int(local.x / CELL_SIZE), int(local.y / CELL_SIZE))

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE
