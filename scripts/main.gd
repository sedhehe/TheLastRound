
extends Node3D
# UNDERDOG: self-contained playable vertical slice / tournament prototype.

const ARENA_VISUALS = preload("res://scripts/arena_visuals.gd")
const MOVE_FILE = "res://data/moves.json"
const ENEMY_FILE = "res://data/enemies.json"
const ITEM_FILE = "res://data/items.json"
const SAVE_PATH = "user://underdog_save.json"
const META_PATH = "user://underdog_meta.json"

const FIGHT_COUNT := 8
# Four opening opponents, two rematches in the semi-finals, the eliminator,
# then the final champion. Rematches scale with fight_index.
const FIGHT_ROSTER := [0, 1, 2, 3, 1, 2, 4, 5]

var player_controller: PlayerController
var player_combat: PlayerCombat
var enemy_controller: EnemyController
var combat_manager: CombatManager

var rng := RandomNumberGenerator.new()
var moves: Array = []
var enemy_templates: Array = []
var item_templates: Array = []

var player: Dictionary = {}
var enemy: Dictionary = {}

var owned_moves: Array[String] = ["jab", "block", "rest"]
var inventory: Array = []
var passive: Dictionary = {}

var fight_index := 0
var round_no := 1
var turn_no := 1

var player_blocking := false
var player_slipping := false
var enemy_blinded := 0
var enemy_drained := 0
var loaded_bonus := 0
var loaded_tape_risk := false
var energy_penalty_pending := false
var next_fight_speed_bonus := 0.0
var enemy_next_action: Dictionary = {}

var bribe_ready := false
var revive_used := false
var heart_active := false

var game_state := "menu"
var run_ended := false
var respect := 0
var lifetime_respect := 0
var run_seed := 0

var log_lines: Array[String] = []

var root_ui: Control
var panel: PanelContainer
var content: VBoxContainer
var ui_scroll: ScrollContainer
var player_last_move_id := ""

var arena_light: OmniLight3D
var opponent_mesh: Node3D
var opponent_mat: StandardMaterial3D
var camera: Camera3D
var arena_visuals: Node3D

var screen_shake := false
var crt_enabled := true

var player_start_position := Vector3(0.0, 0.0, 2.1)
var enemy_start_position := Vector3.ZERO


func _ready() -> void:
	rng.randomize()

	_load_meta()
	moves = _read_json(MOVE_FILE)
	enemy_templates = _read_json(ENEMY_FILE)
	item_templates = _read_json(ITEM_FILE)

	_build_world()
	_build_ui()
	_show_main_menu()


func _read_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open " + path)
		return []

	var parsed = JSON.parse_string(file.get_as_text())

	if parsed is Array:
		return parsed

	push_error("Invalid JSON array in " + path)
	return []


# ---------------------------------------------------------
# WORLD AND COMBAT SETUP
# ---------------------------------------------------------

func _build_world() -> void:
	arena_visuals = ARENA_VISUALS.new()
	arena_visuals.name = "ArenaVisuals"
	add_child(arena_visuals)

	var refs: Dictionary = arena_visuals.build()

	camera = refs.get("camera")
	arena_light = refs.get("arena_light")
	opponent_mesh = refs.get("opponent_mesh")
	opponent_mat = refs.get("opponent_mat")

	if is_instance_valid(camera):
		camera.current = false

	combat_manager = CombatManager.new()
	combat_manager.name = "CombatManager"
	add_child(combat_manager)

	player_controller = PlayerController.new()
	player_controller.name = "Player"
	add_child(player_controller)

	player_controller.global_position = player_start_position
	player_controller.set_physics_process(false)

	enemy_controller = EnemyController.new()
	enemy_controller.name = "EnemyController"
	add_child(enemy_controller)

	if is_instance_valid(opponent_mesh):
		enemy_start_position = opponent_mesh.global_position
		enemy_controller.global_position = enemy_start_position

	enemy_controller.setup(
		player_controller,
		combat_manager,
		opponent_mesh
	)

	player_controller.setup_target(enemy_controller)
	arena_visuals.attach_player_camera(player_controller.camera)

	combat_manager.configure(
		player_controller,
		enemy_controller
	)

	player_combat = PlayerCombat.new()
	player_combat.name = "PlayerCombat"
	player_controller.add_child(player_combat)

	player_combat.setup(
		player_controller,
		enemy_controller,
		combat_manager
	)

	player_combat.set_process(false)
	enemy_controller.set_process(false)

	combat_manager.combat_log.connect(_on_combat_log)
	combat_manager.fight_ended.connect(_on_realtime_fight_ended)


func _on_combat_log(message: String) -> void:
	_log(message)
	print("[UNDERDOG] ", message)


func _on_realtime_fight_ended(player_won: bool) -> void:
	if game_state != "combat":
		return

	_disable_realtime_combat()

	if player_won:
		_win_fight()
	else:
		_end_run(false, "You were knocked out.")


func _enable_realtime_combat() -> void:
	if is_instance_valid(player_controller):
		player_controller.set_physics_process(true)

	if is_instance_valid(player_combat):
		player_combat.set_process(true)

	if is_instance_valid(enemy_controller):
		enemy_controller.set_process(true)


func _disable_realtime_combat() -> void:
	if is_instance_valid(player_controller):
		player_controller.set_physics_process(false)
		player_controller.velocity = Vector3.ZERO
		player_controller.is_dodging = false

	if is_instance_valid(player_combat):
		player_combat.set_process(false)
		player_combat.state = PlayerCombat.CombatState.IDLE

	if is_instance_valid(enemy_controller):
		enemy_controller.set_process(false)


func _reset_fighter_positions() -> void:
	if is_instance_valid(player_controller):
		player_controller.global_position = player_start_position
		player_controller.velocity = Vector3.ZERO
		player_controller.rotation = Vector3.ZERO

	if is_instance_valid(enemy_controller):
		enemy_controller.global_position = enemy_start_position
		enemy_controller.rotation = Vector3.ZERO

	if is_instance_valid(opponent_mesh):
		opponent_mesh.global_position = enemy_start_position
		opponent_mesh.global_rotation = Vector3.ZERO


func _configure_enemy_ai() -> void:
	if not is_instance_valid(enemy_controller):
		return

	enemy_controller.movement_speed = float(enemy.get("speed", 2.0)) * 0.12
	enemy_controller.movement_speed = clampf(
		enemy_controller.movement_speed,
		1.2,
		3.8
	)

	enemy_controller.attack_range = 1.65
	enemy_controller.preferred_distance = 1.35

	var damage_value := float(enemy.get("damage", 10.0))
	enemy_controller.attack_cooldown = clampf(
		2.0 - damage_value * 0.025,
		0.85,
		1.8
	)


func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


# ---------------------------------------------------------
# UI
# ---------------------------------------------------------

func _build_ui() -> void:
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_ui)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.012, 0.018, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(shade)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	root_ui.add_child(panel)

	ui_scroll = ScrollContainer.new()
	ui_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ui_scroll.follow_focus = true
	ui_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(ui_scroll)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_scroll.add_child(content)

	root_ui.resized.connect(_layout_ui)
	_layout_ui()


