class_name PlacementController
extends Node

const FLEET := [
	{ "name": "Battleship",  "size": 4 },
	{ "name": "Cruiser 1",   "size": 3 },
	{ "name": "Cruiser 2",   "size": 3 },
	{ "name": "Destroyer 1", "size": 2 },
	{ "name": "Destroyer 2", "size": 2 },
	{ "name": "Destroyer 3", "size": 2 },
	{ "name": "Patrol 1",    "size": 1 },
	{ "name": "Patrol 2",    "size": 1 },
	{ "name": "Patrol 3",    "size": 1 },
	{ "name": "Patrol 4",    "size": 1 },
]

@onready var _player_grid: GridDisplay = $"../PlayerGridDisplay"
@onready var _ship_list: VBoxContainer = $"../Sidebar/VLayout/ShipList"
@onready var _title_label: Label       = $"../Sidebar/VLayout/TitleLabel"
@onready var _instruct_label: Label    = $"../Sidebar/VLayout/InstructLabel"
@onready var _rotate_btn: Button       = $"../Sidebar/VLayout/RotateButton"
@onready var _random_btn: Button       = $"../Sidebar/VLayout/RandomButton"
@onready var _start_btn: Button        = $"../Sidebar/VLayout/StartButton"
@onready var _dialogue_overlay: Control = $"../UILayer/DialogueOverlay"
@onready var _portrait_rect: ColorRect = $"../UILayer/DialogueOverlay/Panel/VBox/DialogueRow/PortraitPanel/PortraitColor"
@onready var _portrait_initials: Label = $"../UILayer/DialogueOverlay/Panel/VBox/DialogueRow/PortraitPanel/PortraitInitials"
@onready var _dialogue_title: Label = $"../UILayer/DialogueOverlay/Panel/VBox/TitleLabel"
@onready var _speaker_label: Label = $"../UILayer/DialogueOverlay/Panel/VBox/DialogueRow/TextBox/SpeakerLabel"
@onready var _dialogue_label: Label = $"../UILayer/DialogueOverlay/Panel/VBox/DialogueRow/TextBox/DialogueLabel"
@onready var _dialogue_btn: Button = $"../UILayer/DialogueOverlay/Panel/VBox/ContinueButton"

var _fleet_data: Array[ShipData] = []
var _ship_buttons: Array[Button] = []
var _selected: ShipData = null
var _horizontal: bool = true
var _placing_player: int = 1
var _campaign_dialogue: Array = []
var _dialogue_index := 0

func _ready() -> void:
	GameManager.reset()
	_player_grid.interactive = true
	_player_grid.hide_ships = false
	_player_grid.is_enemy_grid = false

	_begin_placement_for_player(1)

	_rotate_btn.pressed.connect(_on_rotate_pressed)
	_random_btn.pressed.connect(_on_random_pressed)
	_start_btn.pressed.connect(_on_start_pressed)
	_player_grid.cell_tapped.connect(_on_grid_cell_tapped)
	_dialogue_btn.pressed.connect(_on_dialogue_continue_pressed)

	if GameManager.mode == GameManager.GameMode.CAMPAIGN:
		_show_campaign_dialogue()

