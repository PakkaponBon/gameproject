extends Control
## Title screen: new game / load / quit. The .md files call it Ashfall.

func _ready() -> void:
	theme = UiTheme.get_theme()
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
	%ScenarioButton.pressed.connect(func() -> void:
		var order: Array = ScenarioDefs.ORDER
		var next := (order.find(ScenarioDefs.selected) + 1) % order.size()
		ScenarioDefs.selected = order[next]
		_update_scenario())
	%LoadGameButton.disabled = not FileAccess.file_exists(SaveManager.MANUAL_SAVE_PATH)
	_update_difficulty()
	_update_scenario()

func _update_difficulty() -> void:
	%DifficultyButton.text = "Difficulty: %s" % Balance.mode

func _update_scenario() -> void:
	var def := ScenarioDefs.current()
	%ScenarioButton.text = "Scenario: %s" % def.name
	%ScenarioBlurb.text = String(def.blurb)
