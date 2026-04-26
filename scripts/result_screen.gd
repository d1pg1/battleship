class_name ResultScreen
extends Control

@onready var _result_label: Label    = $VBox/ResultLabel
@onready var _play_again_btn: Button = $VBox/PlayAgainButton
@onready var _menu_btn: Button       = $VBox/MenuButton

func _ready() -> void:
	_play_again_btn.pressed.connect(_on_play_again)
	_menu_btn.pressed.connect(_on_menu)
	_setup(GameManager.last_winner)

func _setup(winner: String) -> void:
	if GameManager.mode == GameManager.GameMode.AI_VS_AI:
		_result_label.text = "AI 1 WINS" if winner == "player1" else "AI 2 WINS"
		_result_label.modulate = Color(0.3, 1.0, 0.4)
		return
	if GameManager.mode == GameManager.GameMode.LOCAL_PVP:
		_result_label.text = "PLAYER 1 WINS" if winner == "player1" else "PLAYER 2 WINS"
		_result_label.modulate = Color(0.3, 1.0, 0.4)
		return
	if winner == "player":
		_result_label.text = "VICTORY"
		_result_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		_result_label.text = "DEFEAT"
		_result_label.modulate = Color(1.0, 0.3, 0.2)

func _on_play_again() -> void:
	GameManager.reset()
	if GameManager.mode == GameManager.GameMode.AI_VS_AI:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/battle_screen.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_menu() -> void:
	GameManager.reset()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
