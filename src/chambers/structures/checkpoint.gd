class_name Checkpoint
extends Node2D


@export var level_manager: LevelManager
@export var inactive_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var active_color: Color = Color(0.0, 1.0, 0.0, 1.0)

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	sprite.self_modulate = inactive_color


func _on_body_entered(body: Node2D):
	if body != level_manager.player:
		return
	level_manager.player_start_position = global_position
	sprite.self_modulate = active_color
