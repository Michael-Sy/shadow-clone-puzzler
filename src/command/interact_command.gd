class_name InteractCommand
extends Command


func execute(controller: CharacterController) -> void:
	var character := controller.player
	for node in controller.get_tree().get_nodes_in_group("interactable"):
		if node.can_interact(character):
			node.interact(character)
			return
