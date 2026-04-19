extends RigidBody2D
signal tackled

@export var input_up : String = "ui_up"
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"

@onready var jump_timer : Timer = $JumpTimer
@onready var effect_timer : Timer = $EffectTimer
@onready var animation : AnimatedSprite2D = $AnimatedSprite2D

const BOUNCE_COEFFICIENT : float = 0.8
const DAMAGED_COLOR : Color = Color.RED
const NORMAL_COLOR : Color = Color.WHITE

var is_active : bool = true
var is_jumping : bool = false
var is_bounding : bool = false
var is_attacked_front : bool = false
var is_attacked_rear : bool = false

var jump_parameter : float = 0.0
var rot_parameter : float = 1.0

var rear_damage : float = 0.0

var minimum_tackle_speed : float = 0.0

# status
var hp : float = 100.0
var attack_front : float = 2.0
var attack_rear : float = 5.0

var max_rot_speed : float = 10.0
var rot_acceleration : float = 5.0

var max_jump_speed : float = 500.0
var jump_acceleration : float = 10.0

func _init() -> void:
	minimum_tackle_speed = max_jump_speed / 2.0

func get_attack_front() -> float:
	return attack_front

func get_attack_rear() -> float:
	return attack_rear

func change_activation(flag : bool):
	is_active = flag

func apply_damage(value : float):
	modulate = DAMAGED_COLOR
	hp -= value

func wait_jump_end():
	jump_timer.start()
	await jump_timer.timeout
	jump_timer.stop()

func _physics_process(delta: float) -> void:
	if !is_active:
		set_deferred("freeze", true)
		return
	
	set_deferred("freeze", false)
	
	if !is_jumping:
		if Input.is_action_pressed(input_up):
			animation.animation = "charge"
			jump_parameter += jump_acceleration
			if jump_parameter > max_jump_speed:
				jump_parameter = max_jump_speed
		
		if Input.is_action_just_released(input_up):
			animation.animation = "boost"
			is_jumping = true
			apply_impulse(jump_parameter * Vector2.UP.rotated(rotation))
			await wait_jump_end()
			animation.animation = "default"
			jump_parameter = 0.0
			is_jumping = false
	
	var rot_direction : float = Input.get_axis(input_left, input_right)
	if rot_direction != 0.0:
		
		set_deferred("angular_velocity", rot_direction * rot_parameter)
		rot_parameter = min(rot_parameter + rot_acceleration * delta, max_rot_speed)
	else:
		rot_parameter = 1.0

func _process(delta: float) -> void:
	if is_attacked_rear:
		apply_damage(rear_damage)

func tackle_impulse(velocity : Vector2, opponent : RigidBody2D):
	set_deferred("lock_rotation", true)
	set_deferred("freeze", true)
	opponent.set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	
	effect_timer.start()
	await effect_timer.timeout
	effect_timer.stop()
	
	set_deferred("freeze", false)
	set_deferred("lock_rotation", false)
	
	apply_impulse(velocity)
	
	opponent.set_deferred("freeze", false)
	

# attack
func _on_damage_area_area_entered(area: Area2D) -> void:
	var opponent : RigidBody2D = area.get_parent()
	if area.is_in_group("attack_front")\
	and opponent.linear_velocity.length() >= minimum_tackle_speed:
		is_attacked_front = true
		apply_damage(opponent.get_attack_rear())
		var tackle_velocity : Vector2 = opponent.linear_velocity
		await tackle_impulse(tackle_velocity, opponent)
		
		is_attacked_front = false
		
	elif area.is_in_group("attack_rear"):
		rear_damage = opponent.get_attack_rear()
		is_attacked_rear = true

func _on_damage_area_area_exited(area : Area2D) -> void:
	var opponent : RigidBody2D = area.get_parent()
	if area.is_in_group("attack_rear"):
		modulate = NORMAL_COLOR
		is_attacked_rear = false

# bounce
func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	var shape_owner : int = shape_find_owner(local_shape_index)
	var shape : Object = shape_owner_get_owner(shape_owner)
	var opponent : RigidBody2D = shape.get_parent()
	if shape is CollisionPolygon2D\
	and !is_bounding\
	and !is_attacked_front\
	and linear_velocity.length() >= opponent.linear_velocity.length():
		is_bounding = true
		set_deferred("linear_velocity", linear_velocity * 1 * BOUNCE_COEFFICIENT)
		opponent.set_deferred("linear_velocity", linear_velocity * BOUNCE_COEFFICIENT * -1)



func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	var shape_owner : int = shape_find_owner(local_shape_index)
	var shape : Object = shape_owner_get_owner(shape_owner)
	
	if shape is CollisionPolygon2D\
	and is_bounding:
		is_bounding = false
