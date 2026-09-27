class_name PressurePlate
extends Activator


@export var inactive_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var active_color: Color = Color(0.0, 1.0, 0.0, 1.0)

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

var _body_count: int = 0


func _ready() -> void:
	super()
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func reset() -> void:
	pass


func save_state() -> Dictionary:
	return {}


func load_state(_state: Dictionary) -> void:
	pass


func _on_body_entered(_body: Node2D) -> void:
	_body_count += 1
	set_active(true)
	sprite.self_modulate = active_color


func _on_body_exited(_body: Node2D) -> void:
	_body_count -= 1
	set_active(_body_count > 0)
	sprite.self_modulate = active_color if is_active else inactive_color
