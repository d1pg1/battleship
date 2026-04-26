class_name GridDisplay
extends Node2D

signal cell_tapped(cell: Vector2i)

@export var interactive: bool = false
@export var hide_ships: bool = false
@export var is_enemy_grid: bool = false

const GRID_SIZE := 10
const CELL_SIZE := 52.0
const LABEL_OFFSET := 52.0
const GRID_ORIGIN := Vector2(LABEL_OFFSET, LABEL_OFFSET)
const BOARD_TEXTURE_SIZE := CELL_SIZE * 11.0
const TOKEN_SIZE := 34.0

const COL_SHIP := Color(0.40, 0.40, 0.45, 1.0)
const COL_SUNK := Color(1.00, 0.50, 0.05, 1.0)
const COL_HOVER := Color(1.00, 1.00, 1.00, 0.22)
const COL_GHOST_OK := Color(0.20, 1.00, 0.30, 0.45)
const COL_GHOST_BAD := Color(1.00, 0.10, 0.10, 0.45)

const OCEAN_GRID_TEX := preload("res://assets/Naval Battle Assets/oceangrid_final.png")
const RADAR_GRID_TEX := preload("res://assets/Naval Battle Assets/radargrid_final.png")
const SHIP_SHEET_TEX := preload("res://assets/Naval Battle Assets/BattleShipSheet_final.png")
const TOKENS_TEX := preload("res://assets/Naval Battle Assets/Tokens.png")

const SHIP_REGIONS := {
	"1_h": Rect2(245, 179, 30, 30),
	"2_h": Rect2(245, 219, 60, 30),
	"3_h": Rect2(245, 257, 90, 30),
	"4_h": Rect2(245, 331, 120, 30),
	"1_v": Rect2(1, 369, 30, 30),
	"2_v": Rect2(36, 339, 30, 60),
	"3_v": Rect2(74, 307, 30, 90),
	"4_v": Rect2(148, 279, 30, 120),
}

const TOKEN_MISS_REGION := Rect2(64, 0, 32, 32)
const TOKEN_HIT_REGION := Rect2(96, 0, 32, 32)

var board_state: BoardState = null

var _hover_cell := Vector2i(-1, -1)
var _ghost_ship: ShipData = null
var _revealed_ships: Array[ShipData] = []
var _ship_sheet_tex: Texture2D = SHIP_SHEET_TEX

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ship_sheet_tex = _make_transparent_ship_sheet()
	set_process(interactive)

	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.ship_sunk.connect(_on_ship_sunk)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.shot_fired.connect(_on_shot_fired)

func _draw() -> void:
	if board_state == null:
		return

	var board_tex := RADAR_GRID_TEX if is_enemy_grid else OCEAN_GRID_TEX
	draw_texture_rect(board_tex, Rect2(Vector2.ZERO, Vector2.ONE * BOARD_TEXTURE_SIZE), false)

	for data in board_state.ships:
		if not hide_ships:
			_draw_ship(data)

	for data in _revealed_ships:
		_draw_ship(data, Color(1.0, 0.78, 0.45, 1.0))

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell := Vector2i(col, row)
			var rect := Rect2(_cell_to_local(cell), Vector2.ONE * CELL_SIZE)
			var cell_state: BoardState.Cell = board_state.get_cell(cell)
			match cell_state:
				BoardState.Cell.HIT:
					_draw_token(TOKEN_HIT_REGION, rect)
				BoardState.Cell.MISS:
					_draw_token(TOKEN_MISS_REGION, rect)
				_:
					pass

	for data in _revealed_ships:
		var first_local := _cell_to_local(data.cells()[0])
		var last_cell := data.cells()[-1]
		var last_end := _cell_to_local(last_cell) + Vector2.ONE * CELL_SIZE
		draw_rect(Rect2(first_local, last_end - first_local), COL_SUNK, false, 2.0)

	if _ghost_ship != null:
		var is_valid := GameManager.can_place(_ghost_ship)
		var ghost_col := COL_GHOST_OK if is_valid else COL_GHOST_BAD
		for cell in _ghost_ship.cells():
			if _in_bounds(cell):
				draw_rect(Rect2(_cell_to_local(cell), Vector2.ONE * CELL_SIZE), ghost_col, true)
		_draw_ship(_ghost_ship, Color(1.0, 1.0, 1.0, 0.55))

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

func refresh() -> void:
	queue_redraw()

func set_ghost(data: ShipData) -> void:
	_ghost_ship = data
	queue_redraw()

func _on_turn_changed(new_state: GameManager.State) -> void:
	if is_enemy_grid:
		interactive = (new_state == GameManager.State.PLAYER_TURN)
		set_process(interactive)
	queue_redraw()

func _on_ship_sunk(data: ShipData, owner: String) -> void:
	if is_enemy_grid and owner == "ai":
		_revealed_ships.append(data)
	queue_redraw()

func _on_game_ended(_winner: String) -> void:
	interactive = false
	set_process(false)
	queue_redraw()

func _on_shot_fired(_cell: Vector2i, _result: Dictionary) -> void:
	queue_redraw()

func _cell_to_local(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	var local := to_local(world_pos) - GRID_ORIGIN
	return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE

func _draw_token(source: Rect2, cell_rect: Rect2) -> void:
	var offset := (CELL_SIZE - TOKEN_SIZE) * 0.5
	var dest := Rect2(cell_rect.position + Vector2.ONE * offset, Vector2.ONE * TOKEN_SIZE)
	draw_texture_rect_region(TOKENS_TEX, dest, source)

func _draw_ship(data: ShipData, tint: Color = Color.WHITE) -> void:
	var key := "%d_%s" % [data.size, "h" if data.horizontal else "v"]
	if not SHIP_REGIONS.has(key):
		for cell in data.cells():
			if _in_bounds(cell):
				draw_rect(Rect2(_cell_to_local(cell), Vector2.ONE * CELL_SIZE), COL_SHIP, true)
		return

	var dest_size := Vector2(
			CELL_SIZE * (data.size if data.horizontal else 1),
			CELL_SIZE * (1 if data.horizontal else data.size))
	var dest := Rect2(_cell_to_local(data.origin), dest_size)
	draw_texture_rect_region(_ship_sheet_tex, dest, SHIP_REGIONS[key], tint)

func _make_transparent_ship_sheet() -> Texture2D:
	var image := SHIP_SHEET_TEX.get_image()
	if image == null:
		return SHIP_SHEET_TEX
	if _has_transparency(image):
		return SHIP_SHEET_TEX
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.r > 0.96 and pixel.g > 0.96 and pixel.b > 0.96:
				image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 0.0))
	return ImageTexture.create_from_image(image)

func _has_transparency(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < 0.99:
				return true
	return false
