extends Control
## Title screen: new game / load / quit. The .md files call it Ashfall.

func _ready() -> void:
	%NewGameButton.pressed.connect(func() -> void:
		SaveManager.pending_load = {}
		get_tree().change_scene_to_file("res://scenes/main.tscn"))
	%LoadGameButton.pressed.connect(func() -> void:
		SaveManager.load_game(SaveManager.MANUAL_SAVE_PATH))
	%QuitButton.pressed.connect(func() -> void: get_tree().quit())
	%DifficultyButton.pressed.connect(func() -> void:
		var next := (Balance.MODES.find(Balance.mode) + 1) % Balance.MODES.size()
		Balance.mode = Balance.MODES[next]
		_update_difficulty())
	%LoadGameButton.disabled = not FileAccess.file_exists(SaveManager.MANUAL_SAVE_PATH)
	_update_difficulty()

func _update_difficulty() -> void:
	%DifficultyButton.text = "Difficulty: %s" % Balance.mode
