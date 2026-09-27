class_name ChamberExit
extends Area2D


@export var level_manager: LevelManager


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body == level_manager.player:
		GameManager.complete_chamber()
