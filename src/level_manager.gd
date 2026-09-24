class_name LevelManager
extends Node


@export var clone_scene: PackedScene

var controlled_character: Character
var controlled_clone: Character
var stored_clones: Array[Character] = []
var clone_parents: Dictionary[Character, Character] = {}
var clone_children: Dictionary[Character, Array] = {}
var next_child_index: Dictionary = {}
var clone_waiting_for_replay: bool = false
var player_controller: CharacterController
var has_replayed: bool = false

@onready var player: Character = $"../Player"


func _ready() -> void:
	await player.ready
	player_controller = player.player_controller
	player_controller.action_performed.connect(_on_player_action)
	player_controller.spawn_event_reached.connect(_on_spawn_event_reached)
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
	
	controlled_character.player_controller.recording_manager.record_spawn_event()
	
	var new_clone: Character = clone_scene.instantiate()
	add_child(new_clone)
	
	new_clone.global_position = controlled_character.global_position
	new_clone.velocity = controlled_character.velocity
	
	var clone_controller: CharacterController = new_clone.player_controller
	clone_controller.spawn_event_reached.connect(_on_spawn_event_reached)
	clone_controller.replay_finished.connect(_on_replay_finished)
	clone_controller.start_recording()
	
	clone_parents[new_clone] = controlled_character
	if not clone_children.has(controlled_character):
		clone_children[controlled_character] = []
	
	clone_children[controlled_character].append(new_clone)
	
	controlled_character.player_controller.deactivate()
	controlled_character.set_input(CharacterInputData.new())
	controlled_character.freeze()
	
	controlled_clone = new_clone
	controlled_character = new_clone
	clone_waiting_for_replay = false


func stop_controlled_clone() -> void:
	if controlled_clone == null:
		return
	
	var clone_controller: CharacterController = controlled_clone.player_controller
	var previous_character: Character = clone_parents[controlled_clone]
	
	clone_controller.stop_recording()
	clone_controller.deactivate()
	
	controlled_clone.visible = false
	stored_clones.append(controlled_clone)
	
	controlled_clone = previous_character if previous_character != player else null
	
	previous_character.visible = true
	previous_character.unfreeze()
	previous_character.player_controller.activate()
	
	controlled_character = previous_character
	
	if previous_character == player:
		previous_character.player_controller.set_human_control()
	
	clone_waiting_for_replay = previous_character == player


func replay_stored_clone() -> void:
	next_child_index.clear()
	has_replayed = true
	
	for clone in stored_clones:
		var clone_controller: CharacterController = clone.player_controller
		
		if clone_parents[clone] != player:
			continue
		
		clone.global_position = clone_controller.recording_start_position
		clone.velocity = Vector2.ZERO
		clone.enable_collision()
		clone.visible = true
		
		clone_controller.set_replay(clone_controller.get_recording())
		clone_controller.activate()


func reset_controlled_clone() -> void:
	if controlled_clone == null:
		return
	
	var clone_controller: CharacterController = controlled_clone.player_controller
	
	clone_children.erase(controlled_clone)
	
	controlled_clone.global_position = clone_controller.recording_start_position
	controlled_clone.velocity = Vector2.ZERO
	
	clone_controller.start_recording()


func clean_previous_replays() -> void:
	for clone in stored_clones:
		clone.queue_free()
	
	stored_clones.clear()
	clone_parents.clear()
	clone_children.clear()
	next_child_index.clear()
	has_replayed = false


func _on_player_action() -> void:
	if not clone_waiting_for_replay:
		return
	
	replay_stored_clone()
	clone_waiting_for_replay = false


func _on_spawn_event_reached(character: Character) -> void:
	if not clone_children.has(character):
		return
	
	if not next_child_index.has(character):
		next_child_index[character] = 0
	
	var index: int = next_child_index[character]
	var children: Array = clone_children[character]
	
	if index >= children.size():
		return
	
	var clone: Character = children[index]
	next_child_index[character] += 1
	
	var clone_controller: CharacterController = clone.player_controller
	
	clone.global_position = character.global_position
	clone.velocity = Vector2.ZERO
	clone.enable_collision()
	clone.visible = true
	
	clone_controller.set_replay(clone_controller.get_recording())
	clone_controller.activate()


func _on_replay_finished(character: Character) -> void:
	character.player_controller.deactivate()
	character.disable_collision()
	character.visible = false
