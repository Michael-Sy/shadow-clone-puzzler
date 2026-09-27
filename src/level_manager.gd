class_name LevelManager
extends Node


@export var hard_reset_hold_time: float = 1.0
@export var entrance: Marker2D
@export_category("Clone Settings")
@export var allow_become_platform: bool = false
@export var max_total_clones: int = 1
@export var allow_nested_clones: bool = false
@export var max_clones_per_clone: int = 1


var clone_scene: PackedScene = preload("res://scenes/clone.tscn")
var clone_colors: Array[Color] = [
	Color("00d1ff"), 
	Color("ff8c00"), 
	Color("ff4e99"), 
	Color("00d300"), 
	Color("a600ff")
	]
var player_start_position: Vector2
var attempt_start_position: Vector2
var attempt_start_velocity: Vector2
var reset_hold_start: int = -1
var is_waiting_to_resume: bool = false
var controlled_character: Character
var controlled_clone: Character
var stored_clones: Array[Character] = []
var clone_parents: Dictionary[Character, Character] = {}
var clone_children: Dictionary[Character, Array] = {}
var clone_waiting_for_replay: bool = false
var has_replayed: bool = false
var world_snapshots: Dictionary[Character, Dictionary] = {}

@onready var player: Character = $"../Player"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not player.is_node_ready():
		await player.ready
	
	if entrance != null:
		player.global_position = entrance.global_position
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
	else:
		push_warning("LevelManager: no entrance set, using the player's placed position.")
	
	player_start_position = player.global_position
	controlled_character = player


func _process(_delta: float) -> void:
	if reset_hold_start < 0:
		return
	if (Time.get_ticks_msec() - reset_hold_start) / 1000.0 >= hard_reset_hold_time:
		reset_hold_start = -1
		hard_reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level"):
		reset_hold_start = Time.get_ticks_msec()
		return
	
	if event.is_action_released("reset_level"):
		if reset_hold_start >= 0:
			reset_hold_start = -1
			quick_reset()
		return
	
	if is_waiting_to_resume and _is_moving_event(event):
		resume_world()
		return
	
	if event.is_action_pressed("reset_recording"):
		reset_controlled_clone()
	
	if event.is_action_pressed("create_clone"):
		spawn_clone_from_controlled_character()
	
	if event.is_action_pressed("stop_recording"):
		stop_controlled_clone()
	
	if event.is_action_pressed("become_platform"):
		make_controlled_clone_platform()
	
	if event.is_action_pressed("interact") and controlled_character != null:
		controlled_character.controller.queue_command(InteractCommand.new())


func spawn_clone_from_controlled_character() -> void:
	if controlled_character == null:
		return
	
	if controlled_character == player and has_replayed:
		clean_previous_replays()
	
	if not can_spawn_from(controlled_character):
		return
	
	var new_clone: Character = clone_scene.instantiate()
	add_child(new_clone)
	new_clone.global_position = controlled_character.global_position
	new_clone.velocity = controlled_character.velocity
	new_clone.reset_physics_interpolation()
	
	world_snapshots[new_clone] = _save_world_state()
	
	var color_index := clone_parents.size()
	new_clone.clone_number = color_index + 1
	if color_index < clone_colors.size():
		new_clone.set_base_color(clone_colors[color_index])
	
	var spawn_command := SpawnCloneCommand.new()
	spawn_command.position = new_clone.global_position
	spawn_command.velocity = new_clone.velocity
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
	
	pause_world()


func stop_controlled_clone() -> void:
	if controlled_clone == null:
		return
	
	_load_world_state(world_snapshots.get(controlled_clone, {}))
	
	var clone_controller: CharacterController = controlled_clone.controller
	var previous_character: Character = clone_parents[controlled_clone]
	
	clone_controller.stop_recording()
	clone_controller.deactivate()
	
	controlled_clone.visible = false
	controlled_clone.disable_collision()
	stored_clones.append(controlled_clone)
	
	controlled_clone = previous_character if previous_character != player else null
	
	previous_character.controller.activate()
	
	controlled_character = previous_character
	
	if previous_character == player:
		attempt_start_position = player.global_position
		attempt_start_velocity = player.velocity
	
	clone_waiting_for_replay = previous_character == player
	
	pause_world()


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
	
	_load_world_state(world_snapshots.get(controlled_clone, {}))
	
	var clone_controller: CharacterController = controlled_clone.controller
	_free_descendants(controlled_clone)
	
	controlled_clone.global_position = clone_controller.recording_start_position
	controlled_clone.velocity = clone_controller.recording_start_velocity
	controlled_clone.reset_state()
	controlled_clone.reset_physics_interpolation()
	
	clone_controller.start_recording()


