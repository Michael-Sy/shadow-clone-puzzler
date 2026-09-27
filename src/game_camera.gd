class_name GameCamera
extends Camera2D


@export var level_manager: LevelManager
@export var follow_speed: float = 6.0

var _rooms: Array[Rect2] = []
var _current_room: Rect2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for room: ReferenceRect in get_tree().get_nodes_in_group("camera_room"):
		_rooms.append(room.get_global_rect())
	make_current()
	await get_tree().process_frame
	_snap_to_target()


func _process(delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	var desired := _get_desired_position(target.global_position)
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)


func _snap_to_target() -> void:
	var target := _get_target()
	if target != null:
		global_position = _get_desired_position(target.global_position)


func _get_target() -> Node2D:
	if level_manager == null:
		return null
	return level_manager.controlled_character


func _get_desired_position(target_position: Vector2) -> Vector2:
	for room in _rooms:
		if room.has_point(target_position):
			_current_room = room
			break

	if _current_room.size == Vector2.ZERO:
		return target_position

	var half_view := get_viewport_rect().size / zoom / 2.0
	return Vector2(
		_clamp_axis(target_position.x, _current_room.position.x, _current_room.end.x, half_view.x),
		_clamp_axis(target_position.y, _current_room.position.y, _current_room.end.y, half_view.y)
	)


func _clamp_axis(value: float, room_start: float, room_end: float, half_view: float) -> float:
	if room_end - room_start <= half_view * 2.0:
		return (room_start + room_end) / 2.0
	return clampf(value, room_start + half_view, room_end - half_view)
