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