func _layout_ui() -> void:
	if not is_instance_valid(panel) or not is_instance_valid(root_ui):
		return

	var viewport_size := root_ui.size
	var margin := 20.0
	var available_width := maxf(240.0, viewport_size.x - margin * 2.0)
	var available_height := maxf(180.0, viewport_size.y - margin * 2.0)

	panel.position = Vector2(margin, margin)
	panel.size = Vector2(
		minf(500.0, available_width),
		minf(660.0, available_height)
	)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.03, 0.035, 0.94)
	style.border_color = Color(0.43, 0.16, 0.12)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _clear_ui() -> void:
	for child in content.get_children():
		child.queue_free()

	if is_instance_valid(ui_scroll):
		ui_scroll.scroll_vertical = 0


func _label(
	text: String,
	size: int = 16,
	color: Color = Color(0.88, 0.84, 0.79)
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)
	return label


func _button(
	text: String,
	callback: Callable,
	disabled: bool = false
) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override(
		"font_color",
		Color(0.95, 0.9, 0.84)
	)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.075, 0.065)
	style.border_color = Color(0.52, 0.23, 0.17)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override(
		"hover",
		_button_style(Color(0.32, 0.11, 0.08))
	)
	button.add_theme_stylebox_override(
		"disabled",
		_button_style(Color(0.09, 0.08, 0.08))
	)

	button.pressed.connect(callback)
	content.add_child(button)
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.52, 0.23, 0.17)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _heading(fighter_name: String, sub: String) -> void:
	_clear_ui()
	_label(fighter_name, 30, Color(0.9, 0.36, 0.22))
	_label(sub, 14, Color(0.65, 0.61, 0.58))

	var line := HSeparator.new()
	content.add_child(line)


# ---------------------------------------------------------
# MENUS AND RUN START
# ---------------------------------------------------------

func _show_main_menu() -> void:
	game_state = "menu"
	_disable_realtime_combat()

	_heading("UNDERDOG", "NO CONTRACT. NO CORNER. NO WAY OUT.")
	_label("An underground boxing roguelike.", 17)
	_label("Eight fights stand between you and the Crown.", 14)
	_label("CAREER RESPECT: %d  |  RANK: %s" % [lifetime_respect, _respect_rank()], 14, Color(0.88, 0.68, 0.38))
	_label("CAREER PERKS: " + _career_perk_summary(), 12, Color(0.72, 0.82, 0.68))

	_button("NEW RUN", _new_run)
	_button(
		"CONTINUE",
		_continue_run,
		not FileAccess.file_exists(SAVE_PATH)
	)
	_button("CODEX", _show_codex)
	_button("SETTINGS", _show_settings)

	_label(
		"A fight is a conversation. Make sure you get the last word.",
		13,
		Color(0.62, 0.54, 0.50)
	)


func _new_run() -> void:
	run_ended = false
	run_seed = int(Time.get_unix_time_from_system())
	rng.seed = run_seed

	fight_index = 0
	round_no = 1
	turn_no = 1

	owned_moves = ["jab", "block", "rest"]
	inventory = ["ice"]

	passive = {
		"damage": 0.0,
		"health": 0.0,
		"stamina": 0.0,
		"defence": 0.0,
		"speed": 0.0,
		"slots": 0,
		"wind": 0
	}

	revive_used = false
	respect = 0
	bribe_ready = false
	heart_active = false
	loaded_bonus = 0
	loaded_tape_risk = false
	energy_penalty_pending = false
	next_fight_speed_bonus = 0.0
	enemy_next_action.clear()
	log_lines.clear()

	player = {
		"health": 100.0,
		"max_health": 100.0,
		"stamina": 100.0,
		"max_stamina": 100.0,
		"damage": 10.0,
		"speed": 10.0,
		"defence": 5.0,
		"heart": false,
		"knockdowns": 0
	}
	_apply_career_perks()

	_start_fight()


# ---------------------------------------------------------
# FIGHT SETUP
# ---------------------------------------------------------

func _start_fight() -> void:
	if enemy_templates.is_empty():
		push_error("No enemy templates were loaded.")
		_end_run(false, "No opponents could be loaded.")
		return

	if fight_index >= FIGHT_COUNT:
		_end_run(true, "You became the underground champion.")
		return

	game_state = "combat"

	round_no = 1
	turn_no = 1
	player_blocking = false
	player_slipping = false
	enemy_blinded = 0
	enemy_drained = 0
	loaded_bonus = 0
	loaded_tape_risk = false
	energy_penalty_pending = false
	player.speed = minf(60.0, float(player.get("speed", 0.0)) + next_fight_speed_bonus)
	next_fight_speed_bonus = 0.0
	enemy_next_action.clear()
	player_last_move_id = ""
	_disable_realtime_combat()

	var roster_index := _opponent_template_index(fight_index)
	if roster_index < 0 or roster_index >= enemy_templates.size():
		push_error("Tournament roster references a missing opponent.")
		_end_run(false, "The next opponent could not be loaded.")
		return

	var template: Dictionary = enemy_templates[roster_index].duplicate(true)

	var visual_scale := 1.0 + float(fight_index) * 0.115

	enemy = {
		"name": template.get("name", "Unknown Fighter"),
		"archetype": template.get("archetype", "Boxer"),
		"health": float(template.get("health", 100.0)) * visual_scale,
		"max_health": float(template.get("health", 100.0)) * visual_scale,
		"stamina": float(template.get("stamina", 100.0)) * visual_scale,
		"max_stamina": float(template.get("stamina", 100.0)) * visual_scale,
		"damage": float(template.get("damage", 10.0)) * (1.0 + fight_index * 0.07),
		"speed": float(template.get("speed", 10.0)) + fight_index * 1.2,
		"defence": float(template.get("defence", 5.0)) + fight_index * 0.7,
		"tell": template.get("tell", ""),
		"trick": template.get("trick", ""),
		"accuracy": 82.0
	}

	if fight_index == 7:
		enemy["name"] = "THE UNDERTAKER"
		enemy["archetype"] = "Final Champion"
		enemy_mat_color(Color(0.12, 0.10, 0.12))
	else:
		enemy_mat_color(Color(0.34, 0.19, 0.16))

	_configure_enemy_ai()
	_reset_fighter_positions()

	# Turn-based combat is authoritative. Keep the real-time actors disabled.
	_disable_realtime_combat()
	_prepare_enemy_telegraph()
	_show_combat()




func enemy_mat_color(color: Color) -> void:
	if is_instance_valid(opponent_mat):
		opponent_mat.albedo_color = color


func _get_move(id: String) -> Dictionary:
	for move in moves:
		if str(move.get("id", "")) == id:
			return move
	return {}


func _get_item_name(id: String) -> String:
	for item in item_templates:
		if str(item.get("id", "")) == id:
			return str(item.get("name", id))
	return id.replace("_", " ").capitalize()

func _get_item_data(id: String) -> Dictionary:
	for item in item_templates:
		if str(item.get("id", "")) == id:
			return item
	return {}


