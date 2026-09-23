class_name PlayerController
extends Node


var player: Player
var input_provider: CharacterInputProvider
var recording_manager: RecordingManager


func _ready() -> void:
	player = get_parent()
	
	input_provider = HumanInput.new()
	recording_manager = RecordingManager.new()
	
	recording_manager.start_recording()
	
	player.set_input(input_provider.get_input())


func _physics_process(_delta: float) -> void:
	var input: CharacterInputData = input_provider.get_input()
	
	player.set_input(input)
	
	if input_provider is HumanInput:
		recording_manager.record_input(input)
