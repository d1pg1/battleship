extends Node

@onready var hit_player: AudioStreamPlayer = $HitPlayer
@onready var miss_player: AudioStreamPlayer = $MissPlayer
@onready var sunk_player: AudioStreamPlayer = $SunkPlayer
@onready var victory_player: AudioStreamPlayer = $VictoryPlayer
@onready var defeat_player: AudioStreamPlayer = $DefeatPlayer

func _ready() -> void:
	# This tells the AudioManager to listen for the signals 
	# that your GameManager is already broadcasting!
	GameManager.shot_fired.connect(_on_shot_fired)
	GameManager.ship_sunk.connect(_on_ship_sunk)
	GameManager.game_ended.connect(_on_game_ended)

func _on_shot_fired(_cell: Vector2i, result: Dictionary) -> void:
	# Play the right sound based on the shot result
	if result["result"] == BoardState.Cell.HIT:
		hit_player.play()
	elif result["result"] == BoardState.Cell.MISS:
		miss_player.play()

func _on_ship_sunk(_data: ShipData, _owner: String) -> void:
	# Plays the massive explosion sound when a whole ship goes down
	sunk_player.play()

func _on_game_ended(winner: String) -> void:
	# Check who won and play the fanfare
	if winner == "player":
		victory_player.play()
	else:
		defeat_player.play()
