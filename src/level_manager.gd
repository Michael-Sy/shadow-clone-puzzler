class_name LevelManager
extends Node


@export var clone_scene: PackedScene

var controlled_character: Character
var controlled_clone: Character
var stored_clones: Array[Character] = []
var clone_parents: Dictionary[Character, Character] = {}
var clone_children: Dictionary[Character, Array] = {}
var clone_waiting_for_replay: bool = false
var has_replayed: bool = false

@onready var player: Character = $"../Player"


func _ready() -> void:
	if not player.is_node_ready():
		await player.ready
	
	var player_controller: CharacterController = player.controller
	player_controller.action_performed.connect(_on_player_action)
	player_controller.replay_finished.connect(_on_replay_finished)
	controlled_character = player


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("clear_recording"):
		reset_controlled_clone()
	
	if event.is_action_pressed("ui_up"):
		spawn_clone_from_controlled_character()
	
	if event.is_action_pressed("ui_down"):
		stop_controlled_clone()


func spawn_clone_from_controlled_character() -> void:
	if controlled_character == null:
		return
	
	if controlled_character == player and has_replayed:
		clean_previous_replays()
	
	var new_clone: Character = clone_scene.instantiate()
	add_child(new_clone)
	new_clone.global_position = controlled_character.global_position
	new_clone.velocity = controlled_character.velocity
	
	var spawn_command := SpawnCloneCommand.new()
	spawn_command.position = controlled_character.global_position
	spawn_command.velocity = controlled_character.velocity
	spawn_command.clone = new_clone
	controlled_character.controller.recording_manager.record_command(spawn_command)
	
	var clone_controller: CharacterController = new_clone.controller
	clone_controller.replay_finished.connect(_on_replay_finished)
	clone_controller.start_recording()
	
	clone_parents[new_clone] = controlled_character
	if not clone_children.has(controlled_character):
		clone_children[controlled_character] = []
	
	clone_children[controlled_character].append(new_clone)
	
	controlled_character.controller.deactivate()
	
	controlled_clone = new_clone
	controlled_character = new_clone
	clone_waiting_for_replay = false


func stop_controlled_clone() -> void:
	if controlled_clone == null:
		return
	
	var clone_controller: CharacterController = controlled_clone.controller
	var previous_character: Character = clone_parents[controlled_clone]
	
	clone_controller.stop_recording()
	clone_controller.deactivate()
	
	controlled_clone.visible = false
	controlled_clone.disable_collision()
	stored_clones.append(controlled_clone)
	
	controlled_clone = previous_character if previous_character != player else null
	
	previous_character.visible = true
	previous_character.controller.activate()
	
	controlled_character = previous_character
	
	if previous_character == player:
		previous_character.controller.set_human_control()
	
	clone_waiting_for_replay = previous_character == player


func replay_stored_clone() -> void:
	has_replayed = true
	
	for clone in stored_clones:
		if clone_parents[clone] != player:
			continue
		
		var clone_controller: CharacterController = clone.controller
		clone_controller.begin_replay(
			clone_controller.recording_start_position,
			clone_controller.recording_start_velocity
		)


func reset_controlled_clone() -> void:
	if controlled_clone == null:
		return

	var clone_controller: CharacterController = controlled_clone.controller
	_free_descendants(controlled_clone)

	controlled_clone.global_position = clone_controller.recording_start_position
	controlled_clone.velocity = clone_controller.recording_start_velocity
	controlled_clone.reset_state()

	clone_controller.start_recording()


func _free_descendants(character: Character) -> void:
	if not clone_children.has(character):
		return
	for child: Character in clone_children[character]:
		_free_descendants(child)
		stored_clones.erase(child)
		clone_parents.erase(child)
		child.queue_free()
	clone_children.erase(character)


func clean_previous_replays() -> void:
	for clone in stored_clones:
		clone.queue_free()
	
	stored_clones.clear()
	clone_parents.clear()
	clone_children.clear()
	has_replayed = false


func _on_player_action() -> void:
	if not clone_waiting_for_replay:
		return
	
	replay_stored_clone()
	clone_waiting_for_replay = false


func _on_replay_finished(character: Character) -> void:
	character.controller.deactivate()
	character.disable_collision()
	character.visible = false
