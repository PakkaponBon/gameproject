class_name PauseMenu
extends CanvasLayer
## Esc toggles the menu and pauses the simulation (GameClock's timer
## inherits pause). Runs in ALWAYS mode so it still gets input while paused.

signal save_requested
signal load_requested(path: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%ResumeButton.pressed.connect(toggle)
	%SaveButton.pressed.connect(_on_save)
	%LoadButton.pressed.connect(func() -> void: load_requested.emit(SaveManager.MANUAL_SAVE_PATH))
	%LoadAutosaveButton.pressed.connect(func() -> void: load_requested.emit(SaveManager.AUTOSAVE_PATH))
	%FullscreenButton.pressed.connect(func() -> void:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs
				else DisplayServer.WINDOW_MODE_FULLSCREEN))
	%VolumeSlider.value_changed.connect(func(value: float) -> void:
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.001))))
	%MenuButton.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	%QuitButton.pressed.connect(func() -> void: get_tree().quit())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()

func toggle() -> void:
	visible = not visible
	get_tree().paused = visible

func _on_save() -> void:
	save_requested.emit()
	toggle()
