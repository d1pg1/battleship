class_name MainMenu
extends Control

@onready var _play_btn: Button = $VBox/PlayButton
@onready var _quit_btn: Button = $VBox/QuitButton

func _ready() -> void:
	_play_btn.pressed.connect(_on_play)
	_quit_btn.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/placement_screen.tscn")

func _on_quit() -> void:
	get_tree().quit()
