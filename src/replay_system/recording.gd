class_name Recording
extends RefCounted


var inputs: Array[CharacterInputData] = []
var spawn_events: Array[int] =[]


func add_input(input: CharacterInputData) -> void:
	inputs.append(input.duplicate())


func add_spawn_event() -> void:
	spawn_events.append(inputs.size())


func clear() -> void:
	inputs.clear()
	spawn_events.clear()


func get_input(index: int) -> CharacterInputData:
	return inputs[index]


func get_length() -> int:
	return inputs.size()
