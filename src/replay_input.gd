class_name ReplayInput
extends CharacterInputProvider


var recording: Recording
var current_index: int = 0


func _init(recording_in_play: Recording) -> void:
	recording = recording_in_play


func get_input() -> CharacterInputData:
	if current_index >= recording.get_length():
		return CharacterInputData.new()
	
	var input: CharacterInputData = recording.get_input(current_index)
	current_index += 1
	
	return input


func reset() -> void:
	current_index = 0
