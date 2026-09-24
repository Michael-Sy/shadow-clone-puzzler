class_name CharacterController
extends Node


signal action_performed
signal spawn_event_reached(player: Character)
signal replay_finished(player: Character)

var is_active: bool = true
var is_recording: bool = false
var player: Character
var input_provider: CharacterInputProvider
var recording_manager: RecordingManager
var recording_start_position: Vector2


func _ready() -> void:
	player = get_parent()
	
	input_provider = HumanInput.new()
	recording_manager = RecordingManager.new()
	
	player.set_input(input_provider.get_input())


func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	
	var input: CharacterInputData = input_provider.get_input()
	
	if input_provider is ReplayInput:
		if input_provider.has_spawn_event():
			spawn_event_reached.emit(player)
		
		if input_provider.is_finished():
			replay_finished.emit(player)
	
	player.set_input(input)
	
	if not is_recording:
		if input.move_direction != 0.0 or input.jump_pressed or player.velocity.y != 0.0:
			action_performed.emit()
	
	if is_recording:
		recording_manager.record_input(input)


func start_recording() -> void:
	recording_start_position = player.global_position
	input_provider = HumanInput.new()
	recording_manager.start_recording()
	is_recording = true


func stop_recording() -> void:
	recording_manager.stop_recording()
	is_recording = false


func play_recording() -> void:
	input_provider = ReplayInput.new(recording_manager.get_recording())


func clear_recording() -> void:
	recording_manager.clear_recording()


func get_recording() -> Recording:
	return recording_manager.get_recording()


func activate() -> void:
	is_active = true


func deactivate() -> void:
	is_active = false


func set_human_control() -> void:
	input_provider = HumanInput.new()
	is_recording = false


func set_replay(recording: Recording) -> void:
	input_provider = ReplayInput.new(recording)
	is_recording = false
