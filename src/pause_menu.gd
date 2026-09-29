class_name PauseMenu
extends CanvasLayer


@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton

var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(GameManager.restart_chamber)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = _was_paused
