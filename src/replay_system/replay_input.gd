class_name ReplayInput
extends CharacterInputProvider


var recording: Recording
var current_index: int = 0
var spawn_events: Array[int] = []


func _init(recording_in_play: Recording) -> void:
	recording = recording_in_play
	spawn_events = recording.spawn_events


func get_input() -> CharacterInputData:
	if current_index >= recording.get_length():
		return CharacterInputData.new()
	
	var input: CharacterInputData = recording.get_input(current_index)
	current_index += 1
	
	return input


func has_spawn_event() -> bool:
	return current_index in spawn_events


func is_finished() -> bool:
	return current_index >= recording.get_length()


func reset() -> void:
	current_index = 0