func _item_timing(id: String) -> String:
	match id:
		"ice":
			return "Between fights — restore 22 health in the hub."
		"salts":
			return "Passive — automatically revive once after a lethal hit."
		"crowd":
			return "Combat-use — activate during a fight; +5 speed for the next fight."
		_:
			return "Combat-use — activate during your turn."


func _move_reward_details(move: Dictionary) -> String:
	var details: Array[String] = []
	var cost := int(move.get("cost", 0))
	var accuracy := int(move.get("accuracy", 100.0))
	var damage: Array = move.get("damage", [0, 0])

	details.append("%d stamina" % cost)
	details.append("%d%% accuracy" % accuracy)

	if damage.size() >= 2 and (float(damage[0]) > 0.0 or float(damage[1]) > 0.0):
		details.append("%d–%d base damage" % [int(damage[0]), int(damage[1])])
	else:
		details.append(str(move.get("kind", "utility")).capitalize() + " move")

	details.append(str(move.get("description", "")))
	return " | ".join(details)


func _show_salts_status() -> void:
	if revive_used:
		_label(
			"LAST STAND — SPENT | Smelling Salts were used. No second revive this run.",
			13,
			Color(0.95, 0.62, 0.35)
		)
	elif inventory.has("salts"):
		_label(
			"LAST STAND — READY | Smelling Salts are in your bag. They automatically revive you from a lethal hit with 30 HP.",
			13,
			Color(0.55, 0.85, 0.65)
		)
	else:
		_label(
			"LAST STAND — NOT IN YOUR BAG | Smelling Salts are not owned. Look for them in an ITEM reward after a fight.",
			13,
			Color(0.95, 0.72, 0.42)
		)


func _show_item_summary(include_active_effects: bool) -> void:
	_label("CORNER BAG — %d / 3 SLOTS" % inventory.size(), 15, Color(0.9, 0.36, 0.22))

	if inventory.is_empty():
		_label("No items in your corner bag.", 12)
	else:
		for item_variant in inventory:
			var item_id := str(item_variant)
			var item_data := _get_item_data(item_id)
			var item_name := str(item_data.get("name", _get_item_name(item_id)))
			var description := str(item_data.get("description", "No description available."))
			var status := _item_timing(item_id)

			_label(
				"%s — %s\n%s" % [item_name, description, status],
				12,
				Color(0.78, 0.73, 0.68)
			)

	var active_effects: Array[String] = []

	if not include_active_effects:
		if next_fight_speed_bonus > 0.0:
			active_effects.append("+%d speed is waiting for the next fight." % int(next_fight_speed_bonus))
		if float(passive.get("wind", 0.0)) > 0.0:
			active_effects.append("+%d stamina on a successful dodge." % int(passive.get("wind", 0.0)))

		if not active_effects.is_empty():
			_label("PERSISTENT / NEXT-FIGHT EFFECTS", 15, Color(0.9, 0.36, 0.22))
			for effect in active_effects:
				_label("• " + effect, 12, Color(0.82, 0.76, 0.68))
		return

	if enemy_blinded > 0:
		active_effects.append("Opponent accuracy reduced for %d more turn(s)." % enemy_blinded)
	if enemy_drained > 0:
		active_effects.append("Opponent loses 8 stamina for %d more turn(s)." % enemy_drained)
	if loaded_bonus > 0:
		active_effects.append("Next landed attack gains +%d damage." % loaded_bonus)
	if loaded_tape_risk:
		active_effects.append("Loaded tape disqualification risk is pending.")
	if bribe_ready:
		active_effects.append("Next dirty move is protected from disqualification.")
	if energy_penalty_pending:
		active_effects.append("Energy drink crash: lose 10 stamina after the enemy response.")
	if next_fight_speed_bonus > 0.0:
		active_effects.append("+%d speed is waiting for the next fight." % int(next_fight_speed_bonus))
	if float(passive.get("wind", 0.0)) > 0.0:
		active_effects.append("+%d stamina on a successful dodge." % int(passive.get("wind", 0.0)))

	_label("ACTIVE EFFECTS", 15, Color(0.9, 0.36, 0.22))
	if active_effects.is_empty():
		_label("No temporary effects currently active.", 12)
	else:
		for effect in active_effects:
			_label("• " + effect, 12, Color(0.82, 0.76, 0.68))


# ---------------------------------------------------------
# TURN-BASED COMBAT SCREEN
# ---------------------------------------------------------

func _show_combat() -> void:
	_heading(
		"FIGHT %d — %s" % [fight_index + 1, str(enemy.get("name", "OPPONENT"))],
		"ROUND %d  |  TURN %d / 6" % [round_no, turn_no]
	)

	_label(
		"YOU     HP %d/%d     STA %d/%d" % [
			int(player.get("health", 0)),
			int(player.get("max_health", 100)),
			int(player.get("stamina", 0)),
			int(player.get("max_stamina", 100))
		],
		16,
		Color(0.55, 0.82, 0.95)
	)
	_show_salts_status()
	_label(
		"OPPONENT     HP %d/%d     STA %d/%d" % [
			int(enemy.get("health", 0)),
			int(enemy.get("max_health", 100)),
			int(enemy.get("stamina", 0)),
			int(enemy.get("max_stamina", 100))
		],
		15,
		Color(0.95, 0.62, 0.48)
	)

	_show_item_summary(true)

	var tell := str(enemy_next_action.get("tell", enemy.get("tell", "Studies your guard.")))
	var action_name := str(enemy_next_action.get("name", "Unknown attack"))
	_label("THEY'RE TELEGRAPHING: " + tell, 15, Color(1.0, 0.76, 0.35))
	_label("Expected action: " + action_name, 13, Color(0.82, 0.72, 0.62))

	var line := HSeparator.new()
	content.add_child(line)
	_label("CHOOSE YOUR MOVE", 18, Color(0.9, 0.36, 0.22))

	for id in owned_moves:
		var move := _get_move(str(id))
		if move.is_empty():
			continue

		var cost := float(move.get("cost", 0.0))
		var move_name := str(move.get("name", id))
		var description := str(move.get("description", ""))
		var label_text := "%s  [%d STA] — %s" % [
			move_name,
			int(cost),
			description
		]
		_button(
			label_text,
			_player_move.bind(str(id)),
			float(player.get("stamina", 0.0)) < cost
		)

	# Show every combat-usable item. Passive and between-fight items
	# remain in the bag without blocking items stored behind them.
	var usable_item_count := 0
	for item_variant in inventory:
		var item_id := str(item_variant)
		if item_id in ["ice", "salts"]:
			continue

		usable_item_count += 1
		_button(
			"USE ITEM: " + _get_item_name(item_id),
			_use_item.bind(item_id)
		)

	if usable_item_count == 0 and not inventory.is_empty():
		_label("CORNER ITEMS: Ice is saved for the hub; Smelling Salts trigger on a knockout.", 12)

	_label("RECENT CORNER TALK", 13, Color(0.68, 0.58, 0.52))
	var first_log := maxi(0, log_lines.size() - 3)
	for i in range(first_log, log_lines.size()):
		_label("• " + log_lines[i], 12, Color(0.72, 0.68, 0.64))

	_button("FORFEIT RUN", _forfeit_run)



func _forfeit_run() -> void:
	_disable_realtime_combat()
	_end_run(false, "You walked away from the fight.")


