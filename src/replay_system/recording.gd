class_name Recording
extends RefCounted


var inputs: Array[CharacterInputData] = []
var commands: Array[Command] =[]


func add_input(input: CharacterInputData) -> void:
	inputs.append(input.duplicate())


func add_command(command: Command) -> void:
	commands.append(command)


func clear() -> void:
	inputs.clear()
	commands.clear()


func get_input(index: int) -> CharacterInputData:
	return inputs[index]


func get_command(index: int) -> Command:
	return commands[index]


func get_length() -> int:
	return inputs.size()
