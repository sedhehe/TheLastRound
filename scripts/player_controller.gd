
extends CharacterBody3D
class_name PlayerController

@export var move_speed: float = 4.2
@export var dodge_speed: float = 8.0
@export var dodge_duration: float = 0.22
@export var eye_height: float = 1.62

@export var ring_center: Vector3 = Vector3.ZERO
@export var ring_half_extents: Vector2 = Vector2(2.8, 2.8)
@export var ring_margin: float = 0.45

var target: Node3D
var camera: Camera3D

var is_dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	_create_collision()
	_create_camera()
	_create_movement_inputs()


func _physics_process(delta: float) -> void:
	if is_dodging:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			is_dodging = false
			_dodge_velocity = Vector3.ZERO

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var forward := _get_target_forward()
	var right := forward.cross(Vector3.UP).normalized()

	var movement := Vector3.ZERO

	if input_vector.length() > 0.0:
		movement += right * input_vector.x
		movement += forward * -input_vector.y
		movement = movement.normalized()

	var desired_velocity := movement * move_speed

	if is_dodging:
		desired_velocity = _dodge_velocity

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity.y = 0.0

	move_and_slide()

	_apply_ring_boundaries()
	_face_target()


func _process(_delta: float) -> void:
	_update_target_camera()


func setup_target(target_node: Node3D) -> void:
	target = target_node


func _get_target_forward() -> Vector3:
	if is_instance_valid(target):
		var direction := target.global_position - global_position
		direction.y = 0.0

		if direction.length_squared() > 0.001:
			return direction.normalized()

	return Vector3.FORWARD


func _face_target() -> void:
	if not is_instance_valid(target):
		return

	var direction := target.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	direction = direction.normalized()
	rotation.y = atan2(-direction.x, -direction.z)


func _update_target_camera() -> void:
	if not is_instance_valid(camera):
		return

	if not is_instance_valid(target):
		return

	var aim_point := target.global_position + Vector3.UP * 1.25
	camera.look_at(aim_point, Vector3.UP)


func perform_dodge(direction: Vector3) -> void:
	if is_dodging:
		return

	direction.y = 0.0

	if direction.length_squared() < 0.001:
		direction = -_get_target_forward()

	direction = direction.normalized()

	is_dodging = true
	_dodge_timer = dodge_duration
	_dodge_velocity = direction * dodge_speed


func _apply_ring_boundaries() -> void:
	var min_x := ring_center.x - ring_half_extents.x + ring_margin
	var max_x := ring_center.x + ring_half_extents.x - ring_margin
	var min_z := ring_center.z - ring_half_extents.y + ring_margin
	var max_z := ring_center.z + ring_half_extents.y - ring_margin

	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.z = clampf(global_position.z, min_z, max_z)
	global_position.y = 0.0


func _create_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "PlayerCollision"

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8

	collision.shape = capsule
	collision.position = Vector3(0.0, 0.9, 0.0)

	add_child(collision)


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 78.0
	camera.position = Vector3(0.0, eye_height, 0.0)
	camera.current = true

	add_child(camera)


func _create_movement_inputs() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)


func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event := InputEventKey.new()
	event.keycode = key

	InputMap.action_add_event(action_name, event)
