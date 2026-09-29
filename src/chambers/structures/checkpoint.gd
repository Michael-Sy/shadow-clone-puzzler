class_name Checkpoint
extends Area2D


@export var level_manager: LevelManager
@export var spawn_point: Marker2D
@export var inactive_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var active_color: Color = Color(0.0, 1.0, 0.0, 1.0)

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.self_modulate = inactive_color


func _on_body_entered(body: Node2D) -> void:
	if body != level_manager.player:
		return
	var new_position := spawn_point.global_position if spawn_point != null else global_position
	level_manager.set_checkpoint(new_position)
	level_manager.clear_all_recordings()
	sprite.self_modulate = active_color
