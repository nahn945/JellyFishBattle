extends RigidBody2D
signal damaged(value : float, id : int)
signal damage_end(id : int)

@export var id : int
@export var power : float = 0.5

@export var input_up : String
@export var input_left : String
@export var input_right : String

const ROT_SPEED : float = 2.0
const JUMP_SPEED : float = 800.0
const JUMP_CHARGE : float = 0.01

const X_MAX : float = 1920
const X_MIN : float = 0.0
const Y_MAX : float = 1080
const Y_MIN : float = 0.0
const CENTER_X : float = 960
const CENTER_Y : float = 540

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D
@onready var particle : CPUParticles2D = $CPUParticles2D

var can_operate : bool = true

var jump_parameter : float = 0.0
var can_jump : bool = true

var damage_rate : float = 0.0

var is_attackikng : bool = false

func _ready() -> void:
	anim.animation = "default"

func _physics_process(delta: float) -> void:
	if sleeping:
		return
	
	if Input.is_action_pressed(input_up) and can_jump:
		anim.animation = "charge"
		jump_parameter = min(1.0, jump_parameter + JUMP_CHARGE)
		
	if Input.is_action_just_released(input_up) and can_jump:
		anim.animation = "boost"
		can_jump = false
		var jump_force := Vector2.UP.rotated(transform.get_rotation()) * JUMP_SPEED * jump_parameter 
		apply_impulse(jump_force)
		await get_tree().create_timer(max(0.5, jump_parameter * 1.5)).timeout
		jump_parameter = 0.0
		can_jump = true
		anim.animation = "default"
		
	check_is_outside()
	
	var direction : float = Input.get_axis(input_left, input_right)
	if direction:
		angular_velocity = direction * ROT_SPEED

func check_is_outside():
	if global_position.x < X_MIN or global_position.x > X_MAX:
		global_position = Vector2(CENTER_X, global_position.y)
		damaged.emit(1, id)
		await get_tree().create_timer(0.1).timeout
		damage_end.emit(id)
	if global_position.y < Y_MIN or global_position.y > Y_MAX:
		global_position = Vector2(global_position.x, CENTER_Y)
		damaged.emit(1, id)
		await get_tree().create_timer(0.1).timeout
		damage_end.emit(id)
	

func _process(delta: float) -> void:
	if is_attackikng and id:
		damaged.emit(damage_rate, id)

func _on_area_entered(area: Area2D) -> void:
	is_attackikng = true
	damage_rate = power

func _on_area_exited(area: Area2D) -> void:
	is_attackikng = false
	damage_end.emit(id)

func stop_operating():
	can_operate = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	gravity_scale = 0.0
	self.sleeping = true

func activate_operating():
	can_operate = true
	self.sleeping = false
	gravity_scale = 0.05
	apply_impulse(Vector2.DOWN)

func lose():
	particle.emitting = true
	await get_tree().create_timer(1.0).timeout
	hide()
