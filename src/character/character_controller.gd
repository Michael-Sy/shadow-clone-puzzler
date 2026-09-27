class_name CharacterController
extends Node


signal replay_finished(character: Character)

var is_active: bool = true
var is_recording: bool = false
var player: Character
var input_provider: CharacterInputProvider
var recording_manager: RecordingManager
var recording_start_position: Vector2
var recording_start_velocity: Vector2

var _queued_commands: Array[Command] = []


func _ready() -> void:
	player = get_parent() as Character
	input_provider = HumanInput.new()
	recording_manager = RecordingManager.new()


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	for command in input_provider.get_ready_commands():
		command.execute(self)
	
	for command in _queued_commands:
		recording_manager.record_command(command)
		command.execute(self)
	_queued_commands.clear()
	
	var input := input_provider.get_input()
	player.tick(input, delta)
	
	if is_recording:
		recording_manager.record_input(input)
	
	if input_provider.is_finished():
		replay_finished.emit(player)


func queue_command(command: Command) -> void:
	_queued_commands.append(command)


func start_recording() -> void:
	recording_start_position = player.global_position
	recording_start_velocity = player.velocity
	input_provider = HumanInput.new()
	recording_manager.start_recording()
	is_recording = true


func stop_recording() -> void:
	recording_manager.stop_recording()
	is_recording = false


func get_recording() -> Recording:
	return recording_manager.get_recording()


func activate() -> void:
	is_active = true


func deactivate() -> void:
	is_active = false


func set_replay(recording: Recording) -> void:
	input_provider = ReplayInput.new(recording)
	is_recording = false


func begin_replay(start_position: Vector2, start_velocity: Vector2) -> void:
	player.global_position = start_position
	player.velocity = start_velocity
	player.reset_state()
	player.enable_collision()
	player.visible = true
	player.reset_physics_interpolation()
	set_replay(get_recording())
	activate()
