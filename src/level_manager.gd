class_name LevelManager
extends Node


@export var pause_menu: PauseMenu
@export var entrance: Marker2D
@export_category("Clone Settings")
@export var allow_become_platform: bool = false
@export var max_total_clones: int = 1
@export var allow_nested_clones: bool = false
@export var max_clones_per_clone: int = 1


var clone_scene: PackedScene = preload("res://scenes/clone.tscn")
var clone_colors: Array[Color] = [
	Color("00d1fbff"), 
	Color("ff8c00"), 
	Color("ff4e99"), 
	Color("00d300"), 
	Color("a600ff")
	]
var player_start_position: Vector2
var checkpoint_position: Vector2
var selected_clone: Character
var is_waiting_to_resume: bool = false
var controlled_character: Character
var controlled_clone: Character
var stored_clones: Array[Character] = []
var clone_parents: Dictionary[Character, Character] = {}
var clone_children: Dictionary[Character, Array] = {}
var pending_clones: Array[Character] = []
var frozen_clones: Array[Character] = []
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
	checkpoint_position = player_start_position
	controlled_character = player


func _unhandled_input(event: InputEvent) -> void:
	if pause_menu != null and pause_menu.visible:
		return
	
	if is_waiting_to_resume and _is_moving_event(event):
		resume_world()
		return
	
	if event.is_action_pressed("return_to_checkpoint"):
		return_to_checkpoint()
	elif event.is_action_pressed("clear_all_recordings"):
		clear_all_recordings()
	elif event.is_action_pressed("clear_recording"):
		clear_recording()
	elif event.is_action_pressed("select_previous_clone"):
		cycle_selected_clone(-1)
	elif event.is_action_pressed("select_next_clone"):
		cycle_selected_clone(1)
	elif event.is_action_pressed("ui_up"):
		spawn_clone_from_controlled_character()
	elif event.is_action_pressed("ui_down"):
		stop_controlled_clone()
	elif event.is_action_pressed("become_platform"):
		make_controlled_clone_platform()
	elif event.is_action_pressed("interact") and controlled_character != null:
		controlled_character.controller.queue_command(InteractCommand.new())


func spawn_clone_from_controlled_character() -> void:
	if controlled_character == null:
		return
	
	if can_spawn_from(controlled_character):
		_freeze_running_clones()
		_spawn_new_clone(controlled_character)
	elif controlled_character == player and clone_parents.size() >= max_total_clones:
		var selected := get_selected_clone()
		if selected != null:
			_freeze_running_clones()
			_rerecord_clone(selected)


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
	if previous_character == player:
		pending_clones.append(controlled_clone)
	
	controlled_clone = previous_character if previous_character != player else null
	
	previous_character.controller.activate()
	
	controlled_character = previous_character
	
	clone_waiting_for_replay = previous_character == player
	
	pause_world()


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
	pause_world()


func can_spawn_from(character: Character) -> bool:
	if clone_parents.size() >= max_total_clones:
		return false
	if character == player:
		return true
	if not allow_nested_clones:
		return false
	return clone_children.get(character, []).size() < max_clones_per_clone


func pause_world() -> void:
	get_tree().paused = true
	is_waiting_to_resume = true


func resume_world() -> void:
	is_waiting_to_resume = false
	get_tree().paused = false
	if clone_waiting_for_replay:
		_release_clones()
		clone_waiting_for_replay = false
	elif controlled_clone != null:
		_resume_frozen_clones()


func make_controlled_clone_platform() -> void:
	if controlled_clone == null or not allow_become_platform or controlled_clone.is_platform:
		return
	controlled_clone.controller.queue_command(BecomePlatformCommand.new())


func return_to_checkpoint() -> void:
	_clear_all_clones()
	get_tree().call_group("resettable", "reset")
	_reset_player(checkpoint_position, Vector2.ZERO)
	clone_waiting_for_replay = false
	pause_world()


func set_checkpoint(position: Vector2) -> void:
	checkpoint_position = position


func clear_recording() -> void:
	if controlled_clone != null:
		reset_controlled_clone()
		return
	var selected := get_selected_clone()
	if selected != null:
		_delete_clone(selected)


func clear_all_recordings() -> void:
	var was_recording := controlled_clone != null
	if was_recording:
		_load_world_state(world_snapshots.get(_get_chain_root(controlled_clone), {}))
	if has_replayed:
		get_tree().call_group("resettable", "reset")
	
	_clear_all_clones()
	player.controller.activate()
	controlled_character = player
	controlled_clone = null
	clone_waiting_for_replay = false
	if was_recording:
		pause_world()


func get_selected_clone() -> Character:
	var roots: Array = clone_children.get(player, [])
	if roots.is_empty():
		selected_clone = null
	elif not is_instance_valid(selected_clone) or not roots.has(selected_clone):
		selected_clone = roots[0]
	return selected_clone


func cycle_selected_clone(direction: int) -> void:
	var roots: Array = clone_children.get(player, [])
	if roots.is_empty():
		return
	var index := roots.find(get_selected_clone())
	selected_clone = roots[posmod(index + direction, roots.size())]


func _freeze_running_clones() -> void:
	for clone in stored_clones:
		if clone.controller.is_active:
			clone.controller.deactivate()
			frozen_clones.append(clone)


