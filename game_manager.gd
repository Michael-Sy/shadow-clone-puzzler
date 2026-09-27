extends Node


const SAVE_PATH := "user://progress.cfg"

var campaign: Campaign = preload("res://assets/resources/campaign.tres")
var current_index: int = -1
var highest_unlocked: int = 0

var _is_changing_scene: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_progress()


func start_chamber(index: int) -> void:
	if _is_changing_scene:
		return
	_is_changing_scene = true
	current_index = index
	highest_unlocked = maxi(highest_unlocked, index)
	_save_progress()
	get_tree().paused = false
	_change_scene.call_deferred(campaign.chambers[index].scene_path)


func complete_chamber() -> void:
	var next := current_index + 1
	if next >= campaign.chambers.size():
		print("job done")
		return  # TODO: Make a end credits or go back to menu or something
	start_chamber(next)


func restart_chamber() -> void:
	start_chamber(current_index)


func get_current_chamber() -> ChamberData:
	return campaign.chambers[current_index]


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
	_is_changing_scene = false


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked", highest_unlocked)
	config.save(SAVE_PATH)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highest_unlocked = config.get_value("progress", "highest_unlocked", 0)
