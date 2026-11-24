
extends Node
class_name PlayerCombat

signal attack_performed(move_name: String)

enum CombatState {
	IDLE,
	WINDUP,
	ACTIVE,
	RECOVERY,
	BLOCKING
}

var state: CombatState = CombatState.IDLE

var player: PlayerController
var target: Node3D
var combat_manager: CombatManager

var attack_elapsed: float = 0.0
var attack_resolved: bool = false
var current_move: Dictionary = {}

var block_active: bool = false

const ATTACKS := {
	"jab": {
		"damage": 8.0,
		"stamina": 7.0,
		"range": 1.65,
		"windup": 0.12,
		"active": 0.08,
		"recovery": 0.22,
		"facing": 0.15
	},
	"cross": {
		"damage": 13.0,
		"stamina": 12.0,
		"range": 1.75,
		"windup": 0.20,
		"active": 0.10,
		"recovery": 0.38,
		"facing": 0.15
	},
	"hook": {
		"damage": 16.0,
		"stamina": 16.0,
		"range": 1.50,
		"windup": 0.28,
		"active": 0.12,
		"recovery": 0.52,
		"facing": 0.05
	},
	"uppercut": {
		"damage": 19.0,
		"stamina": 19.0,
		"range": 1.40,
		"windup": 0.32,
		"active": 0.10,
		"recovery": 0.62,
		"facing": 0.05
	}
}


func _ready() -> void:
	_create_combat_inputs()


func setup(
	player_node: PlayerController,
	target_node: Node3D,
	manager: CombatManager
) -> void:
	player = player_node
	target = target_node
	combat_manager = manager

	if is_instance_valid(combat_manager):
		combat_manager.set_player_combat(self)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if not is_instance_valid(combat_manager):
		return

	if combat_manager.fight_over:
		return

	if state == CombatState.BLOCKING:
		_process_blocking(delta)
		return

	if state != CombatState.IDLE:
		_process_attack(delta)
		return

	if Input.is_action_pressed("block"):
		_start_blocking()
		return

	if Input.is_action_just_pressed("dodge"):
		_try_dodge()
		return

	if Input.is_action_just_pressed("attack_jab"):
		_try_attack("jab")
	elif Input.is_action_just_pressed("attack_cross"):
		_try_attack("cross")
	elif Input.is_action_just_pressed("attack_hook"):
		_try_attack("hook")
	elif Input.is_action_just_pressed("attack_uppercut"):
		_try_attack("uppercut")
	else:
		combat_manager.recover_player_stamina(5.0 * delta)


func _try_attack(move_name: String) -> void:
	if not ATTACKS.has(move_name):
		return

	if state != CombatState.IDLE:
		return

	var move: Dictionary = ATTACKS[move_name]

	if not combat_manager.spend_player_stamina(
		float(move["stamina"])
	):
		return

	current_move = move.duplicate()
	current_move["name"] = move_name

	attack_elapsed = 0.0
	attack_resolved = false
	state = CombatState.WINDUP


func _process_attack(delta: float) -> void:
	attack_elapsed += delta

	var windup := float(current_move["windup"])
	var active := float(current_move["active"])
	var recovery := float(current_move["recovery"])

	if state == CombatState.WINDUP:
		if attack_elapsed >= windup:
			state = CombatState.ACTIVE
			_resolve_attack()

	elif state == CombatState.ACTIVE:
		if attack_elapsed >= windup + active:
			state = CombatState.RECOVERY

	elif state == CombatState.RECOVERY:
		if attack_elapsed >= windup + active + recovery:
			state = CombatState.IDLE
			current_move.clear()
			attack_elapsed = 0.0
			attack_resolved = false


func _resolve_attack() -> void:
	if attack_resolved:
		return

	attack_resolved = true

	if not is_instance_valid(target):
		return

	if not is_instance_valid(combat_manager):
		return

	var move_name := str(current_move["name"])
	attack_performed.emit(move_name)

	combat_manager.resolve_player_attack(
		player,
		target,
		move_name,
		current_move
	)


func _start_blocking() -> void:
	state = CombatState.BLOCKING
	block_active = true


func _process_blocking(delta: float) -> void:
	if not Input.is_action_pressed("block"):
		block_active = false
		state = CombatState.IDLE
		return

	var stamina_cost := 8.0 * delta

	if not combat_manager.spend_player_stamina(stamina_cost):
		block_active = false
		state = CombatState.IDLE


func _try_dodge() -> void:
	if not is_instance_valid(player):
		return

	if not combat_manager.spend_player_stamina(12.0):
		return

	var direction := Vector3.ZERO

	if Input.is_action_pressed("move_left"):
		direction = -player.global_transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction = player.global_transform.basis.x
	elif Input.is_action_pressed("move_forward"):
		direction = player._get_target_forward()
	elif Input.is_action_pressed("move_back"):
		direction = -player._get_target_forward()
	else:
		direction = -player._get_target_forward()

	player.perform_dodge(direction)


func is_blocking() -> bool:
	return state == CombatState.BLOCKING and block_active


func _create_combat_inputs() -> void:
	_add_key_action("attack_jab", KEY_J)
	_add_key_action("attack_cross", KEY_K)
	_add_key_action("attack_hook", KEY_L)
	_add_key_action("attack_uppercut", KEY_I)
	_add_key_action("block", KEY_SHIFT)
	_add_key_action("dodge", KEY_SPACE)


func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event := InputEventKey.new()
	event.keycode = key

	InputMap.action_add_event(action_name, event)
