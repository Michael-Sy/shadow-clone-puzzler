@tool
class_name PlayerBarrier
extends Barrier


const BARRIER_LAYER: int = 4

@export var level_manager: LevelManager
@export var seconds_per_color: float = 1.0
@export_range(0.0, 1.0) var blend_fraction: float = 0.5

var _colors: Array[Color] = []
var _time: float = 0.0


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		_colors = _get_clone_colors()


func _get_barrier_layer() -> int:
	return BARRIER_LAYER


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _colors.size() <= 1:
		self_modulate = _colors[0] if _colors.size() == 1 else Color.WHITE
		return
	
	_time += delta
	var step := fmod(_time / seconds_per_color, _colors.size())
	var index := int(step)
	var hold := 1.0 - blend_fraction
	var t := clampf((step - index - hold) / maxf(blend_fraction, 0.001), 0.0, 1.0)
	self_modulate = _colors[index].lerp(_colors[(index + 1) % _colors.size()], smoothstep(0.0, 1.0, t))


func _get_clone_colors() -> Array[Color]:
	var colors: Array[Color] = []
	if level_manager == null:
		return colors
	for i in level_manager.max_total_clones:
		colors.append(level_manager.clone_colors[i] if i < level_manager.clone_colors.size() else Color.WHITE)
	return colors
