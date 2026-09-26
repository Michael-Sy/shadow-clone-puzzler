class_name RecordingManager
extends RefCounted


var recording: Recording
var is_recording: bool = false


func _init() -> void:
	recording = Recording.new()


func start_recording() -> void:
	recording.clear()
	is_recording = true


func stop_recording() -> void:
	is_recording = false


func record_input(input: CharacterInputData) -> void:
	if not is_recording:
		return
	recording.add_input(input)


func record_command(command: Command) -> void:
	if not is_recording:
		return
	
	command.frame = recording.get_length()
	recording.add_command(command)


func get_recording() -> Recording:
	return recording


func clear_recording() -> void:
	recording.clear()