# ---------------------------------------------------------
# TURN-BASED COMBAT RESOLUTION
# ---------------------------------------------------------

func _speed_chance(speed: float) -> float:
	return clampf(speed, 0.0, 60.0)


func _player_move(id: String) -> void:
	if game_state != "combat":
		return

	if not owned_moves.has(id):
		return

	player_last_move_id = id
	var move := _get_move(id)
	if move.is_empty():
		return

	var cost := float(move.get("cost", 0))
	if float(player.get("stamina", 0.0)) < cost:
		_log("You're too exhausted to use %s." % str(move.get("name", id)))
		_show_combat()
		return

	if arena_visuals and arena_visuals.has_method("player_action"):
		arena_visuals.player_action(id)

	if id == "rest":
		player.stamina = minf(
			player.max_stamina,
			player.stamina + 24.0
		)
		_log("You take a breath. +24 stamina. The opening is there.")

	elif id == "block":
		player.stamina = maxf(0.0, player.stamina - cost)
		player_blocking = true
		_log("You shell up behind your gloves.")

	elif id == "slip":
		player.stamina -= cost
		player_slipping = true
		_log("You prepare a sharp slip.")

	elif id == "feint":
		player.stamina -= cost
		enemy_blinded = maxi(enemy_blinded, 1)
		_log("Your feint makes the opponent hesitate.")

	elif id == "clinch":
		player.stamina -= cost
		enemy.stamina = maxf(0.0, enemy.stamina - 10.0)
		player.stamina = minf(player.max_stamina, player.stamina + 8.0)
		_log("You smother the attack in a clinch.")

	elif id == "counter":
		player.stamina -= cost

		var tell := str(enemy_next_action.get("tell", enemy.get("tell", ""))).to_lower()
		var action_name := str(enemy_next_action.get("name", "")).to_lower()
		var guessed := tell.contains("right") or tell.contains("loads") or action_name.contains("right")

		if guessed:
			_deal_player_damage(move, 1.35)
			_log("Perfect read! Counter lands hard.")
		else:
			_log("Wrong read. The counter misses its window.")

	elif id in ["headbutt", "low_blow"]:
		player.stamina -= cost

		if not bribe_ready and rng.randf() < (0.18 if id == "headbutt" else 0.27):
			_log("The referee catches the dirty move. DISQUALIFIED.")
			_end_run(false, "Disqualified for an illegal move.")
			return

		if bribe_ready:
			bribe_ready = false

		_deal_player_damage(move, 1.0)

		if id == "low_blow":
			enemy.stamina = maxf(0.0, enemy.stamina - 18.0)

	else:
		player.stamina -= cost
		_deal_player_damage(move, 1.0)

		if id == "body_shot":
			enemy.stamina = maxf(0.0, enemy.stamina - 12.0)

		if id == "haymaker" and rng.randf() < 0.2:
			player.stamina = maxf(0.0, player.stamina - 8.0)

		if id == "uppercut" and rng.randf() < 0.12:
			enemy.stamina = maxf(0.0, enemy.stamina - 15.0)

	if game_state != "combat":
		return

	player.stamina = clampf(player.stamina, 0.0, player.max_stamina)

	if enemy.health <= 0.0:
		_win_fight()
		return

	_enemy_turn()
	if energy_penalty_pending and game_state == "combat":
		player.stamina = maxf(0.0, player.stamina - 10.0)
		energy_penalty_pending = false
		_log("The energy drink crash costs 10 stamina.")
	# Defensive actions last for exactly one enemy response, even if it misses
	# or the opponent is too exhausted to attack.
	player_blocking = false
	player_slipping = false

	if game_state == "combat":
		_check_round()
		if game_state == "combat":
			_prepare_enemy_telegraph()
			_show_combat()


func _deal_player_damage(move: Dictionary, multiplier: float) -> void:
	if rng.randf() * 100.0 > float(move.get("accuracy", 100.0)):
		_log("%s misses. The crowd groans." % str(move.get("name", "Your move")))
		return

	var damage_range: Array = move.get("damage", [5.0, 10.0])
	if damage_range.size() < 2:
		return

	var amount := rng.randf_range(
		float(damage_range[0]),
		float(damage_range[1])
	)

	amount += float(player.get("damage", 0.0)) * 0.45
	amount *= multiplier
	amount += loaded_bonus
	loaded_bonus = 0

	if loaded_tape_risk:
		loaded_tape_risk = false
		if rng.randf() < 0.12:
			_log("The referee spots the loaded tape. DISQUALIFIED.")
			_end_run(false, "Disqualified for using loaded tape.")
			return

	var critical := id_is_crit()
	if critical:
		amount *= 1.5

	var reduced := maxf(
		1.0,
		amount * (1.0 - float(enemy.defence) / 100.0)
	)

	# Tanks keep a compact guard while they have stamina. Exhaust them to
	# remove this additional damage reduction.
	if str(enemy.get("trick", "")) == "guard" and float(enemy.stamina) > 0.0:
		reduced *= 0.88
		_log("Their tight guard absorbs part of the impact.")

	enemy.health = maxf(0.0, enemy.health - reduced)

	if arena_visuals and arena_visuals.has_method("opponent_hit"):
		arena_visuals.opponent_hit()

	if critical:
		_log("CRITICAL! %s lands for %d." % [
			str(move.get("name", "Your move")),
			int(reduced)
		])
	else:
		_log("%s connects for %d damage." % [
			str(move.get("name", "Your move")),
			int(reduced)
		])


func id_is_crit() -> bool:
	var chance := 0.05

	if player.health <= player.max_health * 0.25:
		chance += 0.08

	return rng.randf() < chance


