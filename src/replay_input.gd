class_name Replayinput
extends CharacterInputProvider


var recorded_inputs: Array[CharacterInput] = []
var current_index: int = 0


func get_input() -> CharacterInput:
	if current_index >= recorded_inputs.size():
		return CharacterInput.new()
	
	var input: CharacterInput = recorded_inputs[current_index]
	current_index += 1
	
	return input
