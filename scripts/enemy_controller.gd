
extends Node3D
class_name EnemyController

signal attack_started

@export var movement_speed: float = 2.0
@export var preferred_distance: float = 1.35
@export var attack_range: float = 1.65
@export var attack_cooldown: float = 1.8

@export var ring_center: Vector3 = Vector3.ZERO
@export var ring_half_extents: Vector2 = Vector2(2.8, 2.8)
@export var ring_margin: float = 0.45

var target: Node3D
var combat_manager: CombatManager
var visual_root: Node3D

var cooldown_timer: float = 0.0
var stagger_timer: float = 0.0

const ENEMY_ATTACK := {
	"damage": 10.0,
	"range": 1.65,
	"block_cost": 8.0
}


func setup(
	player_node: Node3D,
	manager: CombatManager,
	visual: Node3D
) -> void:
	target = player_node
	combat_manager = manager
	visual_root = visual

	if is_instance_valid(visual_root):
		global_position = visual_root.global_position
		global_rotation = visual_root.global_rotation


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	if not is_instance_valid(combat_manager):
		return

	if combat_manager.fight_over:
		return

	cooldown_timer = maxf(0.0, cooldown_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)

	_face_target()

	if stagger_timer > 0.0:
		return

	_update_position(delta)

	var distance := _get_target_distance()

	if distance <= attack_range and cooldown_timer <= 0.0:
		_attack()


func _update_position(delta: float) -> void:
	if not is_instance_valid(target):
		return

	var direction := target.global_position - global_position
	direction.y = 0.0

	var distance := direction.length()

	if distance < 0.001:
		return

	direction = direction.normalized()

	var movement := Vector3.ZERO

	if distance > preferred_distance + 0.15:
		movement = direction
	elif distance < preferred_distance - 0.25:
		movement = -direction

	global_position += movement * movement_speed * delta

	_apply_ring_boundaries()
	_sync_visual()


func _face_target() -> void:
	if not is_instance_valid(target):
		return

	var direction := target.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	direction = direction.normalized()

	rotation.y = atan2(-direction.x, -direction.z)

	_sync_visual()


func _sync_visual() -> void:
	if not is_instance_valid(visual_root):
		return

	visual_root.global_position = global_position
	visual_root.global_rotation.y = global_rotation.y


func _get_target_distance() -> float:
	if not is_instance_valid(target):
		return INF

	var difference := target.global_position - global_position
	difference.y = 0.0

	return difference.length()


func _attack() -> void:
	if not is_instance_valid(combat_manager):
		return

	cooldown_timer = attack_cooldown
	attack_started.emit()

	combat_manager.resolve_enemy_attack(
		self,
		target,
		ENEMY_ATTACK
	)


func on_hit(_damage: float = 0.0) -> void:
	stagger_timer = 0.18


func _apply_ring_boundaries() -> void:
	var min_x := ring_center.x - ring_half_extents.x + ring_margin
	var max_x := ring_center.x + ring_half_extents.x - ring_margin
	var min_z := ring_center.z - ring_half_extents.y + ring_margin
	var max_z := ring_center.z + ring_half_extents.y - ring_margin

	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.z = clampf(global_position.z, min_z, max_z)
	global_position.y = 0.0

	_sync_visual()
