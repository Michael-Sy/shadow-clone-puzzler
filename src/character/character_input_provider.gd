@abstract
class_name CharacterInputProvider
extends RefCounted


@abstract
func get_input() -> CharacterInputData


func get_ready_commands() -> Array[Command]:
	return []


func is_finished() -> bool:
	return false