func _prepare_enemy_telegraph() -> void:
	var trick := str(enemy.get("trick", "")).to_lower()
	var archetype := str(enemy.get("archetype", "")).to_lower()
	var options: Array[Dictionary] = []

	match trick:
		"aggressive":
			options = [
				{"name": "Heavy Right", "tell": "Loads up his right hand.", "damage": 1.25, "accuracy": 78.0, "cost": 14.0},
				{"name": "Pressure Jab", "tell": "Steps forward behind a quick jab.", "damage": 0.82, "accuracy": 91.0, "cost": 8.0}
			]
		"quick":
			options = [
				{"name": "Quick Flurry", "tell": "Bounces in, shoulders twitching.", "damage": 0.78, "accuracy": 92.0, "cost": 12.0},
				{"name": "Fast Jab", "tell": "Flicks a glove toward your guard.", "damage": 0.72, "accuracy": 95.0, "cost": 7.0}
			]
		"guard":
			options = [
				{"name": "Guarded Hook", "tell": "Tucks his chin, then loads a short hook.", "damage": 1.05, "accuracy": 82.0, "cost": 13.0},
				{"name": "Body Jab", "tell": "Keeps his guard high and dips toward your ribs.", "damage": 0.88, "accuracy": 89.0, "cost": 9.0}
			]
		"counter":
			options = [
				{"name": "Counter Right", "tell": "Leaves an opening and waits for you to commit.", "damage": 1.18, "accuracy": 88.0, "cost": 12.0},
				{"name": "Sharp Counter", "tell": "Shifts his weight onto the back foot.", "damage": 0.95, "accuracy": 93.0, "cost": 10.0}
			]
		"dirty":
			options = [
				{"name": "Elbow Smash", "tell": "Edges close with an elbow tucked.", "damage": 1.12, "accuracy": 82.0, "cost": 13.0},
				{"name": "Rough Body Shot", "tell": "Crowds you and dips below the guard.", "damage": 0.95, "accuracy": 89.0, "cost": 11.0}
			]
		_:
			options = [
				{"name": "Champion's Right", "tell": "Goes completely still, then draws back his right.", "damage": 1.35, "accuracy": 84.0, "cost": 16.0},
				{"name": "Champion's Combination", "tell": "Rolls his shoulders and steps into range.", "damage": 1.08, "accuracy": 91.0, "cost": 14.0},
				{"name": "Short Hook", "tell": "Turns his lead shoulder toward you.", "damage": 0.92, "accuracy": 94.0, "cost": 10.0}
			]

	if enemy.stamina < 18.0:
		enemy_next_action = {
			"name": "Desperate Swing",
			"tell": "Breathes heavily and drops his guard.",
			"damage": 0.72,
			"accuracy": 70.0,
			"cost": 5.0
		}
	else:
		enemy_next_action = options[rng.randi_range(0, options.size() - 1)].duplicate(true)

	# Keep the existing fighter-specific tell as a fallback for custom data.
	if str(enemy_next_action.get("tell", "")).is_empty():
		enemy_next_action["tell"] = str(enemy.get("tell", "Studies your guard."))


func _enemy_turn() -> void:
	if enemy_drained > 0:
		enemy.stamina = maxf(0.0, enemy.stamina - 8.0)
		enemy_drained -= 1

	if enemy.stamina <= 0.0:
		enemy.stamina = minf(
			enemy.max_stamina,
			enemy.stamina + 12.0
		)
		_log("Opponent is gassed and struggles to recover.")
		player.stamina = minf(player.max_stamina, player.stamina + 4.0)
		return

	var action := enemy_next_action
	if action.is_empty():
		_prepare_enemy_telegraph()
		action = enemy_next_action

	var enemy_accuracy := float(action.get("accuracy", enemy.accuracy))
	if enemy_blinded > 0:
		enemy_accuracy -= 15.0
		enemy_blinded -= 1

	var archetype_damage_bonus := 1.0
	if str(enemy.get("trick", "")) == "aggressive" and str(action.get("name", "")) == "Heavy Right":
		archetype_damage_bonus = 1.12

	var enemy_damage := (
		float(enemy.damage) * float(action.get("damage", 1.0)) * archetype_damage_bonus
		+ rng.randf_range(-2.0, 2.0)
	)

	enemy.stamina = maxf(
		0.0,
		enemy.stamina - float(action.get("cost", 10.0))
	)

	if arena_visuals and arena_visuals.has_method("enemy_attack"):
		arena_visuals.enemy_attack()

	var dodged := player_slipping or (
		rng.randf() * 100.0 < _speed_chance(player.speed)
	)

	if dodged:
		_log("DODGED! " + str(action.get("name", "Their attack")) + " cuts through empty air.")
		player.stamina = minf(
			player.max_stamina,
			player.stamina + float(passive.get("wind", 0.0))
		)
		return

	if rng.randf() * 100.0 > enemy_accuracy:
		_log("Opponent's %s misses." % str(action.get("name", "attack")))
		return

	var damage := enemy_damage * (
		1.0 - float(player.defence) / 100.0
	)

	if player_blocking:
		damage *= 0.32

	# The speedster's flurries tax stamina when they get through.
	if str(enemy.get("trick", "")) == "quick":
		player.stamina = maxf(0.0, player.stamina - 4.0)
		_log("The speedster's flurry leaves you winded.")

	# The champion changes gears on the third and sixth turns of each round.
	if str(enemy.get("trick", "")) == "boss" and turn_no in [3, 6]:
		damage *= 1.18
		_log("The champion's timed surge lands with extra force.")

	var last_move := _get_move(player_last_move_id)
	if str(enemy.get("trick", "")) == "counter" and str(last_move.get("kind", "")) == "attack":
		damage *= 1.20
		_log("The counter-puncher reads your committed attack and fires back.")

	player.health = maxf(0.0, player.health - damage)

	if str(enemy.get("trick", "")) == "dirty":
		player.stamina = maxf(0.0, player.stamina - 5.0)

	if player.health <= player.max_health * 0.25:
		player.heart = true

	heart_active = player.health <= player.max_health * 0.25
	if heart_active:
		_log("HEART: You refuse to stay down.")

	_log(
		("BLOCKED — " if player_blocking else "")
		+ "You take %d damage." % int(damage)
	)

	if player.health <= 0.0:
		if not revive_used and inventory.has("salts"):
			inventory.erase("salts")
			revive_used = true
			player.health = 30.0
			_log("SMELLING SALTS! You drag yourself back to your feet.")
		else:
			_end_run(false, "You were knocked out.")



func _check_round() -> void:
	turn_no += 1

	if turn_no > 6:
		round_no += 1
		turn_no = 1

		player.stamina = minf(
			player.max_stamina,
			player.stamina + 14.0
		)

		enemy.stamina = minf(
			enemy.max_stamina,
			enemy.stamina + 10.0
		)

		_log("BELL! Corner break. You recover 14 stamina.")

		if round_no > 3:
			if player.health >= enemy.health:
				_win_fight()
			else:
				_end_run(false, "The judges give it to your opponent.")

	if player.health <= 0.0:
		_end_run(false, "You were knocked out.")


# ---------------------------------------------------------
# TOURNAMENT PROGRESSION
# ---------------------------------------------------------

func _win_fight() -> void:
	if game_state != "combat":
		return

	_disable_realtime_combat()

	game_state = "reward"
	respect += 10 + fight_index * 3

	_log("KNOCKOUT! The crowd is chanting your name.")

	if fight_index == FIGHT_COUNT - 1:
		_end_run(true, "You became the underground champion.")
		return

	_show_rewards()