func _begin_placement_for_player(player_number: int) -> void:
	_placing_player = player_number
	_selected = null
	_horizontal = true
	_fleet_data = []
	_ship_buttons = []
	for child in _ship_list.get_children():
		_ship_list.remove_child(child)
		child.queue_free()

	if GameManager.mode == GameManager.GameMode.LOCAL_PVP:
		_title_label.text = "PLAYER %d: PLACE FLEET" % _placing_player
		_instruct_label.text = "Select a ship, then click the grid to place it."
	elif GameManager.mode == GameManager.GameMode.CAMPAIGN:
		_title_label.text = "%s: PLACE FLEET" % GameManager.campaign_title().to_upper()
		if GameManager.campaign_is_tutorial():
			_instruct_label.text = "Tutorial: choose a ship, rotate with R if needed, then place it on the grid. Ships cannot touch, even diagonally. Use RANDOM PLACEMENT if you want to start quickly."
		else:
			_instruct_label.text = "Place your fleet before facing %s." % GameManager.campaign_opponent_name()
	else:
		_title_label.text = "PLACE YOUR FLEET"
		_instruct_label.text = "Select a ship, then click the grid to place it."
	if _placing_player == 2 or GameManager.mode in [GameManager.GameMode.VS_AI, GameManager.GameMode.CAMPAIGN]:
		_start_btn.text = "START BATTLE"
	else:
		_start_btn.text = "NEXT PLAYER"
	_player_grid.placement_player_number = _placing_player
	_player_grid.set_ghost(null)
	_player_grid.set_board_state(GameManager.placement_board(_placing_player))

	for def in FLEET:
		var data := ShipData.new()
		data.ship_name = def["name"]
		data.size = def["size"]
		_fleet_data.append(data)

		var btn := Button.new()
		btn.text = "%s (%d)" % [def["name"], def["size"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Capture data in closure
		var captured := data
		btn.pressed.connect(func(): _on_ship_button_pressed(captured))
		_ship_list.add_child(btn)
		_ship_buttons.append(btn)

	_update_start_button()

func _on_ship_button_pressed(data: ShipData) -> void:
	# If already placed, unplace it first
	if data.is_placed:
		GameManager.remove_ship(data, _placing_player)
		_player_grid.refresh()
		_update_button_style(data, false)

	# Select this ship to place
	_selected = data
	_update_ghost()

func _on_rotate_pressed() -> void:
	_horizontal = not _horizontal
	if _selected != null:
		_selected.horizontal = _horizontal
		_update_ghost()

func _on_grid_cell_tapped(cell: Vector2i) -> void:
	if _selected == null:
		return
	_selected.origin = cell
	_selected.horizontal = _horizontal
	if GameManager.place_ship(_selected, _placing_player):
		_update_button_style(_selected, true)
		_player_grid.set_ghost(null)
		_player_grid.refresh()
		_selected = null
		_update_start_button()
	else:
		# Invalid placement — keep ghost visible (already shown in grid _draw)
		pass

func _on_random_pressed() -> void:
	# Remove all currently placed ships and reset their state
	for data in _fleet_data:
		if data.is_placed:
			GameManager.remove_ship(data, _placing_player)
		data.hit_count = 0
		data.is_placed = false

	_selected = null
	_player_grid.set_ghost(null)

	# Place each existing ShipData object randomly (keeps UI references intact)
	for data in _fleet_data:
		var placed := false
		var attempts := 0
		while not placed and attempts < 10000:
			attempts += 1
			data.horizontal = (randi() % 2) == 0
			var max_x := BoardState.GRID_SIZE - (data.size if data.horizontal else 1)
			var max_y := BoardState.GRID_SIZE - (1 if data.horizontal else data.size)
			data.origin = Vector2i(randi() % (max_x + 1), randi() % (max_y + 1))
			if GameManager.place_ship(data, _placing_player):
				placed = true
		if not placed:
			push_error("PlacementController: could not randomly place " + data.ship_name)

	for data in _fleet_data:
		_update_button_style(data, data.is_placed)

	_player_grid.refresh()
	_update_start_button()

func _on_start_pressed() -> void:
	_player_grid.set_ghost(null)
	if GameManager.mode == GameManager.GameMode.LOCAL_PVP and _placing_player == 1:
		_begin_placement_for_player(2)
		return
	get_tree().call_deferred("change_scene_to_file", "res://scenes/battle_screen.tscn")

func _show_campaign_dialogue() -> void:
	_campaign_dialogue = GameManager.campaign_dialogue()
	_dialogue_index = 0
	_dialogue_title.text = "%s - %s" % [GameManager.campaign_title().to_upper(), GameManager.campaign_level()["theme"]]
	_portrait_rect.color = GameManager.campaign_portrait_color()
	_portrait_initials.text = _initials(GameManager.campaign_opponent_name())
	_dialogue_overlay.visible = true
	_player_grid.interactive = false
	_player_grid.set_process(false)
	_rotate_btn.disabled = true
	_random_btn.disabled = true
	_start_btn.disabled = true
	_show_dialogue_line()

func _show_dialogue_line() -> void:
	if _dialogue_index >= _campaign_dialogue.size():
		_dialogue_overlay.visible = false
		_player_grid.interactive = true
		_player_grid.set_process(true)
		_rotate_btn.disabled = false
		_random_btn.disabled = false
		_update_start_button()
		return
	var line: Dictionary = _campaign_dialogue[_dialogue_index] as Dictionary
	var raw_speaker: String = line["speaker"]
	var is_player_line: bool = raw_speaker == "{player}"
	_speaker_label.text = GameManager.campaign_display_text(raw_speaker)
	_dialogue_label.text = GameManager.campaign_display_text(line["text"])
	if is_player_line:
		_portrait_rect.color = GameManager.campaign_player_portrait_color()
		_portrait_initials.text = _initials(GameManager.campaign_player_name)
	else:
		_portrait_rect.color = GameManager.campaign_portrait_color()
		_portrait_initials.text = _initials(GameManager.campaign_opponent_name())
	_dialogue_btn.text = "PLACE FLEET" if _dialogue_index == _campaign_dialogue.size() - 1 else "CONTINUE"

func _on_dialogue_continue_pressed() -> void:
	_dialogue_index += 1
	_show_dialogue_line()

func _initials(text: String) -> String:
	var words := text.split(" ", false)
	var result := ""
	for word in words:
		result += word.substr(0, 1).to_upper()
		if result.length() >= 2:
			break
	return result

func _update_ghost() -> void:
	if _selected == null:
		_player_grid.set_ghost(null)
		return
	_selected.horizontal = _horizontal
	_player_grid.set_ghost(_selected)

func _update_button_style(data: ShipData, placed: bool) -> void:
	var idx := _fleet_data.find(data)
	if idx < 0:
		return
	var btn := _ship_buttons[idx]
	btn.modulate.a = 0.45 if placed else 1.0

func _update_start_button() -> void:
	# Count ships actually placed on board
	var placed_count := GameManager.placement_board(_placing_player).ships.size()
	_start_btn.disabled = (placed_count < FLEET.size())

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_rotate_pressed()

func _process(_delta: float) -> void:
	# Update ghost origin to follow mouse hover on the grid
	if _selected == null:
		return
	var hover := _player_grid._world_to_cell(get_viewport().get_mouse_position())
	if hover != _selected.origin:
		_selected.origin = hover
		_player_grid.queue_redraw()
