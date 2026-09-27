class_name Door
extends Receiver


@onready var shape: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _set_powered(powered: bool) -> void:
	shape.set_deferred("disabled", powered)
	visible = not powered
