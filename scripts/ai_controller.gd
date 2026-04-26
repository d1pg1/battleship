class_name AIController
extends Node

enum AIState { HUNT, TARGET }
enum Profile { RANDOM, HARE, WOLF }

var _mode: AIState = AIState.HUNT
var _profile: Profile = Profile.WOLF
var _fired: Array[Vector2i] = []
var _hit_queue: Array[Vector2i] = []
var _hit_run: Array[Vector2i] = []
var _locked_axis: int = -1  # -1=none, 0=horizontal, 1=vertical

func configure_profile(profile_name: String) -> void:
	match profile_name:
		"random":
			_profile = Profile.RANDOM
		"hare":
			_profile = Profile.HARE
		_:
			_profile = Profile.WOLF
	reset()

func add_to_fired(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if not (cell in _fired):
			_fired.append(cell)

func reset() -> void:
	_mode = AIState.HUNT
	_fired = []
	_hit_queue = []
	_hit_run = []
	_locked_axis = -1

func choose_cell() -> Vector2i:
	var cell: Vector2i
	match _profile:
		Profile.RANDOM:
			cell = _random_unfired()
		Profile.HARE:
			cell = _random_unfired()
		_:
			if _mode == AIState.HUNT:
				cell = _hunt()
			else:
				cell = _target()
	_fired.append(cell)
	return cell

func on_fire_result(cell: Vector2i, result: Dictionary) -> void:
	if _profile != Profile.WOLF:
		return
	if result["result"] == BoardState.Cell.HIT:
		_hit_run.append(cell)

		if _mode == AIState.HUNT:
			_mode = AIState.TARGET
			_locked_axis = -1
			_enqueue_orthogonal(cell)
		elif _mode == AIState.TARGET:
			if _locked_axis == -1 and _hit_run.size() >= 2:
				var delta := _hit_run[-1] - _hit_run[-2]
				_locked_axis = 0 if delta.x != 0 else 1
				_hit_queue.clear()
				_enqueue_axial()
			else:
				_enqueue_axial()

	# Sunk — reset targeting state entirely
	if result["sunk_ship"] != null:
		_reset_target()

func _hunt() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for row in range(10):
		for col in range(10):
			var cell := Vector2i(col, row)
			if (row + col) % 2 == 0 and not (cell in _fired):
				candidates.append(cell)

	# Fallback when checkerboard is exhausted
	if candidates.is_empty():
		for row in range(10):
			for col in range(10):
				var cell := Vector2i(col, row)
				if not (cell in _fired):
					candidates.append(cell)

	candidates.shuffle()
	return candidates[0]

func _random_unfired() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for row in range(10):
		for col in range(10):
			var cell := Vector2i(col, row)
			if not (cell in _fired):
				candidates.append(cell)
	candidates.shuffle()
	return candidates[0]

func _target() -> Vector2i:
	while not _hit_queue.is_empty():
		var candidate: Vector2i = _hit_queue.pop_front()
		if _is_valid(candidate):
			return candidate
	_reset_target()
	return _hunt()

func _enqueue_orthogonal(cell: Vector2i) -> void:
	for delta: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbour: Vector2i = cell + delta
		if _is_valid(neighbour) and not (neighbour in _hit_queue):
			_hit_queue.append(neighbour)

func _enqueue_axial() -> void:
	if _locked_axis == 0:  # horizontal
		var xs: Array[int] = []
		for c in _hit_run:
			xs.append(c.x)
		var min_x: int = xs.min()
		var max_x: int = xs.max()
		var row: int = _hit_run[0].y
		_try_enqueue(Vector2i(max_x + 1, row))
		_try_enqueue(Vector2i(min_x - 1, row))
	else:  # vertical
		var ys: Array[int] = []
		for c in _hit_run:
			ys.append(c.y)
		var min_y: int = ys.min()
		var max_y: int = ys.max()
		var col: int = _hit_run[0].x
		_try_enqueue(Vector2i(col, max_y + 1))
		_try_enqueue(Vector2i(col, min_y - 1))

func _try_enqueue(cell: Vector2i) -> void:
	if _is_valid(cell) and not (cell in _hit_queue):
		_hit_queue.append(cell)

func _is_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < 10 and cell.y >= 0 and cell.y < 10 \
			and not (cell in _fired)

func _reset_target() -> void:
	_mode = AIState.HUNT
	_hit_queue = []
	_hit_run = []
	_locked_axis = -1
