class_name Recording
extends RefCounted


var inputs: Array[CharacterInputData] = []


func add_input(input: CharacterInputData) -> void:
	inputs.append(input.duplicate())


func clear() -> void:
	inputs.clear()


func get_input(index: int) -> CharacterInputData:
	return inputs[index]


func get_length() -> int:
	return inputs.size()
