@abstract
class_name Activator
extends Node2D


signal changed(active: bool)

var is_active: bool = false


func _ready() -> void:
	add_to_group("resettable")


func set_active(value: bool) -> void:
	if value == is_active:
		return
	is_active = value
	changed.emit(value)


@abstract
func reset() -> void


@abstract
func save_state() -> Dictionary


@abstract
func load_state(state: Dictionary) -> void
