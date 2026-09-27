class_name InteractButton
extends Activator


enum Mode { TIMED, TOGGLE, ONCE }

@export var mode: Mode = Mode.TIMED
@export var active_seconds: float = 3.0
@export var inactive_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var active_color: Color = Color(0.0, 1.0, 0.0, 1.0)

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var rich_text_label: RichTextLabel = $RichTextLabel


var _frames_left: int = 0


func _ready() -> void:
	super()
	add_to_group("interactable")
	changed.connect(_on_changed)
	_on_changed(is_active)


func can_interact(character: Character) -> bool:
	return area.overlaps_body(character)


func interact(_character: Character) -> void:
	match mode:
		Mode.TIMED:
			_frames_left = roundi(active_seconds * Engine.physics_ticks_per_second)
			rich_text_label.visible = true
			set_active(true)
		Mode.TOGGLE:
			set_active(not is_active)
		Mode.ONCE:
			set_active(true)


func _physics_process(_delta: float) -> void:
	if _frames_left > 0:
		_frames_left -= 1
		
		var seconds_left: float = float(_frames_left) / Engine.physics_ticks_per_second
		rich_text_label.text = "%.1f" % seconds_left
		
		if _frames_left == 0:
			set_active(false)
			rich_text_label.visible = false


func reset() -> void:
	_frames_left = 0
	rich_text_label.visible = false
	set_active(false)


func save_state() -> Dictionary:
	return { "active": is_active, "frames_left": _frames_left }


func load_state(state: Dictionary) -> void:
	_frames_left = state["frames_left"]
	set_active(state["active"])


func _on_changed(active: bool) -> void:
	sprite.self_modulate = active_color if active else inactive_color
