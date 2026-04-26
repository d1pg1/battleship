class_name MainMenu
extends Control

@onready var _vs_ai_btn: Button = $VBox/VsAIButton
@onready var _campaign_btn: Button = $VBox/CampaignButton
@onready var _local_pvp_btn: Button = $VBox/LocalPvpButton
@onready var _ai_vs_ai_btn: Button = $VBox/AIVsAIButton
@onready var _quit_btn: Button = $VBox/QuitButton

func _ready() -> void:
	_vs_ai_btn.pressed.connect(_on_vs_ai)
	_campaign_btn.pressed.connect(_on_campaign)
	_local_pvp_btn.pressed.connect(_on_local_pvp)
	_ai_vs_ai_btn.pressed.connect(_on_ai_vs_ai)
	_quit_btn.pressed.connect(_on_quit)

func _on_vs_ai() -> void:
	GameManager.start_new_game(GameManager.GameMode.VS_AI)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_campaign() -> void:
	GameManager.start_campaign()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_local_pvp() -> void:
	GameManager.start_new_game(GameManager.GameMode.LOCAL_PVP)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_ai_vs_ai() -> void:
	GameManager.start_new_game(GameManager.GameMode.AI_VS_AI)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/battle_screen.tscn")

func _on_quit() -> void:
	get_tree().quit()