func can_spawn_from(character: Character) -> bool:
	if clone_parents.size() >= max_total_clones:
		return false
	if character == player:
		return true
	if not allow_nested_clones:
		return false
	return clone_children.get(character, []).size() < max_clones_per_clone


func clean_previous_replays() -> void:
	for clone in clone_parents.keys():
		clone.queue_free()
	
	stored_clones.clear()
	clone_parents.clear()
	clone_children.clear()
	world_snapshots.clear()
	has_replayed = false


func pause_world() -> void:
	get_tree().paused = true
	is_waiting_to_resume = true


func resume_world() -> void:
	is_waiting_to_resume = false
	get_tree().paused = false
	if clone_waiting_for_replay:
		replay_stored_clone()
		clone_waiting_for_replay = false


func quick_reset() -> void:
	_discard_in_progress_clones()
	for clone in stored_clones:
		_hide_clone(clone)
	if stored_clones.is_empty():
		_reset_player(player_start_position, Vector2.ZERO)
	else:
		_reset_player(attempt_start_position, attempt_start_velocity)
	clone_waiting_for_replay = not stored_clones.is_empty()
	pause_world()
	get_tree().call_group("resettable", "reset")
	print("start: ", player_start_position, "  attempt: ", attempt_start_position, "  stored: ", stored_clones.size())


func hard_reset() -> void:
	clean_previous_replays()
	_reset_player(player_start_position, Vector2.ZERO)
	clone_waiting_for_replay = false
	pause_world()
	get_tree().call_group("resettable", "reset")
	GameManager.restart_chamber()


func make_controlled_clone_platform() -> void:
	if controlled_clone == null or not allow_become_platform or controlled_clone.is_platform:
		return
	controlled_clone.controller.queue_command(BecomePlatformCommand.new())
	#controlled_character.controller.recording_manager.record_command(command)
	#command.execute(controlled_clone.controller)


func _reset_player(position: Vector2, velocity: Vector2) -> void:
	player.global_position = position
	player.velocity = velocity
	player.reset_state()
	player.reset_physics_interpolation()
	player.controller.activate()
	controlled_character = player
	controlled_clone = null


func _discard_in_progress_clones() -> void:
	if controlled_clone == null:
		return
	var root: Character = controlled_clone
	while clone_parents[root] != player:
		root = clone_parents[root]
	_free_descendants(root)
	clone_children[player].erase(root)
	world_snapshots.erase(root)
	clone_parents.erase(root)
	root.queue_free()


func _hide_clone(character: Character) -> void:
	character.controller.deactivate()
	character.disable_collision()
	character.visible = false


func _free_descendants(character: Character) -> void:
	if not clone_children.has(character):
		return
	for child: Character in clone_children[character]:
		_free_descendants(child)
		stored_clones.erase(child)
		clone_parents.erase(child)
		world_snapshots.erase(child)
		child.queue_free()
	clone_children.erase(character)


func _is_moving_event(event: InputEvent) -> bool:
	return event.is_action_pressed("left") or event.is_action_pressed("right") \
				or event.is_action_pressed("jump")


func _save_world_state() -> Dictionary:
	var snapshot := {}
	for node in get_tree().get_nodes_in_group("resettable"):
		if node.has_method("save_state"):
			snapshot[node] = node.save_state()
	return snapshot


func _load_world_state(snapshot: Dictionary) -> void:
	for node in snapshot:
		if is_instance_valid(node):
			node.load_state(snapshot[node])


func _on_replay_finished(character: Character) -> void:
	if character.is_platform:
		character.controller.deactivate()
		return
	_hide_clone(character)
