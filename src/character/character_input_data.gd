class_name CharacterInputData
extends RefCounted


var move_direction: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false


func duplicate() -> CharacterInputData:
	var copy: CharacterInputData = CharacterInputData.new()
	
	copy.move_direction = move_direction
	copy.jump_pressed = jump_pressed
	copy.jump_held = jump_held
	
	return copy
