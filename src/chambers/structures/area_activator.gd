class_name AreaActivator
extends Activator


enum Mode { TIMED, TOGGLE, ONCE }

@export var level_manager: LevelManager
@export var resets_on_reset: bool = true
@export var mode: Mode = Mode.TIMED
@export var active_seconds: float = 3.0

@onready var area: Area2D = $Area2D

var _frames_left: int = 0


func _ready() -> void:
	super()
	area.body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if _frames_left > 0:
		_frames_left -= 1
		if _frames_left == 0:
			set_active(false)


func reset() -> void:
	if not resets_on_reset:
		return
	_frames_left = 0
	set_active(false)


func save_state() -> Dictionary:
	return { "active": is_active, "frames_left": _frames_left }


func load_state(state: Dictionary) -> void:
	_frames_left = state["frames_left"]
	set_active(state["active"])


func _on_body_entered(body: Node2D) -> void:
	if body != level_manager.player:
		return
	print(true)
	match mode:
		Mode.TIMED:
			_frames_left = roundi(active_seconds * Engine.physics_ticks_per_second)
			set_active(true)
		Mode.TOGGLE:
			set_active(not is_active)
		Mode.ONCE:
			set_active(true)
