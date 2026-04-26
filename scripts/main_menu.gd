class_name MainMenu
extends Control

@onready var _vs_ai_btn: Button = $VBox/VsAIButton
@onready var _campaign_btn: Button = $VBox/CampaignButton
@onready var _local_pvp_btn: Button = $VBox/LocalPvpButton
@onready var _ai_vs_ai_btn: Button = $VBox/AIVsAIButton
@onready var _quit_btn: Button = $VBox/QuitButton
@onready var _campaign_prompt: Control = $CampaignPrompt
@onready var _prompt_title: Label = $CampaignPrompt/Panel/VBox/PromptTitle
@onready var _prompt_detail: Label = $CampaignPrompt/Panel/VBox/PromptDetail
@onready var _continue_btn: Button = $CampaignPrompt/Panel/VBox/ContinueButton
@onready var _new_campaign_btn: Button = $CampaignPrompt/Panel/VBox/NewCampaignButton
@onready var _prompt_cancel_btn: Button = $CampaignPrompt/Panel/VBox/CancelButton
@onready var _name_prompt: Control = $NamePrompt
@onready var _name_edit: LineEdit = $NamePrompt/Panel/VBox/NameEdit
@onready var _start_campaign_btn: Button = $NamePrompt/Panel/VBox/StartButton
@onready var _name_cancel_btn: Button = $NamePrompt/Panel/VBox/CancelButton

func _ready() -> void:
	ButtonStyle.apply_all($VBox, 30, 84)
	_vs_ai_btn.pressed.connect(_on_vs_ai)
	_campaign_btn.pressed.connect(_on_campaign)
	_local_pvp_btn.pressed.connect(_on_local_pvp)
	_ai_vs_ai_btn.pressed.connect(_on_ai_vs_ai)
	_quit_btn.pressed.connect(_on_quit)
	_continue_btn.pressed.connect(_on_continue_campaign)
	_new_campaign_btn.pressed.connect(_on_new_campaign)
	_prompt_cancel_btn.pressed.connect(_hide_campaign_prompts)
	_start_campaign_btn.pressed.connect(_on_start_named_campaign)
	_name_cancel_btn.pressed.connect(_hide_campaign_prompts)
	_name_edit.text_submitted.connect(_on_name_submitted)

func _on_vs_ai() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/difficulty_menu.tscn")

func _on_campaign() -> void:
	if GameManager.has_campaign_progress():
		_show_continue_prompt()
	else:
		_show_name_prompt()

func _on_local_pvp() -> void:
	GameManager.start_new_game(GameManager.GameMode.LOCAL_PVP)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_ai_vs_ai() -> void:
	GameManager.start_new_game(GameManager.GameMode.AI_VS_AI)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/battle_screen.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _show_continue_prompt() -> void:
	_name_prompt.visible = false
	_prompt_title.text = "CAMPAIGN IN PROGRESS"
	_prompt_detail.text = "%s is at %s." % [GameManager.campaign_player_name, GameManager.campaign_title()]
	_campaign_prompt.visible = true

func _show_name_prompt() -> void:
	_campaign_prompt.visible = false
	_name_edit.text = GameManager.campaign_player_name
	_name_prompt.visible = true
	_name_edit.grab_focus()
	_name_edit.select_all()

func _hide_campaign_prompts() -> void:
	_campaign_prompt.visible = false
	_name_prompt.visible = false

func _on_continue_campaign() -> void:
	GameManager.continue_campaign()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_new_campaign() -> void:
	_show_name_prompt()

func _on_start_named_campaign() -> void:
	GameManager.start_campaign(_name_edit.text)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_name_submitted(_text: String) -> void:
	_on_start_named_campaign()
