class_name ShipData
extends Resource

@export var ship_name: String = ""
@export var size: int = 0
@export var origin: Vector2i = Vector2i.ZERO
@export var horizontal: bool = true
var hit_count: int = 0
var is_placed: bool = false

func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for i in range(size):
		if horizontal:
			result.append(Vector2i(origin.x + i, origin.y))
		else:
			result.append(Vector2i(origin.x, origin.y + i))
	return result

func is_sunk() -> bool:
	return hit_count >= size

func reset() -> void:
	hit_count = 0
	is_placed = false
	origin = Vector2i.ZERO
	horizontal = true
