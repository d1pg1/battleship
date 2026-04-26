class_name BoardState
extends RefCounted

enum Cell { EMPTY = 0, SHIP = 1, HIT = 2, MISS = 3 }

const GRID_SIZE = 10

var _grid: Array = []
var ships: Array[ShipData] = []

func _init() -> void:
	reset()

func reset() -> void:
	_grid = []
	for _r in range(GRID_SIZE):
		var row: Array = []
		for _c in range(GRID_SIZE):
			row.append(Cell.EMPTY)
		_grid.append(row)
	ships = []

func get_cell(cell: Vector2i) -> Cell:
	return _grid[cell.y][cell.x]

func _set_cell(cell: Vector2i, value: Cell) -> void:
	_grid[cell.y][cell.x] = value

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE

func can_place(data: ShipData) -> bool:
	var ship_cells := data.cells()
	for cell in ship_cells:
		if not _in_bounds(cell):
			return false
		if _grid[cell.y][cell.x] == Cell.SHIP:
			return false
		# No adjacent ships allowed, including diagonals
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbor := cell + Vector2i(dx, dy)
				if not _in_bounds(neighbor):
					continue
				if neighbor in ship_cells:
					continue
				if _grid[neighbor.y][neighbor.x] == Cell.SHIP:
					return false
	return true

func place_ship(data: ShipData) -> bool:
	if not can_place(data):
		return false
	for cell in data.cells():
		_set_cell(cell, Cell.SHIP)
	data.is_placed = true
	ships.append(data)
	return true

func remove_ship(data: ShipData) -> void:
	for cell in data.cells():
		_set_cell(cell, Cell.EMPTY)
	data.is_placed = false
	data.hit_count = 0
	ships.erase(data)

func fire(cell: Vector2i) -> Dictionary:
	var result := { "result": Cell.MISS, "sunk_ship": null }
	if _grid[cell.y][cell.x] == Cell.SHIP:
		_set_cell(cell, Cell.HIT)
		result["result"] = Cell.HIT
		for ship in ships:
			if cell in ship.cells():
				ship.hit_count += 1
				if ship.is_sunk():
					result["sunk_ship"] = ship
				break
	else:
		_set_cell(cell, Cell.MISS)
	return result

func all_sunk() -> bool:
	for ship in ships:
		if not ship.is_sunk():
			return false
	return ships.size() > 0

func reveal_surroundings(data: ShipData) -> Array[Vector2i]:
	var revealed: Array[Vector2i] = []
	for cell in data.cells():
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var neighbor := cell + Vector2i(dx, dy)
				if not _in_bounds(neighbor):
					continue
				if _grid[neighbor.y][neighbor.x] == Cell.EMPTY:
					_set_cell(neighbor, Cell.MISS)
					if not (neighbor in revealed):
						revealed.append(neighbor)
	return revealed

func is_already_fired(cell: Vector2i) -> bool:
	var state = _grid[cell.y][cell.x]
	return state == Cell.HIT or state == Cell.MISS

func random_place_all(fleet_defs: Array) -> void:
	# Remove any already-placed ships first
	for ship in ships.duplicate():
		remove_ship(ship)
	ships = []

	for def in fleet_defs:
		var data := ShipData.new()
		data.ship_name = def["name"]
		data.size = def["size"]

		var placed := false
		var attempts := 0
		while not placed and attempts < 10000:
			attempts += 1
			data.horizontal = (randi() % 2) == 0
			var max_x := GRID_SIZE - (data.size if data.horizontal else 1)
			var max_y := GRID_SIZE - (1 if data.horizontal else data.size)
			data.origin = Vector2i(randi() % (max_x + 1), randi() % (max_y + 1))
			if can_place(data):
				place_ship(data)
				placed = true

		if not placed:
			push_error("BoardState: could not place ship '%s' after 10000 attempts" % def["name"])