func _show_rewards() -> void:
	game_state = "reward"

	_disable_realtime_combat()

	_heading(
		"THE CORNER",
		"Fight %d won. Choose ONE reward." % (fight_index + 1)
	)

	_label(
		"Respect earned: %d     Current health: %d     Stamina: %d" % [
			respect,
			int(player.health),
			int(player.stamina)
		]
	)
	_show_salts_status()

	var options: Array = []

	var has_move_space := (
		owned_moves.size() < 4 + int(passive.get("slots", 0))
	)
	var pool := moves.filter(
		func(move):
			var id := str(move.get("id", ""))
			# At the move cap, offer upgrades to owned moves only.
			return owned_moves.has(id) or has_move_space
	)

	if fight_index < 3 and not pool.is_empty():
		options.append({
			"type": "move",
			"data": pool[rng.randi_range(0, pool.size() - 1)]
		})

	var available_items: Array = []
	for item_variant in item_templates:
		var candidate: Dictionary = item_variant
		var candidate_id := str(candidate.get("id", ""))
		# Smelling Salts are a once-per-run revive. Never offer a duplicate
		# while one is owned or after its revive has already been spent.
		if candidate_id == "salts" and (inventory.has("salts") or revive_used):
			continue
		available_items.append(candidate)

	if (
		inventory.size() < 3
		and rng.randf() < 0.55
		and not available_items.is_empty()
	):
		var item: Dictionary = available_items[
			rng.randi_range(0, available_items.size() - 1)
		]
		options.append({"type": "item", "data": item})
	else:
		options.append({
			"type": "stat",
			"data": _random_upgrade()
		})

	while options.size() > 3:
		options.pop_back()

	while options.size() < 3:
		options.append({
			"type": "stat",
			"data": _random_upgrade()
		})

	options.shuffle()

	for option in options:
		if option.type == "move":
			var move: Dictionary = option.data
			var move_id := str(move.get("id", ""))
			var is_upgrade := owned_moves.has(move_id)
			var reward_prefix := "UPGRADE" if is_upgrade else "NEW MOVE"
			var reward_details := _move_reward_details(move)

			if is_upgrade:
				reward_details += " | Upgrade: +1 player damage."

			_button(
				"%s: %s — %s" % [
					reward_prefix,
					str(move.get("name", "Move")),
					reward_details
				],
				_choose_move.bind(move_id)
			)

		elif option.type == "item":
			var item_data: Dictionary = option.data
			var item_id := str(item_data.get("id", ""))
			_button(
				"ITEM: %s — %s | %s" % [
					str(item_data.get("name", "Item")),
					str(item_data.get("description", "")),
					_item_timing(item_id)
				],
				_choose_item.bind(item_id)
			)

		else:
			var upgrade: Dictionary = option.data
			_button(
				str(upgrade.get("name", "Upgrade"))
				+ " — "
				+ str(upgrade.get("description", "")),
				_choose_upgrade.bind(upgrade)
			)



func _random_upgrade() -> Dictionary:
	var pool := [
		{
			"name": "Roadwork",
			"description": "+12 max stamina and recover 12 now.",
			"stat": "stamina",
			"value": 12
		},
		{
			"name": "Heavy Hands",
			"description": "+3 damage, -2 speed.",
			"stat": "damage",
			"value": 3
		},
		{
			"name": "Old Leather",
			"description": "+15 maximum health and heal 10.",
			"stat": "health",
			"value": 15
		},
		{
			"name": "Tight Guard",
			"description": "+4 defence.",
			"stat": "defence",
			"value": 4
		},
		{
			"name": "Quick Feet",
			"description": "+5 speed (cap 60%).",
			"stat": "speed",
			"value": 5
		},
		{
			"name": "Second Wind",
			"description": "+8 stamina after every successful dodge.",
			"stat": "wind",
			"value": 8
		},
		{
			"name": "Corner's Wisdom",
			"description": "Heal 12 health now.",
			"stat": "heal",
			"value": 12
		}
	]

	return pool[rng.randi_range(0, pool.size() - 1)].duplicate(true)


func _choose_move(id: String) -> void:
	if owned_moves.has(id):
		var move := _get_move(id)
		player.damage += 1.0
		_log("%s levels up. Your hands are learning." % str(move.get("name", id)))
	else:
		if owned_moves.size() >= 4 + int(passive.get("slots", 0)):
			_show_rewards()
			return

		owned_moves.append(id)
		_log("New move unlocked: " + str(_get_move(id).get("name", id)))

	_after_reward()


func _choose_item(id: String) -> void:
	if inventory.size() >= 3:
		return

	inventory.append(id)
	_log("Added to your corner bag: " + _get_item_name(id) + ".")
	_after_reward()


func _choose_upgrade(upgrade: Dictionary) -> void:
	match str(upgrade.get("stat", "")):
		"stamina":
			player.max_stamina += float(upgrade.value)
			player.stamina = minf(
				player.max_stamina,
				player.stamina + float(upgrade.value)
			)

		"damage":
			player.damage += float(upgrade.value)
			player.speed = maxf(0.0, player.speed - 2.0)

		"health":
			player.max_health += float(upgrade.value)
			player.health = minf(
				player.max_health,
				player.health + 10.0
			)

		"defence":
			player.defence += float(upgrade.value)

		"speed":
			player.speed = minf(
				60.0,
				player.speed + float(upgrade.value)
			)

		"wind":
			passive["wind"] = int(upgrade.value)

		"heal":
			player.health = minf(
				player.max_health,
				player.health + float(upgrade.value)
			)

	_after_reward()


func _after_reward() -> void:
	fight_index += 1

	player.health = minf(
		player.max_health,
		player.health + 10.0
	)

	player.stamina = minf(
		player.max_stamina,
		player.stamina + 20.0
	)

	_save_run()
	_show_bracket()


func _opponent_template_index(index: int) -> int:
	if index < 0 or index >= FIGHT_ROSTER.size():
		return -1
	return int(FIGHT_ROSTER[index])


func _next_opponent_name() -> String:
	if fight_index >= FIGHT_COUNT:
		return "THE CROWN"

	var roster_index := _opponent_template_index(fight_index)
	if roster_index < 0 or roster_index >= enemy_templates.size():
		return "UNKNOWN FIGHTER"

	if fight_index == FIGHT_COUNT - 1:
		return "THE UNDERTAKER"

	return str(enemy_templates[roster_index].get("name", "Unknown Fighter"))


func _next_opponent_scouting_note() -> String:
	var roster_index := _opponent_template_index(fight_index)
	if roster_index < 0 or roster_index >= enemy_templates.size():
		return "No scouting report is available."

	var upcoming: Dictionary = enemy_templates[roster_index]
	match str(upcoming.get("trick", "")).to_lower():
		"aggressive":
			return "Heavy right hands hit hard. Slip the loaded punch instead of trading."
		"quick":
			return "Fast flurries wear down stamina. Defend the rush and punish the recovery."
		"guard":
			return "A tight guard absorbs damage while stamina lasts. Use body shots and clinches to wear it down."
		"counter":
			return "Committed attack moves invite counters. Mix in defence, feints and utility."
		"dirty":
			return "Clean hits drain your stamina. Avoid wasting turns and protect your gas tank."
		"boss":
			return "The champion surges on turns 3 and 6. Keep stamina ready to defend those turns."
		_:
			return str(upcoming.get("tell", "Study the opponent's tell carefully."))


