
extends Node
class_name CombatManager

signal player_stats_changed(health: float, stamina: float)
signal enemy_health_changed(health: float)
signal combat_log(message: String)
signal fight_ended(player_won: bool)

@export var player_max_health: float = 100.0
@export var player_max_stamina: float = 100.0
@export var enemy_max_health: float = 100.0

var player_health: float = 100.0
var player_stamina: float = 100.0
var enemy_health: float = 100.0

var player_actor: PlayerController
var enemy_actor: Node3D
var player_combat: PlayerCombat

var fight_over: bool = true


func _ready() -> void:
	# Combat stays inactive until begin_fight() is called.
	fight_over = true


func configure(
	player: PlayerController,
	enemy: Node3D
) -> void:
	player_actor = player
	enemy_actor = enemy


func set_player_combat(combat: PlayerCombat) -> void:
	player_combat = combat


func begin_fight(
	player_health_value: float,
	player_stamina_value: float,
	enemy_health_value: float
) -> void:
	reset_fight(
		player_health_value,
		player_stamina_value,
		enemy_health_value
	)

	fight_over = false
	combat_log.emit("The fight has begun.")


func reset_fight(
	player_health_value: float = -1.0,
	player_stamina_value: float = -1.0,
	enemy_health_value: float = -1.0
) -> void:
	# Keep combat disabled while resetting.
	fight_over = true

	player_health = (
		player_max_health
		if player_health_value < 0.0
		else maxf(0.0, player_health_value)
	)

	player_stamina = (
		player_max_stamina
		if player_stamina_value < 0.0
		else maxf(0.0, player_stamina_value)
	)

	enemy_health = (
		enemy_max_health
		if enemy_health_value < 0.0
		else maxf(0.0, enemy_health_value)
	)

	_emit_player_stats()
	enemy_health_changed.emit(enemy_health)


# --------------------------------------------------
# PLAYER STAMINA
# --------------------------------------------------

func spend_player_stamina(amount: float) -> bool:
	if fight_over:
		return false

	if amount < 0.0 or player_stamina < amount:
		return false

	player_stamina = maxf(0.0, player_stamina - amount)
	_emit_player_stats()

	return true


func drain_player_stamina(amount: float) -> void:
	if fight_over:
		return

	player_stamina = maxf(
		0.0,
		player_stamina - maxf(0.0, amount)
	)

	_emit_player_stats()


func recover_player_stamina(amount: float) -> void:
	if fight_over:
		return

	player_stamina = minf(
		player_max_stamina,
		player_stamina + maxf(0.0, amount)
	)

	_emit_player_stats()


# --------------------------------------------------
# PLAYER ATTACK RESOLUTION
# --------------------------------------------------

func resolve_player_attack(
	attacker: Node3D,
	target: Node3D,
	attack_name: String,
	data: Dictionary
) -> void:
	if fight_over:
		return

	if not is_instance_valid(attacker):
		return

	if not is_instance_valid(target):
		return

	var distance := _horizontal_distance(attacker, target)
	var attack_range := float(data.get("range", 0.0))

	if distance > attack_range:
		combat_log.emit("Missed — out of range.")
		return

	# Check that the target is in front of the attacker.
	var direction := target.global_position - attacker.global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	direction = direction.normalized()

	var forward := -attacker.global_transform.basis.z
	forward.y = 0.0

	if forward.length_squared() < 0.001:
		return

	forward = forward.normalized()

	var facing := forward.dot(direction)
	var required_facing := float(data.get("facing", 0.0))

	if facing < required_facing:
		combat_log.emit("Missed — opponent wasn't in front.")
		return

	var damage := maxf(0.0, float(data.get("damage", 0.0)))

	enemy_health = maxf(0.0, enemy_health - damage)

	enemy_health_changed.emit(enemy_health)

	combat_log.emit(
		"%s connected for %d damage."
		% [attack_name.capitalize(), int(damage)]
	)

	if is_instance_valid(enemy_actor):
		if enemy_actor.has_method("on_hit"):
			enemy_actor.call("on_hit", damage)

	_check_fight_end()


# --------------------------------------------------
# ENEMY ATTACK RESOLUTION
# --------------------------------------------------

func resolve_enemy_attack(
	attacker: Node3D,
	target: Node3D,
	data: Dictionary
) -> void:
	if fight_over:
		return

	if not is_instance_valid(attacker):
		return

	if not is_instance_valid(target):
		return

	# Dodging avoids the attack entirely.
	var player_target := target as PlayerController

	if player_target != null and player_target.is_dodging:
		combat_log.emit("You dodged the attack.")
		return

	var distance := _horizontal_distance(attacker, target)
	var attack_range := float(data.get("range", 0.0))

	if distance > attack_range:
		return

	# Ensure the player is in front of the enemy.
	var direction := target.global_position - attacker.global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	direction = direction.normalized()

	var forward := -attacker.global_transform.basis.z
	forward.y = 0.0

	if forward.length_squared() < 0.001:
		return

	forward = forward.normalized()

	if forward.dot(direction) < 0.0:
		return

	var damage := maxf(0.0, float(data.get("damage", 0.0)))

	# Blocking reduces incoming damage.
	if is_instance_valid(player_combat) and player_combat.is_blocking():
		var block_cost := float(data.get("block_cost", 8.0))

		if player_stamina >= block_cost:
			drain_player_stamina(block_cost)
			damage *= 0.25

			combat_log.emit("Blocked. Reduced damage.")
		else:
			# Guard breaks when stamina is insufficient.
			combat_log.emit("Guard broken!")

			player_combat.state = PlayerCombat.CombatState.IDLE

	player_health = maxf(0.0, player_health - damage)

	_emit_player_stats()

	combat_log.emit(
		"You took %d damage." % int(damage)
	)

	_check_fight_end()


# --------------------------------------------------
# HELPERS
# --------------------------------------------------

func _horizontal_distance(a: Node3D, b: Node3D) -> float:
	var a_pos := a.global_position
	var b_pos := b.global_position

	a_pos.y = 0.0
	b_pos.y = 0.0

	return a_pos.distance_to(b_pos)


func _emit_player_stats() -> void:
	player_stats_changed.emit(
		player_health,
		player_stamina
	)


# --------------------------------------------------
# FIGHT END
# --------------------------------------------------

func _check_fight_end() -> void:
	if fight_over:
		return

	if enemy_health <= 0.0:
		fight_over = true

		combat_log.emit("Opponent knocked out.")
		fight_ended.emit(true)

	elif player_health <= 0.0:
		fight_over = true

		combat_log.emit("You were knocked out.")
		fight_ended.emit(false)