func _resume_frozen_clones() -> void:
	for clone in frozen_clones:
		if is_instance_valid(clone):
			clone.controller.activate()
	frozen_clones.clear()


func _release_clones() -> void:
	for clone in frozen_clones:
		if is_instance_valid(clone):
			clone.controller.activate()
	frozen_clones.clear()
	
	for clone in pending_clones:
		clone.controller.begin_replay(
			clone.controller.recording_start_position,
			clone.controller.recording_start_velocity
		)
	pending_clones.clear()
	has_replayed = true


func _delete_clone(clone: Character) -> void:
	_free_descendants(clone)
	clone_children[clone_parents[clone]].erase(clone)
	clone_parents.erase(clone)
	stored_clones.erase(clone)
	frozen_clones.erase(clone)
	pending_clones.erase(clone)
	world_snapshots.erase(clone)
	clone.queue_free()


func _clear_all_clones() -> void:
	for clone in clone_parents.keys():
		clone.queue_free()
	stored_clones.clear()
	clone_parents.clear()
	clone_children.clear()
	world_snapshots.clear()
	frozen_clones.clear()
	pending_clones.clear()
	selected_clone = null
	has_replayed = false


func _get_chain_root(clone: Character) -> Character:
	var root := clone
	while clone_parents[root] != player:
		root = clone_parents[root]
	return root


func _reset_player(position: Vector2, velocity: Vector2) -> void:
	player.global_position = position
	player.velocity = velocity
	player.reset_state()
	player.reset_physics_interpolation()
	player.controller.activate()
	controlled_character = player
	controlled_clone = null


func _spawn_new_clone(parent: Character) -> void:
	var new_clone: Character = clone_scene.instantiate()
	add_child(new_clone)
	world_snapshots[new_clone] = _save_world_state()
	new_clone.set_collision_mask_value(PlayerBarrier.BARRIER_LAYER, false) 
	new_clone.set_collision_mask_value(CloneBarrier.BARRIER_LAYER, true)
	new_clone.global_position = parent.global_position
	new_clone.velocity = parent.velocity
	new_clone.reset_physics_interpolation()
	
	var clone_number := _next_free_clone_number()
	new_clone.clone_number = clone_number
	if clone_number - 1 < clone_colors.size():
		new_clone.set_base_color(clone_colors[clone_number - 1])
	
	var spawn_command := SpawnCloneCommand.new()
	spawn_command.position = new_clone.global_position
	spawn_command.velocity = new_clone.velocity
	spawn_command.clone = new_clone
	parent.controller.recording_manager.record_command(spawn_command)
	
	var clone_controller: CharacterController = new_clone.controller
	clone_controller.replay_finished.connect(_on_replay_finished)
	clone_controller.start_recording()
	
	clone_parents[new_clone] = parent
	if not clone_children.has(parent):
		clone_children[parent] = []
	clone_children[parent].append(new_clone)
	
	parent.controller.deactivate()
	controlled_clone = new_clone
	controlled_character = new_clone
	clone_waiting_for_replay = false
	pause_world()


func _rerecord_clone(clone: Character) -> void:
	frozen_clones.erase(clone)
	pending_clones.erase(clone)
	_free_descendants(clone)
	stored_clones.erase(clone)
	
	clone.visible = true
	clone.enable_collision()
	clone.global_position = player.global_position
	clone.velocity = player.velocity
	clone.reset_state()
	clone.reset_physics_interpolation()
	
	world_snapshots[clone] = _save_world_state()
	clone.controller.start_recording()
	clone.controller.activate()
	
	player.controller.deactivate()
	controlled_clone = clone
	controlled_character = clone
	clone_waiting_for_replay = false
	pause_world()


func _next_free_clone_number() -> int:
	var used: Array[int] = []
	for clone: Character in clone_parents:
		used.append(clone.clone_number)
	var number := 1
	while used.has(number):
		number += 1
	return number


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
		frozen_clones.erase(child)
		pending_clones.erase(child)
		clone_parents.erase(child)
		world_snapshots.erase(child)
		child.queue_free()
	clone_children.erase(character)


func _is_moving_event(event: InputEvent) -> bool:
	return event.is_action_pressed("left") or event.is_action_pressed("right") \
				or event.is_action_pressed("jump")


func _save_world_state() -> Dictionary:
	var objects := {}
	for node in get_tree().get_nodes_in_group("resettable"):
		if node.has_method("save_state"):
			objects[node] = node.save_state()
	var clones := {}
	for clone in stored_clones:
		clones[clone] = clone.save_replay_state()
	return { "objects": objects, "clones": clones, "frozen": frozen_clones.duplicate() }


func _load_world_state(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var objects: Dictionary = snapshot["objects"]
	for node in objects:
		if is_instance_valid(node):
			node.load_state(objects[node])
	
	var clones: Dictionary = snapshot["clones"]
	for clone in clones:
		if is_instance_valid(clone):
			clone.controller.deactivate()
			clone.load_replay_state(clones[clone])
	
	frozen_clones.clear()
	for clone in snapshot["frozen"]:
		if is_instance_valid(clone):
			frozen_clones.append(clone)


func _on_replay_finished(character: Character) -> void:
	if character.is_platform:
		character.controller.deactivate()
		return
	_hide_clone(character)
