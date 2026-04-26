class_name HUD
extends Control

@onready var _turn_label: Label    = $TurnLabel
@onready var _feedback_label: Label = $FeedbackLabel
@onready var _sunk_label: Label    = $SunkLabel

var _feedback_timer: Timer
var _sunk_timer: Timer

func _ready() -> void:
	_feedback_timer = Timer.new()
	_feedback_timer.one_shot = true
	_feedback_timer.wait_time = 1.5
	_feedback_timer.timeout.connect(func(): _feedback_label.text = "")
	add_child(_feedback_timer)

	_sunk_timer = Timer.new()
	_sunk_timer.one_shot = true
	_sunk_timer.wait_time = 2.0
	_sunk_timer.timeout.connect(func(): _sunk_label.text = "")
	add_child(_sunk_timer)

	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.shot_fired.connect(_on_shot_fired)
	GameManager.ship_sunk.connect(_on_ship_sunk)
	GameManager.game_ended.connect(_on_game_ended)

	_turn_label.text = "YOUR TURN"
	_feedback_label.text = ""
	_sunk_label.text = ""

func _on_turn_changed(new_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.PLAYER_TURN:
			if GameManager.mode == GameManager.GameMode.LOCAL_PVP:
				_turn_label.text = GameManager.active_player_label() + " TURN"
			else:
				_turn_label.text = "YOUR TURN"
		GameManager.State.AI_TURN:
			_turn_label.text = "ENEMY FIRING..."
		GameManager.State.HANDOFF:
			_turn_label.text = ""
		GameManager.State.GAME_OVER:
			_turn_label.text = ""

func _on_shot_fired(_cell: Vector2i, result: Dictionary) -> void:
	if result["result"] == BoardState.Cell.HIT:
		_feedback_label.text = "HIT!"
		_feedback_label.modulate = Color(1.0, 0.3, 0.2)
	else:
		_feedback_label.text = "MISS"
		_feedback_label.modulate = Color(0.85, 0.85, 0.95)
	_feedback_timer.start()

func _on_ship_sunk(data: ShipData, _owner: String) -> void:
	_sunk_label.text = "%s SUNK!" % data.ship_name.to_upper()
	_sunk_timer.start()

func _on_game_ended(_winner: String) -> void:
	_turn_label.text = ""
	_feedback_label.text = ""
