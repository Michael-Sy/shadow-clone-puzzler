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
	if not recording:
		return
	
	recording.add_input(input)


func get_recording() -> Recording:
	return recording
