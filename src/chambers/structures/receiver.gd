class_name Receiver
extends Node2D


enum Logic { ALL, ANY }

@export var inputs: Array[Activator] = []
@export var logic: Logic = Logic.ALL
@export var inverted: bool = false


func _ready() -> void:
	add_to_group("resettable")
	for input in inputs:
		input.changed.connect(_on_input_changed)
	_evaluate()


func _on_input_changed(_active: bool) -> void:
	_evaluate()


func _evaluate() -> void:
	var result: bool
	if logic == Logic.ALL:
		result = inputs.all(func(i: Activator) -> bool: return i.is_active)
	else:
		result = inputs.any(func(i: Activator) -> bool: return i.is_active)
	_set_powered(result != inverted)


func _set_powered(_powered: bool) -> void:
	pass  # override


func reset() -> void:
	_evaluate()