func _show_bracket() -> void:
	game_state = "hub"
	_disable_realtime_combat()

	_heading(
		"THE CIRCUIT",
		"Your name is getting around. Don't let it go to your head."
	)

	_label("FIGHTS CLEARED: %d / 8     RESPECT: %d" % [
		fight_index,
		respect
	])

	# Show the entire tournament route so every run has a clear destination.
	_label("TOURNAMENT BRACKET", 18, Color(0.9, 0.36, 0.22))
	var stage_names := [
		"OPENING BOUT",
		"OPENING BOUT",
		"OPENING BOUT",
		"OPENING BOUT",
		"SEMI-FINAL",
		"SEMI-FINAL",
		"TITLE ELIMINATOR",
		"CHAMPIONSHIP"
	]
	for bracket_index in range(FIGHT_ROSTER.size()):
		var roster_index := int(FIGHT_ROSTER[bracket_index])
		var bracket_name := "Unknown Fighter"
		if roster_index >= 0 and roster_index < enemy_templates.size():
			bracket_name = str(enemy_templates[roster_index].get("name", bracket_name))

		var bracket_status := "LOCKED"
		var bracket_color := Color(0.52, 0.49, 0.47)
		if bracket_index < fight_index:
			bracket_status = "CLEARED"
			bracket_color = Color(0.55, 0.78, 0.58)
		elif bracket_index == fight_index:
			bracket_status = "NEXT"
			bracket_color = Color(1.0, 0.76, 0.35)

		_label(
			"%d. %s — %s  [%s]" % [
				bracket_index + 1,
				stage_names[bracket_index],
				bracket_name,
				bracket_status
			],
			13,
			bracket_color
		)

	_label("NEXT OPPONENT: " + _next_opponent_name())

	var preview_index := _opponent_template_index(fight_index)
	if preview_index >= 0 and preview_index < enemy_templates.size():
		var upcoming: Dictionary = enemy_templates[preview_index]
		_label(
			"STYLE: " + str(upcoming.get("archetype", "Unknown"))
			+ " | " + str(upcoming.get("tell", "No tell recorded."))
		)
		_label("SCOUTING REPORT: " + _next_opponent_scouting_note(), 13, Color(0.82, 0.76, 0.68))

	_label(
		"BUILD: HP %d | STA %d | DMG %d | DEF %d | SPEED %d%%" % [
			int(player.health),
			int(player.stamina),
			int(player.damage),
			int(player.defence),
			int(_speed_chance(player.speed))
		]
	)

	_label("MOVES: " + ", ".join(owned_moves))

	_show_item_summary(false)
	_show_salts_status()
	_label("CAREER EDGE: " + _career_perk_summary(), 12, Color(0.72, 0.82, 0.68))

	_button("ENTER THE RING", _start_fight)
	_button(
		"USE CORNER ICE (+22 HP)",
		_use_heal_between,
		not inventory.has("ice")
	)
	_button("CODEX", _show_codex)
	_button("SAVE RUN", _save_run)
	_button("MAIN MENU", _show_main_menu)


func _use_heal_between() -> void:
	if inventory.has("ice"):
		inventory.erase("ice")
		player.health = minf(
			player.max_health,
			player.health + 22.0
		)
		_show_bracket()


# ---------------------------------------------------------
# ITEMS
# ---------------------------------------------------------

func _use_item(id: String) -> void:
	# Combat items can only be activated during a fight.
	if game_state != "combat":
		return

	# Passive Smelling Salts and between-fight Ice are never manually used.
	if id in ["ice", "salts"]:
		return

	var item_index := inventory.find(id)
	if item_index == -1:
		return

	inventory.remove_at(item_index)
	player_last_move_id = "item"

	match id:
		"vaseline":
			enemy_blinded = 2

		"rosin":
			enemy_drained = 2

		"energy":
			player.stamina = minf(
				player.max_stamina,
				player.stamina + 35.0
			)
			energy_penalty_pending = true

		"loaded_tape":
			loaded_bonus = 18
			loaded_tape_risk = true

		"bribe":
			bribe_ready = true

		"crowd":
			next_fight_speed_bonus = minf(5.0, 60.0 - float(player.get("speed", 0.0)))

	_log("Used " + id.replace("_", " ") + ".")

	if game_state == "combat":
		_enemy_turn()
		player_blocking = false
		player_slipping = false
		if game_state == "combat":
			_check_round()
		if game_state == "combat":
			_prepare_enemy_telegraph()
			_show_combat()
	else:
		_show_combat()


# ---------------------------------------------------------
# LOGGING AND RUN END
# ---------------------------------------------------------

func _log(message: String) -> void:
	log_lines.append(message)

	if log_lines.size() > 12:
		log_lines.pop_front()


func _end_run(won: bool, reason: String) -> void:
	if run_ended:
		return

	run_ended = true
	_disable_realtime_combat()

	game_state = "gameover"

	if won:
		respect += 100

	# Persist career progress before rendering the summary so the displayed
	# lifetime total and rank include this run's Respect award.
	_save_meta()

	_heading(
		"THE CROWN" if won else "LIGHTS OUT",
		reason
	)

	_label(
		"Fights cleared: %d / 8" % (
			fight_index + (1 if won else 0)
		),
		18
	)

	_label("Respect earned this run: %d" % respect, 17)
	_label("Career Respect: %d — %s" % [lifetime_respect, _respect_rank()], 14, Color(0.88, 0.68, 0.38))
	_label("Permanent career perks: " + _career_perk_summary(), 12, Color(0.72, 0.82, 0.68))
	_label("Final build: " + ", ".join(owned_moves))

	_label(
		"Final stats: HP %d | STA %d | DMG %d | DEF %d | SPEED %d%%" % [
			int(player.get("health", 0)),
			int(player.get("stamina", 0)),
			int(player.get("damage", 0)),
			int(player.get("defence", 0)),
			int(_speed_chance(float(player.get("speed", 0))))
		]
	)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(SAVE_PATH)
		)

	_button("TRY AGAIN", _new_run)
	_button("MAIN MENU", _show_main_menu)


# ---------------------------------------------------------
# SAVE / CONTINUE
# ---------------------------------------------------------

func _save_run() -> void:
	var data := {
		"fight_index": fight_index,
		"player": player,
		"owned_moves": owned_moves,
		"inventory": inventory,
		"respect": respect,
		"seed": run_seed,
		"passive": passive,
		"revive_used": revive_used,
		"bribe_ready": bribe_ready,
		"heart_active": heart_active,
		"energy_penalty_pending": energy_penalty_pending,
		"next_fight_speed_bonus": next_fight_speed_bonus
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(data))


func _continue_run() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		_new_run()
		return

	var data = JSON.parse_string(file.get_as_text())

	if not data is Dictionary:
		_new_run()
		return

	run_ended = false
	fight_index = int(data.get("fight_index", 0))
	player = data.get("player", {})

	if player.is_empty():
		_new_run()
		return

	owned_moves.assign(
		data.get("owned_moves", ["jab", "block", "rest"])
	)

	inventory = data.get("inventory", [])
	respect = int(data.get("respect", 0))
	run_seed = int(data.get("seed", 0))
	passive = data.get("passive", {
		"damage": 0.0, "health": 0.0, "stamina": 0.0,
		"defence": 0.0, "speed": 0.0, "slots": 0, "wind": 0
	})
	revive_used = bool(data.get("revive_used", false))
	bribe_ready = bool(data.get("bribe_ready", false))
	heart_active = bool(data.get("heart_active", false))
	energy_penalty_pending = bool(data.get("energy_penalty_pending", false))
	next_fight_speed_bonus = float(data.get("next_fight_speed_bonus", 0.0))

	rng.seed = run_seed + fight_index * 991

	_show_bracket()


func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		lifetime_respect = 0
		return

	var file := FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		lifetime_respect = 0
		return

	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		lifetime_respect = maxi(0, int(data.get("respect_total", 0)))
	else:
		lifetime_respect = 0


