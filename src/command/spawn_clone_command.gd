class_name SpawnCloneCommand
extends Command


var position: Vector2
var velocity: Vector2
var clone: Character


func execute(_controller: CharacterController) -> void:
	if not is_instance_valid(clone):
		return
	clone.controller.begin_replay(position, velocity)
