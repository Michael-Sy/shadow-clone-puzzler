class_name BecomePlatformCommand
extends Command


func execute(controller: CharacterController) -> void:
	controller.player.become_platform()
