@tool
class_name CloneBarrier
extends Barrier


const BARRIER_LAYER: int = 5

@export var color: Color = Color.LIGHT_GRAY:
	set(value):
		color = value
		self_modulate = value


func _ready() -> void:
	super()
	self_modulate = color


func _get_barrier_layer() -> int:
	return BARRIER_LAYER
