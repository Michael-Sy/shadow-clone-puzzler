class_name Character
extends CharacterBody2D


const PLATFORM_LAYER: int = 2
const SPEED = 125.0

@export_category("Jump Settings")
@export var jump_height: float = 40.0
@export var time_to_jump_apex: float = 0.35
@export var jump_cutoff: float = 2.5
@export var downward_movement_multiplier: float = 1.2

@export_category("Movement Settings")
@export var max_ground_acceleration: float = 600.0
@export var max_ground_deacceleration: float = 600.0
@export var max_ground_turn_speed: float = 800.0

@export_category("Platform Visuals")
@export_range(0.0, 1.0) var platform_saturation: float = 0.2
@export_range(0.0, 1.0) var platform_brightness: float = 0.55

var clone_number: int = 0
var is_platform: bool = false
var base_color: Color = Color.WHITE

@onready var platform_particles: CPUParticles2D = get_node_or_null("PlatformParticles")
@onready var controller: CharacterController = $CharacterController
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var _jump_gravity: float = 0.0
var _jump_velocity: float = 0.0

var _desired_jump: bool = false
var _pressing_jump: bool = false

var _coyote_time: float = 0.2
var _coyote_time_counter: float = 0.0

var _jump_buffer: float = 0.2
var _jump_buffer_counter: float = 0.0

var _platform_armed: bool = false


func _ready() -> void:
	_jump_gravity = (2.0 * jump_height) / pow(time_to_jump_apex, 2)
	_jump_velocity = -(2.0 * jump_height) / time_to_jump_apex


func tick(input: CharacterInputData, delta: float) -> void:
	if is_platform:
		var wants_move: bool = input.move_direction != 0.0 or input.jump_pressed
		if not wants_move:
			_platform_armed = true
			return
		if not _platform_armed:
			return
		_exit_platform()
	
	if input.jump_pressed:
		_desired_jump = true
		_pressing_jump = true
	
	if not input.jump_held:
		_pressing_jump = false
	
	if _desired_jump:
		_jump_buffer_counter += delta
	
		if _jump_buffer_counter > _jump_buffer:
			_desired_jump = false
			_jump_buffer_counter = 0.0
	
	if is_on_floor():
		_coyote_time_counter = _coyote_time
	else:
		_coyote_time_counter -= delta
	
	if not is_on_floor():
		var gravity_multiplier: float = 1.0
	
		if velocity.y < 0.0:
			if not _pressing_jump:
				gravity_multiplier = jump_cutoff
		elif velocity.y > 0.0:
			gravity_multiplier = downward_movement_multiplier
	
		velocity.y += _jump_gravity * delta * gravity_multiplier
	
	if _desired_jump:
		if is_on_floor() or _coyote_time_counter > 0.0:
			_desired_jump = false
			_jump_buffer_counter = 0.0
			_coyote_time_counter = 0.0
			velocity.y = _jump_velocity
	
	var acceleration: float = max_ground_acceleration
	var deacceleration: float = max_ground_deacceleration
	var turn_speed: float = max_ground_turn_speed
	
	var direction := input.move_direction
	var desired_velocity: float = direction * SPEED
	var max_speed_change: float = 0.0
	
	if direction:
		if sign(direction) != sign(velocity.x):
			max_speed_change = turn_speed * delta
		else:
			max_speed_change = acceleration * delta
	else:
		max_speed_change = deacceleration * delta
	
	velocity.x = move_toward(
		velocity.x,
		desired_velocity,
		max_speed_change
	)
	
	move_and_slide()


func reset_state() -> void:
	_desired_jump = false
	_pressing_jump = false
	_coyote_time_counter = 0.0
	_jump_buffer_counter = 0.0
	if is_platform:
		_exit_platform()


func enable_collision() -> void:
	collision_shape_2d.disabled = false


func disable_collision() -> void:
	collision_shape_2d.disabled = true


func become_platform() -> void:
	if is_platform:
		return
	is_platform = true
	_platform_armed = false
	velocity = Vector2.ZERO
	set_collision_layer_value(PLATFORM_LAYER, true)
	_update_platform_visuals()


func set_base_color(color: Color) -> void:
	base_color = color
	_update_platform_visuals()


func get_platform_color() -> Color:
	return Color.from_hsv(
		base_color.h,
		base_color.s * platform_saturation,
		base_color.v * platform_brightness,
		base_color.a
	)


func _update_platform_visuals() -> void:
	sprite.self_modulate = get_platform_color() if is_platform else base_color
	if platform_particles != null:
		platform_particles.color = get_platform_color()
		platform_particles.emitting = is_platform


func _exit_platform() -> void:
	is_platform = false
	set_collision_layer_value(PLATFORM_LAYER, false)
	_update_platform_visuals()
