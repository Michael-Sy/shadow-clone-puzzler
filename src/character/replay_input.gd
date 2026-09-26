class_name ReplayInput
extends CharacterInputProvider


var recording: Recording
var current_index: int = 0
var current_command_index: int = 0


func _init(recording_to_play: Recording) -> void:
	recording = recording_to_play


func get_input() -> CharacterInputData:
	if current_index >= recording.get_length():
		return CharacterInputData.new()

	var input := recording.get_input(current_index)
	current_index += 1
	return input


func get_ready_commands() -> Array[Command]:
	var ready: Array[Command] = []
	while current_command_index < recording.commands.size() \
			and recording.get_command(current_command_index).frame <= current_index:
		ready.append(recording.get_command(current_command_index))
		current_command_index += 1
	return ready


func is_finished() -> bool:
	return current_index >= recording.get_length() \
		and current_command_index >= recording.commands.size()


func reset() -> void:
	current_index = 0
	current_command_index = 0
