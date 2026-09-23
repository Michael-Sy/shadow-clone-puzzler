class_name HumanInput
extends CharacterInputProvider


func get_input() -> CharacterInput:
	var input: CharacterInput = CharacterInput.new()
	
	input.move_direction = Input.get_axis("left", "right")
	input.jump_pressed = Input.is_action_just_pressed("jump")
	input.jump_held = Input.is_action_pressed("jump")
	
	return input