func _respect_rank() -> String:
	if lifetime_respect >= 1000:
		return "UNDERGROUND LEGEND"
	if lifetime_respect >= 500:
		return "CIRCUIT HEADLINER"
	if lifetime_respect >= 200:
		return "KNOWN CONTENDER"
	if lifetime_respect >= 50:
		return "LOCAL PROSPECT"
	return "UNKNOWN FIGHTER"


func _apply_career_perks() -> void:
	# Permanent, cumulative career rewards. Applied only when a fresh run starts;
	# Continue loads the already-modified saved fighter and must not stack them.
	if lifetime_respect >= 50:
		player.max_health += 5.0
		player.health += 5.0
	if lifetime_respect >= 200:
		player.max_stamina += 5.0
		player.stamina += 5.0
	if lifetime_respect >= 500:
		player.damage += 1.0
	if lifetime_respect >= 1000:
		player.defence += 1.0


func _career_perk_summary() -> String:
	var perks: Array[String] = []
	if lifetime_respect >= 50:
		perks.append("Grit (+5 max HP)")
	if lifetime_respect >= 200:
		perks.append("Conditioning (+5 max stamina)")
	if lifetime_respect >= 500:
		perks.append("Power (+1 damage)")
	if lifetime_respect >= 1000:
		perks.append("Guard (+1 defence)")
	if perks.is_empty():
		return "No permanent perks yet — reach 50 Career Respect for Grit."
	return " | ".join(perks)


func _save_meta() -> void:
	lifetime_respect += respect
	var data := {"respect_total": lifetime_respect}
	var file := FileAccess.open(META_PATH, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(data))


# ---------------------------------------------------------
# CODEX AND SETTINGS
# ---------------------------------------------------------

func _show_codex() -> void:
	_disable_realtime_combat()

	_heading(
		"FIGHTER'S CODEX",
		"Knowledge is the only thing you keep after a loss."
	)

	_button("BACK TO MAIN MENU", _show_main_menu)

	_label("HEALTH: At zero, you are knocked out.")
	_label("STAMINA: Moves cost stamina. Rest to recover; exhaustion is dangerous.")
	_label("SPEED: Percentage chance to completely evade an incoming hit. Capped at 60%.")
	_label("DEFENCE: Reduces damage after a hit gets through.")
	_label("HEART: Below 25% health, gain a comeback critical chance.")
	_label("TELL: The opponent's body language hints at their next attack.")
	_label("MOVE SLOTS: You begin with 3 moves. The move limit is 4.")
	_label("ENEMY TYPES", 18, Color(0.9, 0.36, 0.22))
	_label("BRAWLER: Heavy loaded punches. Respect the big right-hand tell.")
	_label("SPEEDSTER: Fast flurries that wear down your stamina.")
	_label("TANK: A tight guard absorbs extra damage while the tank has stamina.")
	_label("COUNTER-PUNCHER: Punishes committed attack moves. Mix in defence and utility.")
	_label("DIRTY FIGHTER: Successful hits also drain your stamina.")
	_label("FINAL CHAMPION: Timed surges hit harder on turns 3 and 6 of each round.")

	_label("REWARD TYPES & MOVE UPGRADES", 18, Color(0.9, 0.36, 0.22))
	_label("After a win, choose ONE reward before entering the next fight. Move rewards are available in the opening stretch of the tournament.")
	_label("NEW MOVE: Adds that move to your loadout and gives you another action option. You start with 3 moves and have room for 4 by default.")
	_label("MOVE UPGRADE: If the offered move is already in your loadout, choosing it does not create a duplicate. It permanently adds +1 to your fighter's overall damage for the current run; it is not a move-specific level.")
	_label("FULL LOADOUT: When all move slots are occupied, move rewards are limited to moves you already own, so the choice becomes a damage upgrade.")
	_label("ITEM: Adds one item to your corner bag. The bag holds up to 3 items. Read its timing: some items are used in combat, Ice is for the hub, and Smelling Salts are an automatic one-time revive.")
	_label("STAT UPGRADE: Improves your fighter for the rest of the current run. Some upgrades trade one stat for another; read the full description before choosing.")
	_label("STAT REWARDS", 18, Color(0.9, 0.36, 0.22))
	_label("ROADWORK: +12 maximum stamina and recover 12 now.")
	_label("HEAVY HANDS: +3 damage, but -2 speed.")
	_label("OLD LEATHER: +15 maximum health and heal 10 now.")
	_label("TIGHT GUARD: +4 defence.")
	_label("QUICK FEET: +5 speed, up to the 60% cap.")
	_label("SECOND WIND: Recover +8 stamina after every successful dodge.")
	_label("CORNER'S WISDOM: Heal 12 health immediately.")

	_label("CORNER ITEMS", 18, Color(0.9, 0.36, 0.22))
	_label("Smelling Salts are not part of the starting kit. They must be selected as an ITEM reward; once owned, they automatically trigger on one lethal hit and are then gone for the rest of that run.", 13)
	for item in item_templates:
		var item_name := str(item.get("name", "Unknown item"))
		var item_description := str(item.get("description", ""))
		var item_id := str(item.get("id", ""))
		_label("%s — %s" % [item_name, item_description], 13)
		_label(_item_timing(item_id), 12, Color(0.68, 0.64, 0.60))

	_label("CAREER RESPECT PERKS", 18, Color(0.9, 0.36, 0.22))
	_label("50 Respect — Grit: +5 max health on fresh runs.")
	_label("200 Respect — Conditioning: +5 max stamina on fresh runs.")
	_label("500 Respect — Power: +1 damage on fresh runs.")
	_label("1000 Respect — Guard: +1 defence on fresh runs.")
	_label("Perks are cumulative and never stack again when continuing a saved run.")

	_label("TOURNAMENT RULES", 18, Color(0.9, 0.36, 0.22))
	_label("Win a fight to choose one reward. Resolve that choice before the next bout.")
	_label("A win restores 10 health and 20 stamina before the next fight.")
	_label("A loss ends the run. Your current build and run Respect are lost; lifetime Respect is tracked separately.")
	_label("The final decision after three rounds is based on remaining health if neither fighter is knocked out.")

	for move in moves:
		_label(
			"%s (%d STA): %s" % [
				str(move.get("name", "Move")),
				int(move.get("cost", 0)),
				str(move.get("description", ""))
			],
			13
		)

	_button("BACK", _show_main_menu)


func _show_settings() -> void:
	_disable_realtime_combat()

	_heading(
		"SETTINGS",
		"Keep the picture clear. Keep your head."
	)

	_button(
		"SCREEN SHAKE: " + ("ON" if screen_shake else "OFF"),
		_toggle_shake
	)

	_button(
		"CRT FILTER: " + ("ON" if crt_enabled else "OFF"),
		_toggle_crt
	)

	_label("Audio and remappable controls are planned for the expanded release.")
	_button("BACK", _show_main_menu)


func _toggle_shake() -> void:
	screen_shake = not screen_shake
	_show_settings()


func _toggle_crt() -> void:
	crt_enabled = not crt_enabled
	_show_settings()
