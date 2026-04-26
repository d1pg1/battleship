class_name DifficultyMenu
extends Control

@onready var _easy_btn: Button = $VBox/EasyButton
@onready var _medium_btn: Button = $VBox/MediumButton
@onready var _hard_btn: Button = $VBox/HardButton
@onready var _impossible_btn: Button = $VBox/ImpossibleButton
@onready var _back_btn: Button = $VBox/BackButton

func _ready() -> void:
	_easy_btn.pressed.connect(func(): _start(GameManager.AIDifficulty.EASY))
	_medium_btn.pressed.connect(func(): _start(GameManager.AIDifficulty.MEDIUM))
	_hard_btn.pressed.connect(func(): _start(GameManager.AIDifficulty.HARD))
	_impossible_btn.pressed.connect(func(): _start(GameManager.AIDifficulty.IMPOSSIBLE))
	_back_btn.pressed.connect(_on_back)

func _start(difficulty: int) -> void:
	GameManager.start_vs_ai_game(difficulty)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_back() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
