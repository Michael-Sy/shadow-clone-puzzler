class_name Character
extends CharacterBody2D


const SPEED = 125.0
const JUMP_VELOCITY = -250.0

@export_category("Jump Settings")
@export var jump_height: float = 40.0
@export var time_to_jump_apex: float = 0.35
@export var jump_cutoff: float = 2.5
@export var downward_movement_multiplier: float = 1.2

@export_category("Movement Settings")
@export var max_ground_acceleration: float = 600.0
@export var max_ground_deacceleration: float = 600.0
@export var max_ground_turn_speed: float = 800.0

@onready var player_controller: CharacterController = $CharacterController
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var is_frozen: bool = false

var _jump_gravity: float = 0.0
var _jump_velocity: float = 0.0

var _desired_jump: bool = false
var _pressing_jump: bool = false

var _coyote_time: float = 0.2
var _coyote_time_counter: float = 0.0

var _jump_buffer: float = 0.2
var _jump_buffer_counter: float = 0.0

var _max_speed_change: float = 0.0

var _current_input: CharacterInputData = CharacterInputData.new()


func _ready() -> void:
	_jump_gravity = (2.0 * jump_height) / pow(time_to_jump_apex, 2)
	_jump_velocity = -(2.0 * jump_height) / time_to_jump_apex


func _physics_process(delta: float) -> void:
	if is_frozen:
		return
	
	var input := _current_input
	
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
	
	if direction:
		if sign(direction) != sign(velocity.x):
			_max_speed_change = turn_speed * delta
		else:
			_max_speed_change = acceleration * delta
	else:
		_max_speed_change = deacceleration * delta
	
	velocity.x = move_toward(
		velocity.x,
		desired_velocity,
		_max_speed_change
	)
	
	move_and_slide()


func set_input(input: CharacterInputData) -> void:
	_current_input = input


func freeze() -> void:
	is_frozen = true
	velocity = Vector2.ZERO


func unfreeze() -> void:
	is_frozen = false


func enable_collision() -> void:
	collision_shape_2d.disabled = false


func disable_collision() -> void:
	collision_shape_2d.disabled = true
