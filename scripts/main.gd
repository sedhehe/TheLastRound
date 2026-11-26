
extends Node3D
# The Last Round: self-contained playable vertical slice / tournament prototype.

const ARENA_VISUALS = preload("res://scripts/arena_visuals.gd")
const TLRTheme = preload("res://scripts/ui_theme.gd")
const TLRScreens = preload("res://scripts/ui_screens.gd")
const TLRCombatUI = preload("res://scripts/ui_combat.gd")
const TLRAudio = preload("res://scripts/audio_engine.gd")
const TLRStory = preload("res://scripts/story_data.gd")
const MOVE_FILE = "res://data/moves.json"
const ENEMY_FILE = "res://data/enemies.json"
const ITEM_FILE = "res://data/items.json"
const SAVE_SLOT_COUNT := 3
const SAVE_VERSION := 3
const META_PATH = "user://the_last_round_career.json"
const SETTINGS_PATH = "user://the_last_round_settings.json"

var selected_slot := 0

const FIGHT_COUNT := 8
const FIGHT_ROSTER := [0, 1, 2, 3, 4, 5, 6, 9]
const PERK_MAX := 4
const PERK_CATALOG: Array[Dictionary] = [
	{"id": "iron_chin", "name": "Iron Chin", "rarity": "common", "price": 34, "desc": "Below 35% HP: +5 DEF and +30% punch damage."},
	{"id": "rope_a_dope", "name": "Rope-A-Dope", "rarity": "common", "price": 34, "desc": "Block absorbs 85% DMG, reflects 5 DMG, and recovers +5 STA."},
	{"id": "second_heart", "name": "Second Heart", "rarity": "common", "price": 32, "desc": "Recover +8 HP at every corner break between rounds."},
	{"id": "dirty_work", "name": "Dirty Work", "rarity": "uncommon", "price": 42, "desc": "Dirty moves cost 0 STA, halve DQ risk, and pay +$15 Pit Cash."},
	{"id": "combo_addict", "name": "Combo Addict", "rarity": "uncommon", "price": 44, "desc": "Consecutive hits stack +15% DMG (up to +60%)."},
	{"id": "sucker_punch", "name": "Sucker Punch", "rarity": "uncommon", "price": 44, "desc": "First landed hit each round deals +55% DMG and drains 8 STA."},
	{"id": "counter_king", "name": "Counter King", "rarity": "rare", "price": 54, "desc": "Counter & Opening shots deal +35% DMG and restore +6 STA."},
	{"id": "greasy_gloves", "name": "Greasy Gloves", "rarity": "rare", "price": 54, "desc": "+8% Speed; every dodge lands an automatic 6 DMG counter-jab."},
	{"id": "belt_hunter", "name": "Prize Hunter", "rarity": "rare", "price": 52, "desc": "Knockouts pay +$22 Pit Cash and boost Rare/Contraband drops."},
	{"id": "glass_knuckles", "name": "Glass Knuckles", "rarity": "contraband", "price": 66, "desc": "+5 flat damage on every punch; -15 max HP."},
	{"id": "bloodthirst", "name": "Bloodthirst", "rarity": "contraband", "price": 68, "desc": "Crits and Adrenaline Finishers heal +10 HP."},
	{"id": "momentum_king", "name": "Flow State", "rarity": "contraband", "price": 68, "desc": "Momentum chain hits deal +25% bonus DMG and grant +12 Adrenaline."}
]
const STYLE_CATALOG: Array[Dictionary] = [
	{
		"id": "slugger",
		"name": "PIT SLUGGER",
		"tag": "HEAVY BRAWLER",
		"desc": "Built to walk through punches and trade heavy hooks.",
		"stats": "115 HP  •  95 STA  •  13 DMG  •  6 DEF  •  8% SPD",
		"kit": "Jab, Block, Hook, Rest  •  Ice Pack  •  $30  •  Iron Chin"
	},
	{
		"id": "counter_pro",
		"name": "COUNTER ARTIST",
		"tag": "SPEED & OPENINGS",
		"desc": "Slip shots cleanly and punish mistakes with Lv.2 Counters.",
		"stats": "95 HP  •  105 STA  •  10 DMG  •  4 DEF  •  18% SPD",
		"kit": "Jab, Slip, Counter (Lv.2), Rest  •  Vaseline  •  $40"
	},
	{
		"id": "dirty_rat",
		"name": "ALLEY GRIFTER",
		"tag": "DIRTY & RICH",
		"desc": "Start loaded with Pit Cash, dirty tricks, and ref protection.",
		"stats": "100 HP  •  100 STA  •  10 DMG  •  5 DEF  •  12% SPD",
		"kit": "Jab, Block, Low Blow, Rest  •  Tape & Bribe  •  $65  •  Dirty Work"
	},
	{
		"id": "wildcard",
		"name": "PIT WILDCARD",
		"tag": "RANDOMIZED BUILD",
		"desc": "Unpredictable technique, random Uncommon/Rare gear, and a mystery Trait.",
		"stats": "100 HP  •  112 STA  •  11 DMG  •  5 DEF  •  14% SPD",
		"kit": "Random 4th Move  •  Random Item  •  Random Trait  •  $45"
	}
]

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
var move_levels: Dictionary = {}
var owned_perks: Array[String] = []
var run_roster: Array[int] = [0, 1, 2, 3, 4, 5, 6, 9]
var alt_roster: Array[int] = [1, 2, 0, 4, 5, 3, 7, 10]
var bout_branches: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
var bout_bounties: Array = []
var player_style := "slugger"
var inventory: Array = []
var passive: Dictionary = {}

var fight_index := 0
var round_no := 1
var turn_no := 1

var player_blocking := false
var player_slipping := false
var player_combo_ready := false
var player_counter_window := false
var player_momentum := false
var momentum_spent_turn := false
var enemy_staggered := false
var enemy_enraged := false
var enemy_taunt_buff := false
var player_bleeding := 0
var brass_charges := 0
var adrenaline := 0.0
var combo_streak := 0
var round_first_hit_available := true
var fight_turns_total := 0
var fight_used_block := false
var fight_big_hits := 0
var cash := 30
var shop_bought_flags: Dictionary = {}
var shop_stock: Dictionary = {}
var shop_reroll_count := 0
var current_hub_event: Dictionary = {}
var hub_event_done := false
var event_enemy_speed_buff := 0.0
var contract_accepted := false
var run_highest_hit := 0
var run_knockouts := 0
var enemy_blinded := 0
var enemy_drained := 0
var loaded_bonus := 0
var loaded_tape_risk := false
var energy_penalty_pending := false
var next_fight_speed_bonus := 0.0
var enemy_next_action: Dictionary = {}
var current_bout_modifier: Dictionary = {}

var bribe_ready := false
var revive_used := false
var heart_active := false

var game_state := "menu"
var run_ended := false
var respect := 0
var lifetime_respect := 0
var run_seed := 0
var menu_notice := ""
var hub_notice := ""
var tutorial_step := 0
var training_active := false
var training_turn := 0
var training_feedback := ""
const TRAINING_EXCHANGES := 8

var log_lines: Array[String] = []

var root_ui: Control
var panel: PanelContainer
var content: VBoxContainer
var ui_scroll: ScrollContainer
var ui_shade: ColorRect
var screen_canvas: Control
var brightness_overlay: ColorRect
var crt_overlay: ColorRect
var combat_hud: Control
var combat_drawer_open := false
var combat_review_open := false
var review_scenario := ""
var combat_paused := false
var round_transition_open := false
var combat_banner_title := ""
var combat_banner_sub := ""
var animate_combat_banner := false
var animate_round_transition := false
var animate_drawer_open := false
var animate_pause_open := false
var animate_phase_banner := false
var animate_screen_enter := false
var animate_cards_enter := false
var confirm_career_reset := false
var hud_player_hp := -1.0
var hud_player_stamina := -1.0
var hud_enemy_hp := -1.0
var hud_enemy_stamina := -1.0
var player_last_move_id := ""

var reward_options: Array = []
var selected_reward_index := -1
var selected_hub_item_slot := 0
var settings_tab := "controls"
var settings_saved_notice := false
var codex_tab := "core"
var item_lesson_demo_used := false
var item_lesson_show_all := false
var practice_pose := "heavy"
var training_retry_flag := false
var tutorial_completed := false
var pending_first_run_tutorial := false
var story_seen_ids: Array[String] = []
var active_cutscene: Dictionary = {}
var cutscene_beat_idx := 0
var cutscene_after_cb: Callable = Callable()
var cutscene_text_label: Label = null
var cutscene_next_btn: Button = null
var cutscene_char_progress := 0.0
var cutscene_typing := false
var cutscene_is_last := false
var _last_type_tick := -1

var settings: Dictionary = {
	"master_volume": 80,
	"music_volume": 60,
	"sfx_volume": 80,
	"commentary_volume": 80,
	"window_mode": "Fullscreen",
	"aspect_mode": "Auto (Fill)",
	"resolution": "Auto",
	"vsync": true,
	"brightness": 50,
	"crt_enabled": true,
	"reduced_motion": false,
	"screen_shake": true,
	"flash_effects": true,
	"text_size": "Standard",
	"subtitles": true,
	"contrast": "Standard",
	"story_cutscenes": true
}

var arena_light: OmniLight3D
var opponent_mesh: Node3D
var opponent_mat: StandardMaterial3D
var camera: Camera3D
var arena_visuals: Node3D
var audio_engine: Node
var flash_overlay: ColorRect

var screen_shake := false
var crt_enabled := true

var player_start_position := Vector3(0.0, 0.0, 2.1)
var enemy_start_position := Vector3.ZERO


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var key: int = event.keycode
	if game_state == "menu":
		if key in [KEY_1, KEY_2, KEY_3]:
			_select_slot(key - KEY_1)
			get_viewport().set_input_as_handled()
			return
		if key in [KEY_LEFT, KEY_UP]:
			_select_slot((selected_slot + SAVE_SLOT_COUNT - 1) % SAVE_SLOT_COUNT)
			get_viewport().set_input_as_handled()
			return
		if key in [KEY_RIGHT, KEY_DOWN]:
			_select_slot((selected_slot + 1) % SAVE_SLOT_COUNT)
			get_viewport().set_input_as_handled()
			return
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			var info := _slot_info(selected_slot)
			if bool(info.get("has_save", false)):
				_continue_run(selected_slot)
			else:
				_request_new_run(selected_slot)
			get_viewport().set_input_as_handled()
			return
		return

	if game_state == "reward":
		if key in [KEY_1, KEY_2, KEY_3]:
			_select_reward_option(key - KEY_1)
			get_viewport().set_input_as_handled()
			return
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and selected_reward_index >= 0:
			_confirm_selected_reward()
			get_viewport().set_input_as_handled()
			return
		return

	if game_state == "cutscene":
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT]:
			_advance_cutscene()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_LEFT:
			_prev_cutscene_beat()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_ESCAPE:
			_skip_cutscene()
			get_viewport().set_input_as_handled()
			return
		return

	if game_state == "hub":
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_enter_next_bout()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_Q and inventory.size() >= 1:
			_select_hub_item_slot(0)
			if str(inventory[0]) == "ice":
				_use_hub_item_slot(0)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_W and inventory.size() >= 2:
			_select_hub_item_slot(1)
			if str(inventory[1]) == "ice":
				_use_hub_item_slot(1)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_E and inventory.size() >= 3:
			_select_hub_item_slot(2)
			if str(inventory[2]) == "ice":
				_use_hub_item_slot(2)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_C:
			_show_codex()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_B:
			_open_shop()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_ESCAPE:
			_show_main_menu()
			get_viewport().set_input_as_handled()
			return

	if game_state in ["shop", "event"]:
		if key == KEY_ESCAPE:
			_show_bracket()
			get_viewport().set_input_as_handled()
			return

	if game_state == "event_result":
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			_show_bracket()
			get_viewport().set_input_as_handled()
			return

	if game_state == "style_select":
		if key in [KEY_1, KEY_2, KEY_3, KEY_4]:
			var s_idx := key - KEY_1
			if s_idx < STYLE_CATALOG.size():
				_start_story_run(selected_slot, str(STYLE_CATALOG[s_idx].get("id", "slugger")))
				get_viewport().set_input_as_handled()
			return
		if key == KEY_ESCAPE:
			_show_main_menu()
			get_viewport().set_input_as_handled()
			return
			return
		return

	if game_state in ["settings", "codex", "telegraph_practice", "overwrite"]:
		if key == KEY_ESCAPE:
			_show_main_menu()
			get_viewport().set_input_as_handled()
		return

	if game_state == "training_items":
		if key == KEY_Q:
			_toggle_item_lesson_demo()
			get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE:
			_show_training_complete()
			get_viewport().set_input_as_handled()
		return

	if game_state != "combat":
		return

	if round_transition_open:
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			_dismiss_round_transition()
			get_viewport().set_input_as_handled()
		return

	# F1 opens the combat review index (in standard combat). From a scenario
	# card it returns to the index; from the index it returns to the live fight.
	if key == KEY_F1 and not training_active:
		if not combat_review_open:
			combat_review_open = true
			review_scenario = ""
		elif not review_scenario.is_empty():
			review_scenario = ""
		else:
			combat_review_open = false
		_show_combat()
		get_viewport().set_input_as_handled()
		return

	if key == KEY_ESCAPE:
		combat_paused = not combat_paused
		_show_combat()
		get_viewport().set_input_as_handled()
		return

	if key == KEY_TAB:
		combat_drawer_open = not combat_drawer_open
		_show_combat()
		get_viewport().set_input_as_handled()
		return

	# Review and pause overlays are modal: no action can leak through them.
	if combat_paused or combat_review_open:
		return

	var move_slot := -1
	match key:
		KEY_1: move_slot = 0
		KEY_2: move_slot = 1
		KEY_3: move_slot = 2
		KEY_4: move_slot = 3
		KEY_5: move_slot = 4
		KEY_6: move_slot = 5
		KEY_7: move_slot = 6
		KEY_8: move_slot = 7
	if move_slot >= 0:
		if move_slot < owned_moves.size():
			_player_move(owned_moves[move_slot])
		get_viewport().set_input_as_handled()
		return

	var item_slot := -1
	match key:
		KEY_Q: item_slot = 0
		KEY_W: item_slot = 1
		KEY_E: item_slot = 2
	if item_slot >= 0:
		var item_slots := _combat_item_slots()
		if item_slot < item_slots.size():
			_use_item(item_slots[item_slot])
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if game_state != "cutscene" or not cutscene_typing or not is_instance_valid(cutscene_text_label):
		return
	var total_chars := cutscene_text_label.text.length()
	if bool(settings.get("reduced_motion", false)) or DisplayServer.get_name() == "headless":
		cutscene_text_label.visible_characters = -1
		cutscene_typing = false
		if is_instance_valid(cutscene_next_btn):
			cutscene_next_btn.text = "BEGIN  →" if cutscene_is_last else "NEXT  →"
		return
	cutscene_char_progress += delta * 56.0
	var shown := mini(total_chars, int(cutscene_char_progress))
	cutscene_text_label.visible_characters = shown
	if shown > _last_type_tick and shown % 3 == 0 and shown < total_chars:
		_last_type_tick = shown
		if is_instance_valid(audio_engine) and audio_engine.has_method("play_typewriter_tick"):
			audio_engine.play_typewriter_tick()
	if shown >= total_chars:
		cutscene_text_label.visible_characters = -1
		cutscene_typing = false
		if is_instance_valid(cutscene_next_btn):
			cutscene_next_btn.text = "BEGIN  →" if cutscene_is_last else "NEXT  →"


func _ready() -> void:
	rng.randomize()

	_remove_legacy_save_files()
	_load_meta()
	_load_settings()
	moves = _read_json(MOVE_FILE)
	enemy_templates = _read_json(ENEMY_FILE)
	item_templates = _read_json(ITEM_FILE)

	_build_world()
	_build_audio()
	_build_ui()
	_apply_settings()
	_show_main_menu()
	_play_boot_splash()


func _build_audio() -> void:
	audio_engine = TLRAudio.new()
	audio_engine.name = "AudioEngine"
	add_child(audio_engine)
	audio_engine.apply_volumes(settings)


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
	print("[THE LAST ROUND] ", message)


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

	# Buckshot Roulette 3D-world ordered Bayer 4x4 dither + PSX grit filter (sits behind UI text)
	var dither_layer := ColorRect.new()
	dither_layer.name = "WorldDitherPass"
	dither_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dither_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dither_shader := Shader.new()
	dither_shader.code = """
shader_type canvas_item;
uniform sampler2D SCREEN_TEX : hint_screen_texture, filter_nearest;

float bayer4x4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int idx = x + y * 4;
	float m[16] = float[](
		 0.0,  8.0,  2.0, 10.0,
		12.0,  4.0, 14.0,  6.0,
		 3.0, 11.0,  1.0,  9.0,
		15.0,  7.0, 13.0,  5.0
	);
	return (m[idx] / 16.0) - 0.5;
}

void fragment() {
	vec2 px = floor(FRAGCOORD.xy / 2.0);
	vec2 uv_q = (px * 2.0 + 1.0) * SCREEN_PIXEL_SIZE;
	vec3 col = texture(SCREEN_TEX, uv_q).rgb;
	float d = bayer4x4(px) * 0.055;
	col = floor((col + d) * 28.0) / 28.0;
	// Subtle gritty dark corner crush
	float vig = smoothstep(0.96, 0.28, distance(SCREEN_UV, vec2(0.5)));
	col *= mix(0.68, 1.0, vig);
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
"""
	var dither_mat := ShaderMaterial.new()
	dither_mat.shader = dither_shader
	dither_layer.material = dither_mat
	root_ui.add_child(dither_layer)

	ui_shade = ColorRect.new()
	ui_shade.color = TLRTheme.BG_DARK
	ui_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(ui_shade)

	screen_canvas = Control.new()
	screen_canvas.name = "ScreenCanvas"
	screen_canvas.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	screen_canvas.size = Vector2(1600.0, 900.0)
	screen_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	root_ui.add_child(screen_canvas)

	panel = PanelContainer.new()
	panel.visible = false
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

	brightness_overlay = ColorRect.new()
	brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brightness_overlay.z_index = 200
	brightness_overlay.color = Color(0, 0, 0, 0)
	root_ui.add_child(brightness_overlay)

	flash_overlay = ColorRect.new()
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.z_index = 199
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	root_ui.add_child(flash_overlay)

	crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.z_index = 201
	var crt_shader := Shader.new()
	crt_shader.code = """
shader_type canvas_item;
void fragment() {
	float scan = sin(UV.y * 900.0 * 3.14159) * 0.5 + 0.5;
	float vig = smoothstep(0.95, 0.35, distance(UV, vec2(0.5)));
	float alpha = mix(0.06, 0.015, scan) + (1.0 - vig) * 0.10;
	COLOR = vec4(0.01, 0.02, 0.04, clamp(alpha, 0.0, 0.22));
}
"""
	var crt_mat := ShaderMaterial.new()
	crt_mat.shader = crt_shader
	crt_overlay.material = crt_mat
	root_ui.add_child(crt_overlay)

	root_ui.resized.connect(_on_root_ui_resized)
	_layout_ui()


func _on_root_ui_resized() -> void:
	_layout_ui()
	_update_scene_framing()
	if game_state == "combat":
		_show_combat()


func _layout_ui() -> void:
	if not is_instance_valid(panel) or not is_instance_valid(root_ui):
		return
	panel.hide()
	if is_instance_valid(screen_canvas) and root_ui.size.x > 0.0 and root_ui.size.y > 0.0:
		var s := minf(root_ui.size.x / 1600.0, root_ui.size.y / 900.0)
		screen_canvas.size = Vector2(1600.0, 900.0)
		screen_canvas.scale = Vector2(s, s)
		screen_canvas.position = (root_ui.size - Vector2(1600.0, 900.0) * s) * 0.5


func _update_scene_framing() -> void:
	var show_gloves := (game_state == "combat")
	if is_instance_valid(arena_visuals) and arena_visuals.has_method("set_gloves_visible"):
		arena_visuals.set_gloves_visible(show_gloves)
	if is_instance_valid(player_controller) and is_instance_valid(player_controller.camera):
		var aspect := 16.0 / 9.0
		if is_instance_valid(root_ui) and root_ui.size.y > 0.0:
			aspect = maxf(1.0, root_ui.size.x / root_ui.size.y)
		# Keep full ring & gloves framed on narrow (4:3) and ultrawide (21:9) screens
		if aspect < 16.0 / 9.0:
			player_controller.camera.keep_aspect = Camera3D.KEEP_WIDTH
			player_controller.camera.fov = clampf(74.0 * ((16.0 / 9.0) / aspect) * 0.78, 70.0, 88.0)
		else:
			player_controller.camera.keep_aspect = Camera3D.KEEP_HEIGHT
			player_controller.camera.fov = 74.0
		if game_state == "menu":
			player_controller.camera.h_offset = -1.35 * (aspect / (16.0 / 9.0))
		else:
			player_controller.camera.h_offset = 0.0


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.028, 0.045, 0.96)
	style.border_color = Color(0.16, 0.34, 0.50)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _clear_ui() -> void:
	if is_instance_valid(combat_hud):
		combat_hud.queue_free()
		combat_hud = null
	if is_instance_valid(screen_canvas):
		for child in screen_canvas.get_children():
			child.queue_free()
		screen_canvas.show()
		if animate_screen_enter and DisplayServer.get_name() != "headless" and not bool(settings.get("reduced_motion", false)):
			animate_screen_enter = false
			screen_canvas.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(screen_canvas, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			animate_screen_enter = false
			screen_canvas.modulate.a = 1.0
	panel.hide()
	ui_shade.color = Color(0.0, 0.0, 0.0, 0.0) if (game_state == "menu" or game_state == "cutscene") else TLRTheme.BG_DARK
	for child in content.get_children():
		child.queue_free()
	if is_instance_valid(ui_scroll):
		ui_scroll.scroll_vertical = 0
	_update_scene_framing()


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
	style.bg_color = Color(0.075, 0.12, 0.18)
	style.border_color = Color(0.20, 0.42, 0.60)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override(
		"hover",
		_button_style(Color(0.13, 0.23, 0.32))
	)
	button.add_theme_stylebox_override(
		"disabled",
		_button_style(Color(0.055, 0.07, 0.09))
	)

	button.pressed.connect(callback)
	content.add_child(button)
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.20, 0.42, 0.60)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _heading(fighter_name: String, sub: String) -> void:
	_clear_ui()
	_label(fighter_name, 30, Color(0.40, 0.75, 0.95))
	_label(sub, 14, Color(0.62, 0.70, 0.80))

	var line := HSeparator.new()
	content.add_child(line)


# ---------------------------------------------------------
# MENUS AND RUN START
# ---------------------------------------------------------

func _play_boot_splash() -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(root_ui):
		return
	var splash_tex: Texture2D = load("res://splash.png")
	if splash_tex == null:
		return

	var splash := ColorRect.new()
	splash.name = "BootSplashOverlay"
	splash.color = Color(0.071, 0.071, 0.071, 1.0)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.z_index = 250
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ui.add_child(splash)

	var logo := TextureRect.new()
	logo.texture = splash_tex
	logo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.pivot_offset = root_ui.size * 0.5
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.94, 0.94)
	splash.add_child(logo)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.45)
	tw.chain().tween_property(splash, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(splash.queue_free)


func _show_main_menu() -> void:
	training_active = false
	game_state = "menu"
	_disable_realtime_combat()
	if is_instance_valid(arena_visuals) and arena_visuals.has_method("end_cutscene"):
		arena_visuals.end_cutscene(player_controller.camera if is_instance_valid(player_controller) else camera)
	if is_instance_valid(opponent_mat):
		opponent_mat.albedo_color = Color(0.34, 0.19, 0.16)
	if is_instance_valid(audio_engine):
		audio_engine.set_ambience("menu")
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_title_screen(self, screen_canvas)


func _select_slot(slot: int) -> void:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return
	selected_slot = slot
	confirm_career_reset = false
	if game_state == "menu":
		animate_screen_enter = false
		animate_cards_enter = false
		_clear_ui()
		TLRScreens.build_title_screen(self, screen_canvas)


func _reset_career_record() -> void:
	if not confirm_career_reset:
		confirm_career_reset = true
	else:
		confirm_career_reset = false
		lifetime_respect = 0
		_save_meta_flags()
		menu_notice = "Career record reset to 0 Respect."
	if game_state == "menu":
		animate_screen_enter = false
		animate_cards_enter = false
		_clear_ui()
		TLRScreens.build_title_screen(self, screen_canvas)


func _quit_game() -> void:
	get_tree().quit()


func _request_new_run(slot: int) -> void:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return
	selected_slot = slot
	if FileAccess.file_exists(_slot_save_path(slot)):
		_show_slot_overwrite_confirmation(slot)
	elif not tutorial_completed:
		tutorial_completed = true
		pending_first_run_tutorial = true
		_save_meta_flags()
		_start_training(true)
	else:
		_show_style_select(slot)


func _show_slot_overwrite_confirmation(slot: int) -> void:
	game_state = "overwrite"
	_clear_ui()
	TLRScreens.build_overwrite_confirm(self, screen_canvas, slot)


func _show_style_select(slot: int = -1) -> void:
	if slot >= 0 and slot < SAVE_SLOT_COUNT:
		selected_slot = slot
	game_state = "style_select"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_style_select(self, screen_canvas)


func _new_run(slot: int = -1, style_id: String = "slugger", play_intro: bool = false) -> void:
	if slot >= 0 and slot < SAVE_SLOT_COUNT:
		selected_slot = slot
	var previous_slot_save := _slot_save_path(selected_slot)
	if FileAccess.file_exists(previous_slot_save):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(previous_slot_save))
		if remove_error != OK:
			menu_notice = "Could not replace Slot %d. The existing run was kept." % [selected_slot + 1]
			_show_main_menu()
			return
	training_active = false
	run_ended = false
	story_seen_ids.clear()
	run_seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec()) ^ randi()
	rng.seed = run_seed

	fight_index = 0
	round_no = 1
	turn_no = 1

	player_style = style_id
	move_levels.clear()
	owned_perks.clear()
	run_roster = _generate_run_roster(run_seed)
	bout_branches = [0, 0, 0, 0, 0, 0, 0, 0]
	adrenaline = 0.0
	combo_streak = 0
	contract_accepted = false
	shop_bought_flags.clear()
	shop_stock.clear()
	shop_reroll_count = 0
	current_hub_event.clear()
	hub_event_done = false
	event_enemy_speed_buff = 0.0
	run_highest_hit = 0
	run_knockouts = 0

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
	brass_charges = 0
	player_momentum = false
	momentum_spent_turn = false
	enemy_next_action.clear()
	log_lines.clear()

	match style_id:
		"counter_pro":
			owned_moves = ["jab", "slip", "counter", "rest"]
			move_levels = {"counter": 2}
			inventory = ["vaseline"]
			cash = 40
			player = {"health": 95.0, "max_health": 95.0, "stamina": 105.0, "max_stamina": 105.0, "damage": 10.0, "speed": 18.0, "defence": 4.0, "heart": false, "knockdowns": 0}
		"dirty_rat":
			owned_moves = ["jab", "block", "low_blow", "rest"]
			owned_perks = ["dirty_work"]
			inventory = ["loaded_tape", "bribe"]
			cash = 65
			player = {"health": 100.0, "max_health": 100.0, "stamina": 100.0, "max_stamina": 100.0, "damage": 10.0, "speed": 12.0, "defence": 5.0, "heart": false, "knockdowns": 0}
		"wildcard":
			var wild_pool := ["uppercut", "body_shot", "overhand", "feint", "one_two", "hook"]
			var wild_move := str(wild_pool[rng.randi_range(0, wild_pool.size() - 1)])
			owned_moves = ["jab", "block", wild_move, "rest"]
			var wild_items := ["cutman_kit", "pepper_wrap", "adrenaline_shot", "sparring_tonics", "energy"]
			inventory = [str(wild_items[rng.randi_range(0, wild_items.size() - 1)])]
			var wild_perks := ["combo_addict", "sucker_punch", "greasy_gloves", "rope_a_dope", "counter_king"]
			owned_perks = [str(wild_perks[rng.randi_range(0, wild_perks.size() - 1)])]
			cash = 45
			player = {"health": 100.0, "max_health": 100.0, "stamina": 112.0, "max_stamina": 112.0, "damage": 11.0, "speed": 14.0, "defence": 5.0, "heart": false, "knockdowns": 0}
		_:
			# Pit Slugger (default)
			owned_moves = ["jab", "block", "hook", "rest"]
			owned_perks = ["iron_chin"]
			inventory = ["ice"]
			cash = 30
			player = {"health": 115.0, "max_health": 115.0, "stamina": 95.0, "max_stamina": 95.0, "damage": 13.0, "speed": 8.0, "defence": 6.0, "heart": false, "knockdowns": 0}

	_apply_career_perks()
	_generate_shop_stock(true)
	_roll_hub_event()

	if play_intro and bool(settings.get("story_cutscenes", true)) and DisplayServer.get_name() != "headless":
		story_seen_ids.append("prologue")
		_play_story_cutscene("prologue", _start_fight)
	else:
		_start_fight()


func _start_story_run(slot: int = -1, style_id: String = "slugger") -> void:
	_new_run(slot, style_id, true)


func _boss_name() -> String:
	var b_idx: int = _opponent_template_index(FIGHT_COUNT - 1)
	if b_idx >= 0 and b_idx < enemy_templates.size():
		return str(enemy_templates[b_idx].get("name", "The Undertaker"))
	return "The Undertaker"


func _pending_story_for_fight(f_idx: int) -> String:
	if training_active or not bool(settings.get("story_cutscenes", true)) or DisplayServer.get_name() == "headless":
		return ""
	match f_idx:
		3:
			return "" if story_seen_ids.has("act2") else "act2"
		5:
			return "" if story_seen_ids.has("act3") else "act3"
		7:
			return "" if story_seen_ids.has("finale") else "finale"
		_:
			return ""


func _enter_next_bout() -> void:
	var scene_id := _pending_story_for_fight(fight_index)
	if not scene_id.is_empty():
		story_seen_ids.append(scene_id)
		_play_story_cutscene(scene_id, _start_fight)
	else:
		_start_fight()


func _story_context(override_fight_idx: int = -1) -> Dictionary:
	var idx := fight_index if override_fight_idx < 0 else clampi(override_fight_idx, 0, FIGHT_COUNT - 1)
	var opp_t: Dictionary = {}
	var o_i := _opponent_template_index(idx)
	if o_i >= 0 and o_i < enemy_templates.size():
		opp_t = enemy_templates[o_i]
	var boss_t: Dictionary = {}
	var b_i := _opponent_template_index(FIGHT_COUNT - 1)
	if b_i >= 0 and b_i < enemy_templates.size():
		boss_t = enemy_templates[b_i]
	var has_dirty := has_perk("dirty_work") or owned_moves.has("low_blow") or owned_moves.has("headbutt") or bribe_ready
	return {
		"player_style": player_style,
		"opp_id": str(opp_t.get("id", "mick")),
		"opp_name": str(opp_t.get("name", "Mick 'The Meter' Doyle")),
		"opp_archetype": str(opp_t.get("archetype", "Brawler")),
		"opp_visual": opp_t.get("visual", {}),
		"boss_id": str(boss_t.get("id", "undertaker")),
		"boss_name": str(boss_t.get("name", "The Undertaker")),
		"boss_visual": boss_t.get("visual", {}),
		"cash": cash,
		"knockouts": run_knockouts,
		"has_dirty": has_dirty
	}


func _play_story_cutscene(scene_id: String, after_cb: Callable = Callable(), preview_fight_idx: int = -1) -> void:
	_disable_realtime_combat()
	var f_for_scene := preview_fight_idx
	if f_for_scene < 0:
		match scene_id:
			"prologue": f_for_scene = 0
			"act2": f_for_scene = 3
			"act3": f_for_scene = 5
			"finale", "epilogue": f_for_scene = FIGHT_COUNT - 1
			_: f_for_scene = fight_index
	var ctx := _story_context(f_for_scene)
	var vis: Dictionary = ctx.get("boss_visual", {}) if scene_id in ["finale", "epilogue"] else ctx.get("opp_visual", {})
	if is_instance_valid(arena_visuals) and arena_visuals.has_method("set_opponent_appearance") and not vis.is_empty():
		arena_visuals.set_opponent_appearance(vis)
		opponent_mesh = arena_visuals.opponent_body
		opponent_mat = arena_visuals.opponent_material

	active_cutscene = TLRStory.get_cutscene(scene_id, ctx)
	cutscene_beat_idx = 0
	cutscene_after_cb = after_cb
	game_state = "cutscene"
	if is_instance_valid(audio_engine):
		audio_engine.set_ambience("cutscene")
	_apply_cutscene_beat()


func _replay_story_cutscene(scene_id: String) -> void:
	var from_hub := (game_state == "hub")
	var return_cb := func() -> void:
		game_state = "hub" if from_hub else "codex"
		codex_tab = "story"
		_show_codex()
	_play_story_cutscene(scene_id, return_cb)


func _apply_cutscene_beat() -> void:
	var beats: Array = active_cutscene.get("beats", [])
	if beats.is_empty():
		_finish_cutscene()
		return
	cutscene_beat_idx = clampi(cutscene_beat_idx, 0, beats.size() - 1)
	var beat: Dictionary = beats[cutscene_beat_idx]
	animate_screen_enter = (cutscene_beat_idx == 0)
	_clear_ui()
	var ui_refs: Dictionary = TLRScreens.build_cutscene(self, screen_canvas, active_cutscene, cutscene_beat_idx)
	cutscene_text_label = ui_refs.get("text_label") as Label
	cutscene_next_btn = ui_refs.get("next_btn") as Button
	cutscene_is_last = bool(ui_refs.get("is_last", false))
	cutscene_char_progress = 0.0
	_last_type_tick = -1
	if bool(settings.get("reduced_motion", false)) or DisplayServer.get_name() == "headless":
		cutscene_typing = false
		if is_instance_valid(cutscene_text_label):
			cutscene_text_label.visible_characters = -1
	else:
		cutscene_typing = true
		if is_instance_valid(cutscene_next_btn):
			cutscene_next_btn.text = "REVEAL LINE"

	if is_instance_valid(arena_visuals) and arena_visuals.has_method("begin_cutscene_shot"):
		var cam_p := str(beat.get("cam", "establish"))
		var pose := str(beat.get("pose", "idle"))
		var l_col: Color = beat.get("light", Color(0.76, 0.91, 1.0))
		arena_visuals.begin_cutscene_shot(cam_p, pose, l_col, 4.8)
		if cam_p == "victory_crown" and arena_visuals.has_method("trigger_crowd_surge"):
			arena_visuals.trigger_crowd_surge(3.5)

	var sfx_id := str(beat.get("sfx", ""))
	if not sfx_id.is_empty() and is_instance_valid(audio_engine):
		audio_engine.play_sfx(sfx_id, -4.5, 0.02)


func _advance_cutscene() -> void:
	if game_state != "cutscene":
		return
	if cutscene_typing and is_instance_valid(cutscene_text_label):
		cutscene_typing = false
		cutscene_text_label.visible_characters = -1
		if is_instance_valid(cutscene_next_btn):
			cutscene_next_btn.text = "BEGIN  →" if cutscene_is_last else "NEXT  →"
		return
	var beats: Array = active_cutscene.get("beats", [])
	if cutscene_beat_idx + 1 < beats.size():
		cutscene_beat_idx += 1
		_apply_cutscene_beat()
	else:
		_finish_cutscene()


func _prev_cutscene_beat() -> void:
	if game_state != "cutscene":
		return
	if cutscene_beat_idx > 0:
		cutscene_beat_idx -= 1
		_apply_cutscene_beat()


func _skip_cutscene() -> void:
	if game_state != "cutscene":
		return
	_finish_cutscene()


func _finish_cutscene() -> void:
	cutscene_typing = false
	cutscene_text_label = null
	cutscene_next_btn = null
	var cb := cutscene_after_cb
	cutscene_after_cb = Callable()
	active_cutscene.clear()
	if is_instance_valid(arena_visuals) and arena_visuals.has_method("end_cutscene"):
		arena_visuals.end_cutscene(player_controller.camera if is_instance_valid(player_controller) else camera)
	if cb.is_valid():
		cb.call()
	else:
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
	combat_paused = false
	combat_drawer_open = false
	combat_review_open = false
	round_transition_open = false
	combat_banner_title = ""
	combat_banner_sub = ""
	hud_player_hp = -1.0
	hud_player_stamina = -1.0
	hud_enemy_hp = -1.0
	hud_enemy_stamina = -1.0

	round_no = 1
	turn_no = 1
	player_blocking = false
	player_slipping = false
	player_combo_ready = false
	player_counter_window = false
	player_momentum = false
	momentum_spent_turn = false
	enemy_staggered = false
	enemy_enraged = false
	enemy_taunt_buff = false
	player_bleeding = 0
	brass_charges = 0
	adrenaline = 0.0
	combo_streak = 0
	round_first_hit_available = true
	fight_turns_total = 0
	fight_used_block = false
	fight_big_hits = 0
	enemy_blinded = 0
	enemy_drained = 0
	loaded_bonus = 0
	loaded_tape_risk = false
	energy_penalty_pending = false
	player.speed = minf(60.0, float(player.get("speed", 0.0)) + next_fight_speed_bonus)
	next_fight_speed_bonus = 0.0
	enemy_next_action.clear()
	player_last_move_id = ""
	current_bout_modifier = _bout_modifier_for_fight(fight_index) if not training_active else {}
	_disable_realtime_combat()
	if is_instance_valid(arena_visuals) and arena_visuals.has_method("end_cutscene"):
		arena_visuals.end_cutscene(player_controller.camera if is_instance_valid(player_controller) else camera)

	var roster_index := _opponent_template_index(fight_index)
	if roster_index < 0 or roster_index >= enemy_templates.size():
		push_error("Tournament roster references a missing opponent.")
		_end_run(false, "The next opponent could not be loaded.")
		return

	var template: Dictionary = enemy_templates[roster_index].duplicate(true)

	var visual_scale := 1.0 + float(fight_index) * 0.115

	enemy = {
		"id": str(template.get("id", "")),
		"name": template.get("name", "Unknown Fighter"),
		"archetype": template.get("archetype", "Boxer"),
		"health": float(template.get("health", 100.0)) * visual_scale,
		"max_health": float(template.get("health", 100.0)) * visual_scale,
		"stamina": float(template.get("stamina", 100.0)) * visual_scale,
		"max_stamina": float(template.get("stamina", 100.0)) * visual_scale,
		"damage": float(template.get("damage", 10.0)) * (1.0 + fight_index * 0.07),
		"speed": float(template.get("speed", 10.0)) + fight_index * 1.2 + event_enemy_speed_buff,
		"defence": float(template.get("defence", 5.0)) + fight_index * 0.7,
		"tell": template.get("tell", ""),
		"trick": template.get("trick", ""),
		"accuracy": 82.0
	}
	event_enemy_speed_buff = 0.0

	if is_instance_valid(arena_visuals) and arena_visuals.has_method("set_opponent_appearance"):
		arena_visuals.set_opponent_appearance(template.get("visual", {}))
		opponent_mesh = arena_visuals.opponent_body
		opponent_mat = arena_visuals.opponent_material
	elif fight_index == 7:
		enemy_mat_color(Color(0.12, 0.10, 0.12))
	else:
		enemy_mat_color(Color(0.34, 0.19, 0.16))

	_configure_enemy_ai()
	_reset_fighter_positions()

	# Turn-based combat is authoritative. Keep the real-time actors disabled.
	_disable_realtime_combat()
	_prepare_enemy_telegraph()
	if not training_active and not current_bout_modifier.is_empty():
		_log("STIPULATION — %s: %s" % [str(current_bout_modifier.get("name", "")).to_upper(), str(current_bout_modifier.get("desc", ""))])
	if not training_active:
		var walk_lore := TLRStory.get_fighter_lore(str(enemy.get("id", "")))
		var walk_line := str(walk_lore.get("walkout", ""))
		if not walk_line.is_empty():
			_log("%s: “%s”" % [str(enemy.get("name", "Opponent")), walk_line])
	if is_instance_valid(audio_engine):
		audio_engine.set_ambience("combat")
		audio_engine.play_sfx("bell_round", -4.0, 0.02)
	_show_combat()


func _bout_modifier_for_fight(f_idx: int) -> Dictionary:
	var pool: Array[Dictionary] = [
		{"id": "short_fuse", "name": "Short Fuse", "desc": "Heavy hits (+25% DMG) land harder both ways."},
		{"id": "iron_lungs", "name": "Iron Lungs", "desc": "High tempo: move stamina costs reduced by 3."},
		{"id": "back_alley", "name": "Back Alley Rules", "desc": "Bribed ref: dirty moves & loaded tape carry 50% less DQ risk."},
		{"id": "glass_pit", "name": "Glass Pit", "desc": "+10% Critical Hit chance for explosive swings."},
		{"id": "body_war", "name": "Body War", "desc": "Body shots & clinches drain +6 extra opponent stamina."},
		{"id": "quick_draw", "name": "Flow State Pit", "desc": "First landed hit each round grants Momentum (Free Follow-up)!"},
		{"id": "high_roller", "name": "High Roller Stake", "desc": "+50% Pit Cash payout for winning this bout."}
	]
	if f_idx <= 0:
		if absi(run_seed) % 2 == 0:
			return {"id": "standard", "name": "Underground Standard", "desc": "Standard 3-round bout. Read the tells."}
		return pool[absi(run_seed * 7) % pool.size()].duplicate(true)
	if f_idx >= FIGHT_COUNT - 1:
		return {"id": "championship", "name": "Blood Pit Finale", "desc": "+12% CRIT both ways. Champion surges on Turns 3 & 6."}
	var pick := absi(run_seed * 31 + f_idx * 17) % pool.size()
	return pool[pick].duplicate(true)


func _effective_move_cost(move: Dictionary) -> float:
	var m_id := str(move.get("id", ""))
	if m_id in ["headbutt", "low_blow"] and has_perk("dirty_work"):
		return 0.0
	var cost := float(move.get("cost", 0.0))
	var lv := _move_level(m_id)
	if cost > 0.0 and lv > 1:
		cost = maxf(2.0, cost - float(lv - 1))
	if not training_active and str(current_bout_modifier.get("id", "")) == "iron_lungs" and cost > 0.0:
		cost = maxf(2.0, cost - 3.0)
	return cost


func _move_level(id: String) -> int:
	return maxi(1, int(move_levels.get(id, 1)))


func has_perk(perk_id: String) -> bool:
	return owned_perks.has(perk_id)


func _get_perk_data(perk_id: String) -> Dictionary:
	for p in PERK_CATALOG:
		if str(p.get("id", "")) == perk_id:
			return p
	return {}


func _generate_run_roster(seed_val: int) -> Array[int]:
	var total := enemy_templates.size()
	if total < 10:
		var fallback: Array[int] = []
		alt_roster.clear()
		bout_bounties.clear()
		for i in range(FIGHT_COUNT):
			var idx := mini(i, maxi(0, total - 1))
			fallback.append(idx)
			alt_roster.append((idx + 1) % maxi(1, total))
			bout_bounties.append({"a": "cash", "b": "rare_item"})
		return fallback

	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed_val + 77

	# Partition non-boss pool dynamically & boss pool [9..total-1]
	var non_boss: Array[int] = []
	var bosses: Array[int] = []
	for ti in range(total):
		var tier := int(enemy_templates[ti].get("tier", 1))
		if tier >= 4:
			bosses.append(ti)
		else:
			non_boss.append(ti)
	if bosses.is_empty():
		bosses.append(total - 1)

	# Full Fisher-Yates shuffle on non_boss and bosses so brackets vary wildly every run
	for pool_arr in [non_boss, bosses]:
		for i in range(pool_arr.size() - 1, 0, -1):
			var j := local_rng.randi_range(0, i)
			var tmp: int = pool_arr[i]
			pool_arr[i] = pool_arr[j]
			pool_arr[j] = tmp

	var tier_score: Dictionary = {}
	for ti in non_boss:
		tier_score[ti] = int(enemy_templates[ti].get("tier", 1)) * 2 + local_rng.randi_range(0, 1)

	# Build primary roster (7 unique non-boss fighters sorted lightly by early/mid/late tiers + 1 random Champion)
	var picked := non_boss.slice(0, mini(7, non_boss.size()))
	while picked.size() < 7:
		picked.append(local_rng.randi_range(0, non_boss.size() - 1))
	picked.sort_custom(func(a: int, b: int) -> bool:
		return int(tier_score.get(a, 0)) < int(tier_score.get(b, 0))
	)
	picked.append(bosses[0])

	# Build Alternate Challenger for each bout (never equal to primary) & distinct Bounties
	alt_roster.clear()
	bout_bounties.clear()
	var bounty_types := ["cash", "rare_item", "trait_drop", "recovery", "skill_manual"]
	for i in range(FIGHT_COUNT):
		if i == FIGHT_COUNT - 1:
			var alt_b: int = bosses[1] if bosses.size() > 1 else bosses[0]
			alt_roster.append(alt_b)
		else:
			var cand: int = non_boss[(i + local_rng.randi_range(2, non_boss.size() - 1)) % non_boss.size()]
			if cand == picked[i]:
				cand = (cand + 1) % non_boss.size()
			alt_roster.append(cand)
		var ba: String = bounty_types[local_rng.randi_range(0, bounty_types.size() - 1)]
		var bb: String = bounty_types[(bounty_types.find(ba) + local_rng.randi_range(1, bounty_types.size() - 1)) % bounty_types.size()]
		bout_bounties.append({"a": ba, "b": bb})

	return picked


func _bounty_label(tag: String) -> String:
	match tag:
		"cash": return "+$35 PURSE"
		"rare_item": return "RARE ITEM DROP"
		"trait_drop": return "GUARANTEED TRAIT"
		"recovery": return "+22 HP POST-WIN"
		"skill_manual": return "+1 MOVE UPGRADE"
		_: return "STANDARD PURSE"


func _current_bout_bounty() -> String:
	if fight_index < 0 or fight_index >= bout_bounties.size():
		return "cash"
	var pair: Dictionary = bout_bounties[fight_index]
	var br := int(bout_branches[fight_index]) if fight_index < bout_branches.size() else 0
	return str(pair.get("b" if br == 1 else "a", "cash"))


func _contract_for_fight(f_idx: int) -> Dictionary:
	var pool: Array[Dictionary] = [
		{"id": "speed_ko", "name": "BLITZ KO", "desc": "Win in <= 8 turns for +$55 Pit Cash.", "bonus": 55},
		{"id": "no_block", "name": "NO SHELLS", "desc": "Win without using Block for +$50 Pit Cash.", "bonus": 50},
		{"id": "showstopper", "name": "SHOWSTOPPER", "desc": "Land 2+ Crits or Finishers for +$55 Pit Cash.", "bonus": 55},
		{"id": "untouched", "name": "CLEAN SHEET", "desc": "Finish above 55% HP for +$45 Pit Cash.", "bonus": 45}
	]
	var idx := absi(run_seed * 13 + f_idx * 29) % pool.size()
	return pool[idx].duplicate(true)


func _contract_live_status() -> Dictionary:
	if not contract_accepted or training_active:
		return {"active": false}
	var c := _contract_for_fight(fight_index)
	var cid := str(c.get("id", ""))
	var c_bonus := int(c.get("bonus", 50))
	var failed := false
	var progress := ""
	match cid:
		"speed_ko":
			failed = fight_turns_total >= 8
			progress = ("TURN %d / 8 — ON PACE ✓" % mini(8, fight_turns_total + 1)) if not failed else ("TURN %d / 8 — FAILED ✗" % (fight_turns_total + 1))
		"no_block":
			failed = fight_used_block
			progress = "NO BLOCKS USED ✓" if not failed else "BLOCKED — FAILED ✗"
		"showstopper":
			progress = ("BIG HITS: %d / 2 ✓" if fight_big_hits >= 2 else "CRITS / FINISHERS: %d / 2") % fight_big_hits
		"untouched":
			var pct := int(roundf(float(player.get("health", 100.0)) / maxf(1.0, float(player.get("max_health", 100.0))) * 100.0))
			failed = pct < 55
			progress = ("HP %d%% >= 55%% ✓" % pct) if not failed else ("HP %d%% < 55%% ✗" % pct)
	return {"active": true, "name": str(c.get("name", "CONTRACT")), "bonus": c_bonus, "progress": progress, "failed": failed}


func _grant_adrenaline(amount: float) -> void:
	if training_active:
		return
	var prev := adrenaline
	adrenaline = clampf(adrenaline + amount, 0.0, 100.0)
	if prev < 100.0 and adrenaline >= 100.0:
		_log("ADRENALINE FULL! Your next punch unleashes LIGHTS OUT (×1.75 DMG + Stagger)!")




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


func _get_item_rarity(id: String) -> String:
	var item := _get_item_data(id)
	return str(item.get("rarity", "common")).to_lower()


func _item_timing(id: String) -> String:
	match id:
		"ice":
			return "Between fights — restore 22 health in the hub."
		"salts":
			return "Passive — automatically revive once after a lethal hit."
		"sparring_tonics":
			return "Anytime (Hub or Combat) — +12 permanent max HP and heal +18 HP."
		"cutman_kit", "adrenaline_shot", "nitro_salts":
			return "Quick-Use — activates in combat WITHOUT spending your turn!"
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
	_label("CORNER BAG — %d / 3 SLOTS" % inventory.size(), 15, Color(0.40, 0.75, 0.95))

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
			_label("PERSISTENT / NEXT-FIGHT EFFECTS", 15, Color(0.40, 0.75, 0.95))
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

	_label("ACTIVE EFFECTS", 15, Color(0.40, 0.75, 0.95))
	if active_effects.is_empty():
		_label("No temporary effects currently active.", 12)
	else:
		for effect in active_effects:
			_label("• " + effect, 12, Color(0.82, 0.76, 0.68))


# ---------------------------------------------------------
# TURN-BASED COMBAT SCREEN
# ---------------------------------------------------------

func _hud_panel(parent: Control, rect: Rect2, tint: Color = Color(0.025, 0.035, 0.055, 0.88)) -> PanelContainer:
	var card := PanelContainer.new()
	card.position = rect.position
	card.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.border_color = Color(0.22, 0.42, 0.62, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	return card


func _hud_label(parent: Control, value: String, size: int = 14, color: Color = Color(0.88, 0.92, 0.98)) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _hud_bar(parent: Control, value: float, maximum: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 13)
	bar.min_value = 0.0
	bar.max_value = maxf(1.0, maximum)
	bar.value = clampf(value, 0.0, bar.max_value)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.10, 0.14)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	parent.add_child(bar)
	return bar


func _animate_hud_bar(bar: ProgressBar, previous: float, target: float) -> void:
	bar.value = target if previous < 0.0 else clampf(previous, 0.0, bar.max_value)
	var tween := create_tween()
	tween.tween_property(bar, "value", clampf(target, 0.0, bar.max_value), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _hud_button(parent: Control, caption: String, callback: Callable, disabled: bool = false, compact: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.disabled = disabled
	button.custom_minimum_size = Vector2(104 if compact else 138, 32 if compact else 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13 if compact else 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.17, 0.25)
	normal.border_color = Color(0.20, 0.43, 0.62)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.27, 0.37)
	button.add_theme_stylebox_override("hover", hover)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _toggle_combat_pause() -> void:
	combat_paused = true
	animate_pause_open = true
	_show_combat()

func _resume_combat() -> void:
	combat_paused = false
	animate_pause_open = false
	_show_combat()

func _toggle_combat_drawer() -> void:
	combat_drawer_open = not combat_drawer_open
	animate_drawer_open = combat_drawer_open
	_show_combat()


func _hud_abs_label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _hud_abs_bar(parent: Control, rect: Rect2, value: float, maximum: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.min_value = 0.0
	bar.max_value = maxf(1.0, maximum)
	bar.value = clampf(value, 0.0, bar.max_value)
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.035, 0.045, 0.060, 0.95)
	background.set_corner_radius_all(2)
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	foreground.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)
	parent.add_child(bar)
	return bar


func _hud_abs_button(parent: Control, caption: String, rect: Rect2, callback: Callable, disabled: bool, selected: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.91, 0.93, 0.95))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.48, 0.53))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.055, 0.075, 0.91) if not selected else Color(0.035, 0.14, 0.16, 0.96)
	normal.border_color = Color(0.20, 0.31, 0.39, 0.9) if not selected else Color(0.30, 0.76, 0.70, 1.0)
	normal.set_border_width_all(1 if not selected else 2)
	normal.set_corner_radius_all(2)
	normal.content_margin_left = 5
	normal.content_margin_right = 5
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.10, 0.17, 0.21, 0.98)
	button.add_theme_stylebox_override("hover", hover)
	var unavailable := normal.duplicate() as StyleBoxFlat
	unavailable.bg_color = Color(0.025, 0.035, 0.045, 0.82)
	button.add_theme_stylebox_override("disabled", unavailable)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _dismiss_round_transition() -> void:
	round_transition_open = false
	animate_round_transition = false
	animate_phase_banner = true
	_show_combat()


func _open_review_from_pause() -> void:
	combat_paused = false
	combat_review_open = true
	review_scenario = ""
	_show_combat()


func _show_combat() -> void:
	game_state = "combat"
	if is_instance_valid(combat_hud):
		combat_hud.queue_free()
		combat_hud = null
	if is_instance_valid(screen_canvas):
		for child in screen_canvas.get_children():
			child.queue_free()
		screen_canvas.hide()
	panel.hide()
	ui_shade.color = Color(0.0, 0.0, 0.0, 0.0)
	_layout_ui()
	_update_scene_framing()

	combat_hud = TLRCombatUI.build_combat_hud(self, root_ui)
	if training_active and animate_screen_enter and not bool(settings.get("reduced_motion", false)):
		animate_screen_enter = false
		combat_hud.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(combat_hud, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		animate_screen_enter = false


func _combat_item_slots() -> Array[String]:
	var result: Array[String] = []
	for item_variant in inventory:
		result.append(str(item_variant))
	return result


func _show_combat_review_overlay(sx: float, sy: float, target_hud: Control = null) -> void:
	var host: Control = target_hud if is_instance_valid(target_hud) else (combat_hud if is_instance_valid(combat_hud) else root_ui)
	var s := minf(sx, sy)
	var shade := ColorRect.new()
	shade.color = Color(0.004, 0.009, 0.018, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.z_index = 95
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(shade)
	var review_panel := TLRTheme.make_panel(shade, Rect2(120.0 * s, 64.0 * s, 1360.0 * s, 772.0 * s), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 2, 24, 20)
	var review_col := VBoxContainer.new()
	review_col.position = Vector2(24.0 * s, 20.0 * s)
	review_col.size = Vector2(1312.0 * s, 732.0 * s)
	review_col.add_theme_constant_override("separation", 10)
	review_panel.add_child(review_col)
	review_col.add_child(TLRTheme.make_label("COMBAT UI  /  STATE REVIEW", 24, TLRTheme.TEXT_PRIMARY, true))
	review_col.add_child(TLRTheme.make_label("Each card opens a focused state reference. Press F1 to return to the index or the live fight.", 13, TLRTheme.TEXT_MUTED, false))

	var cards: Array[Dictionary] = [
		{"id":"player_turn","name":"01  PLAYER TURN","desc":"Default HUD and action selection."},
		{"id":"telegraph","name":"02  OPPONENT TELEGRAPH","desc":"Heavy-right tell; defend or evade."},
		{"id":"impact","name":"03  ATTACK IMPACT","desc":"Floating damage and stamina loss."},
		{"id":"block","name":"04  BLOCK","desc":"Reduced damage and guard feedback."},
		{"id":"dodge","name":"05  DODGE","desc":"Avoid the blow and create a counter window."},
		{"id":"counter","name":"06  COUNTER","desc":"Consume the window for bonus damage."},
		{"id":"clinch","name":"07  CLINCH","desc":"Smother the attack and drain stamina."},
		{"id":"recovery","name":"08  RECOVERY","desc":"Stamina gain with an exposed warning."},
		{"id":"low_health","name":"09  LOW HEALTH","desc":"Danger treatment and last-stand status."},
		{"id":"low_stamina","name":"10  LOW STAMINA","desc":"Affordability and unavailable move states."},
		{"id":"effects","name":"11  BUFFS & DEBUFFS","desc":"Effect durations and queued next-turn costs."},
		{"id":"player_ko","name":"12  PLAYER KNOCKOUT","desc":"Run-ended combat state."},
		{"id":"round_end","name":"13  ROUND TRANSITION","desc":"Round-end summary and continue."},
		{"id":"drawer","name":"14  FIGHTER DRAWER","desc":"Items, moves, stats and active effects."},
		{"id":"tooltip","name":"15  MOVE TOOLTIP","desc":"Cost, effect, accuracy and turn cost."},
		{"id":"enemy_ko","name":"16  OPPONENT KNOCKOUT","desc":"Fight-cleared combat state."},
		{"id":"fatigue","name":"17  FATIGUE RECOVERY","desc":"Rest restores 24 stamina."},
		{"id":"pause","name":"18  PAUSE","desc":"Resume without changing combat."},
		{"id":"new_round","name":"19  NEW ROUND","desc":"Round 02, turn 01."},
		{"id":"windup","name":"20  ATTACK WIND-UP","desc":"Input lock before the incoming hit."},
		{"id":"item_used","name":"21  ITEM USED","desc":"Energy Drink consumed."},
		{"id":"energy","name":"22  ENERGY FROM FATIGUE","desc":"Restore 35 stamina; crash queued."}
	]

	if review_scenario.is_empty():
		var review_grid := GridContainer.new()
		review_grid.columns = 4
		review_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		review_grid.add_theme_constant_override("h_separation", 8)
		review_grid.add_theme_constant_override("v_separation", 8)
		review_col.add_child(review_grid)
		for card in cards:
			var entry := Button.new()
			entry.text = str(card.name) + "\n" + str(card.desc)
			entry.custom_minimum_size = Vector2(310.0 * s, 72.0 * s)
			entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			TLRTheme.style_button(entry, "default", 11)
			entry.pressed.connect(_open_review_scenario.bind(str(card.id)))
			review_grid.add_child(entry)
		var close_btn := Button.new()
		close_btn.text = "RETURN TO FIGHT  /  F1"
		close_btn.custom_minimum_size = Vector2(0, 44 * s)
		TLRTheme.style_button(close_btn, "teal", 13)
		close_btn.pressed.connect(_close_combat_review)
		review_col.add_child(close_btn)
	else:
		var selected: Dictionary = {}
		for card in cards:
			if str(card.id) == review_scenario:
				selected = card
				break
		review_col.add_child(TLRTheme.make_label(str(selected.get("name", "REVIEW SCENARIO")), 22, TLRTheme.CYAN, true))
		review_col.add_child(TLRTheme.make_label(str(selected.get("desc", "")), 16, TLRTheme.TEXT_PRIMARY, false))
		review_col.add_child(TLRTheme.make_label("Reference state: use the live fight controls to reproduce this state. The review index does not alter fighter health, stamina, turn count or run progress.", 14, TLRTheme.TEXT_MUTED, false))
		var back_btn := Button.new()
		back_btn.text = "BACK TO REVIEW INDEX  /  F1"
		back_btn.custom_minimum_size = Vector2(0, 44 * s)
		TLRTheme.style_button(back_btn, "teal", 13)
		back_btn.pressed.connect(_back_to_review_index)
		review_col.add_child(back_btn)
		var ret_btn := Button.new()
		ret_btn.text = "RETURN TO FIGHT"
		ret_btn.custom_minimum_size = Vector2(0, 44 * s)
		TLRTheme.style_button(ret_btn, "default", 13)
		ret_btn.pressed.connect(_close_combat_review)
		review_col.add_child(ret_btn)


func _open_review_scenario(id: String) -> void:
	review_scenario = id
	_show_combat()


func _back_to_review_index() -> void:
	review_scenario = ""
	_show_combat()


func _close_combat_review() -> void:
	combat_review_open = false
	review_scenario = ""
	_show_combat()


func _forfeit_run() -> void:
	if training_active:
		_exit_training_to_menu()
		return
	_disable_realtime_combat()
	_end_run(false, "You walked away from the fight.")


func _exit_training_to_menu() -> void:
	training_active = false
	training_retry_flag = false
	pending_first_run_tutorial = false
	combat_paused = false
	combat_drawer_open = false
	combat_review_open = false
	_disable_realtime_combat()
	_show_main_menu()


func _skip_tutorial_to_run() -> void:
	training_active = false
	training_retry_flag = false
	pending_first_run_tutorial = false
	tutorial_completed = true
	_save_meta_flags()
	combat_paused = false
	combat_drawer_open = false
	combat_review_open = false
	_disable_realtime_combat()
	_show_style_select(selected_slot)


# ---------------------------------------------------------
# TURN-BASED COMBAT RESOLUTION
# ---------------------------------------------------------

func _speed_chance(speed: float) -> float:
	return clampf(speed, 0.0, 60.0)


func _player_move(id: String) -> void:
	if game_state != "combat" or combat_paused:
		return

	if not owned_moves.has(id):
		return

	var move := _get_move(id)
	if move.is_empty():
		return

	var cost := _effective_move_cost(move)
	if float(player.get("stamina", 0.0)) < cost:
		_log("You're too exhausted to use %s." % str(move.get("name", id)))
		_show_combat()
		return

	if training_active and not _training_move_is_acceptable(id):
		training_retry_flag = true
		training_feedback = _training_retry_feedback(id)
		combat_banner_title = "TRY ANOTHER ANSWER"
		combat_banner_sub = training_feedback
		animate_combat_banner = true
		animate_phase_banner = true
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("ui_retry", -6.0, 0.02)
		_show_combat()
		return

	var stamina_before_action := float(player.get("stamina", 0.0))
	var enemy_stamina_before_action := float(enemy.get("stamina", 0.0))
	var consumed_momentum := player_momentum and not training_active
	player_momentum = false
	momentum_spent_turn = consumed_momentum
	player_last_move_id = id
	if training_active:
		training_retry_flag = false
		training_feedback = _training_feedback_for_move(id)

	if arena_visuals and arena_visuals.has_method("player_action"):
		arena_visuals.player_action(id)
	if is_instance_valid(audio_engine):
		match id:
			"jab": audio_engine.play_sfx("punch_jab", -4.0)
			"block": audio_engine.play_sfx("block_thud", -5.0)
			"slip": audio_engine.play_sfx("whoosh_slip", -5.0)
			"rest": audio_engine.play_sfx("rest_breath", -5.0)
			"clinch": audio_engine.play_sfx("clinch_tie", -4.0)
			"body_shot": audio_engine.play_sfx("punch_body", -4.0)
			"feint": audio_engine.play_sfx("whoosh_slip", -8.0)
			"counter": audio_engine.play_sfx("whoosh_slip", -4.0)
			_: audio_engine.play_sfx("punch_heavy", -3.0)

	if round_transition_open:
		return

	var enemy_kind := str(enemy_next_action.get("kind", "attack")).to_lower()

	if id == "rest":
		player.stamina = minf(
			player.max_stamina,
			player.stamina + 24.0
		)
		player_combo_ready = false
		combat_banner_title = "TAKE A BREATH"
		combat_banner_sub = "+24 STA restored" + (" • Clean breathing window!" if enemy_kind == "recovery" else " • Guard is open")
		_log("You take a breath. +24 stamina.")

	elif id == "block":
		player.stamina = maxf(0.0, player.stamina - cost)
		player_blocking = true
		fight_used_block = true
		player_combo_ready = false
		if has_perk("rope_a_dope"):
			player.stamina = minf(player.max_stamina, player.stamina + 5.0)
		combat_banner_title = "GUARD HOLDS"
		combat_banner_sub = ("Rope-A-Dope (+5 STA, reflect) • " if has_perk("rope_a_dope") else "Damage reduced • ") + "%d stamina spent" % int(cost)
		_log("You shell up behind your gloves.")

	elif id == "slip":
		player.stamina -= cost
		player_slipping = true
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("foot_shuffle", -4.0)
		combat_banner_title = "CLEAN SLIP"
		combat_banner_sub = "Evading blow • Opens counter window"
		_log("You slip off the centerline, lining up an opening.")

	elif id == "feint":
		player.stamina -= cost
		enemy_blinded = maxi(enemy_blinded, 1)
		player_combo_ready = true
		_grant_adrenaline(15.0)
		var gained_mom := false
		if not consumed_momentum and not training_active:
			player_momentum = true
			gained_mom = true
		var broke_guard := (enemy_kind in ["guard", "taunt"])
		if broke_guard:
			enemy_staggered = true
			enemy_taunt_buff = false
			enemy.stamina = maxf(0.0, enemy.stamina - 8.0)
			combat_banner_title = "GUARD PULLED OPEN!"
			combat_banner_sub = ("MOMENTUM + " if gained_mom else "") + "Rhythm Ready (+25% power) • Opp staggered"
			_log("Your feint draws his gloves out of position!")
		else:
			combat_banner_title = "FEINT + MOMENTUM!" if gained_mom else "FEINT LANDS"
			combat_banner_sub = ("FREE FOLLOW-UP ACTION! • " if gained_mom else "") + "Rhythm Ready (+25% power)"
			_log("Your feint freezes his read — follow up before he resets!")

	elif id == "clinch":
		player.stamina -= cost
		var drain_amt := 16.0 if str(current_bout_modifier.get("id", "")) == "body_war" else 10.0
		enemy.stamina = maxf(0.0, enemy.stamina - drain_amt)
		player.stamina = minf(player.max_stamina, player.stamina + 8.0)
		enemy_staggered = true
		enemy_taunt_buff = false
		_grant_adrenaline(15.0)
		combat_banner_title = "TIED UP"
		combat_banner_sub = "Opp -%d STA & Staggered • You +8 STA" % int(drain_amt)
		_log("You smother them in a clinch, disrupting their rhythm.")

	elif id == "counter":
		player.stamina -= cost

		var tell := str(enemy_next_action.get("tell", enemy.get("tell", ""))).to_lower()
		var action_name := str(enemy_next_action.get("name", "")).to_lower()
		var guessed := player_counter_window or tell.contains("right") or tell.contains("loads") or action_name.contains("right") or action_name.contains("flurry") or action_name.contains("combination")

		if guessed:
			var mult := 1.45 if player_counter_window else 1.35
			if has_perk("counter_king"):
				mult += 0.35
				player.stamina = minf(player.max_stamina, player.stamina + 6.0)
			_deal_player_damage(move, mult)
			player_counter_window = false
			combat_banner_title = "COUNTER OPENING!" if mult > 1.4 else "PERFECT COUNTER"
			combat_banner_sub = "Clean intercept (×%.2f) • %d stamina spent" % [mult, int(cost)]
			_log("Sharp intercept! Counter lands clean.")
		else:
			combat_banner_title = "COUNTER WHIFFS"
			combat_banner_sub = "Wrong read — use after Slip/Heavy Tell • %d STA" % int(cost)
			_log("No opening there. The counter misses its window.")

	elif id in ["headbutt", "low_blow"]:
		player.stamina -= cost
		var dq_chance := 0.18 if id == "headbutt" else 0.27
		if str(current_bout_modifier.get("id", "")) == "back_alley":
			dq_chance *= 0.5
		if has_perk("dirty_work"):
			dq_chance *= 0.5

		if not bribe_ready and rng.randf() < dq_chance:
			_log("The referee catches the dirty move. DISQUALIFIED.")
			_end_run(false, "Disqualified for an illegal move.")
			return

		if bribe_ready:
			bribe_ready = false

		_deal_player_damage(move, 1.0)
		enemy_staggered = true
		enemy_taunt_buff = false
		if has_perk("dirty_work") and not training_active:
			cash += 15
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("crowd_boo", -5.5)
		combat_banner_title = "%s CONNECTS" % str(move.get("name", id)).to_upper()
		combat_banner_sub = "Opponent Staggered • " + ("+$15 Dirty Work" if has_perk("dirty_work") else "%d stamina spent" % int(cost))

		if id == "low_blow":
			enemy.stamina = maxf(0.0, enemy.stamina - 18.0)

	else:
		player.stamina -= cost
		var enemy_hp_before := float(enemy.health)
		var tactical_mult := 1.0
		var tactical_tag := ""

		var used_setup := false
		var clear_combo := false
		var clear_window := false
		if player_combo_ready and id in ["hook", "uppercut", "haymaker", "overhand", "body_shot"]:
			tactical_mult *= 1.25
			clear_combo = true
			used_setup = true
			tactical_tag = "RHYTHM +25%"
		if player_counter_window and id in ["hook", "uppercut", "haymaker", "overhand", "one_two"]:
			tactical_mult *= (1.60 if has_perk("counter_king") else 1.25)
			if has_perk("counter_king"):
				player.stamina = minf(player.max_stamina, player.stamina + 6.0)
			clear_window = true
			used_setup = true
			tactical_tag = "OPENING!"

		var broke_guard := false
		if enemy_kind == "guard":
			if id in ["overhand", "body_shot"]:
				tactical_mult *= 1.40
				broke_guard = true
				enemy_staggered = true
				tactical_tag = "GUARD BROKEN!"
			else:
				tactical_mult *= 0.50
				tactical_tag = "GLANCING (GUARDED)"
		elif enemy_kind == "recovery":
			tactical_mult *= 1.30
			enemy_next_action["recover_interrupted"] = true
			tactical_tag = "PUNISHED RECOVERY!"
		elif enemy_kind == "taunt":
			tactical_mult *= 1.25
			enemy_staggered = true
			enemy_next_action["taunt_broken"] = true
			tactical_tag = "TAUNT INTERRUPTED!"

		if str(current_bout_modifier.get("id", "")) == "short_fuse" and id in ["hook", "uppercut", "haymaker", "overhand"]:
			tactical_mult *= 1.25

		var was_first_round_hit := round_first_hit_available
		_deal_player_damage(move, tactical_mult)
		if clear_combo:
			player_combo_ready = false
		if clear_window:
			player_counter_window = false
		var dmg_dealt := roundi(enemy_hp_before - float(enemy.health))
		if dmg_dealt > 0:
			combo_streak += 1
			if id in ["jab", "one_two"]:
				player_combo_ready = true
			elif not used_setup:
				player_combo_ready = false
			if not consumed_momentum and not training_active:
				if broke_guard or enemy_kind == "taunt" or (was_first_round_hit and str(current_bout_modifier.get("id", "")) == "quick_draw"):
					player_momentum = true
			var banner_prefix := tactical_tag + " • " if not tactical_tag.is_empty() else ""
			var next_hint := " • MOMENTUM READY!" if player_momentum else (" • Rhythm Ready!" if player_combo_ready and id in ["jab", "one_two"] else "")
			combat_banner_title = "%s%s CONNECTS" % ["GUARD SHATTERED: " if broke_guard else "", str(move.get("name", id)).to_upper()]
			combat_banner_sub = "%s%d damage • %d STA%s" % [banner_prefix, dmg_dealt, int(cost), next_hint]
			if broke_guard:
				_grant_adrenaline(32.0)
		else:
			combo_streak = 0
			player_combo_ready = false
			combat_banner_title = "%s MISSES" % str(move.get("name", id)).to_upper()
			combat_banner_sub = "%d stamina spent" % int(cost)

		if id == "body_shot":
			var body_drain := (18.0 if str(current_bout_modifier.get("id", "")) == "body_war" else 12.0) + float((_move_level(id) - 1) * 4)
			enemy.stamina = maxf(0.0, enemy.stamina - body_drain)

		if id == "haymaker" and dmg_dealt == 0:
			player.stamina = maxf(0.0, player.stamina - 8.0)

		if id == "uppercut" and dmg_dealt > 0 and rng.randf() < (0.28 + 0.08 * float(_move_level(id) - 1)):
			enemy.stamina = maxf(0.0, enemy.stamina - 15.0)
			enemy_staggered = true

	if game_state != "combat":
		return

	player.stamina = clampf(player.stamina, 0.0, player.max_stamina)
	var stamina_delta := float(player.stamina) - stamina_before_action
	if absf(stamina_delta) >= 1.0:
		_show_floating_number(absf(stamina_delta), true, false, stamina_delta > 0.0)

	if enemy.health <= 0.0:
		_win_fight()
		return
	var enemy_stamina_delta := float(enemy.stamina) - enemy_stamina_before_action
	if absf(enemy_stamina_delta) >= 1.0:
		_show_floating_number(absf(enemy_stamina_delta), true, true, enemy_stamina_delta > 0.0)

	if player_momentum and not training_active:
		player_blocking = false
		player_slipping = false
		animate_combat_banner = not combat_banner_title.is_empty()
		animate_phase_banner = true
		_show_combat()
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

	if training_active and game_state == "combat":
		player.health = maxf(25.0, float(player.health))
		enemy.health = maxf(50.0, float(enemy.health))
		training_turn += 1
		if training_turn >= TRAINING_EXCHANGES:
			_finish_training()
			return
		if training_turn == 7:
			adrenaline = 100.0
		_prepare_enemy_telegraph()
		animate_combat_banner = not combat_banner_title.is_empty()
		animate_phase_banner = true
		_show_combat()
		return

	if game_state == "combat":
		_check_round()
		if game_state == "combat":
			_prepare_enemy_telegraph()
			animate_combat_banner = not combat_banner_title.is_empty()
			animate_phase_banner = true
			_show_combat()


func _show_floating_number(amount: float, is_stamina: bool, over_opponent: bool, is_gain: bool = false) -> void:
	if not is_instance_valid(root_ui) or game_state != "combat":
		return
	var label := Label.new()
	var prefix := "+" if is_gain else "-"
	var suffix := " STA" if is_stamina else ""
	label.text = "%s%d%s" % [prefix, roundi(amount), suffix]
	label.add_theme_font_size_override("font_size", 24 if not is_stamina else 19)
	var color := Color(0.40, 0.88, 1.0) if is_stamina else Color(1.0, 0.28, 0.22)
	if is_gain:
		color = Color(0.42, 0.92, 0.62)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 100
	root_ui.add_child(label)
	var start_position := Vector2(root_ui.size.x * (0.67 if over_opponent else 0.34), root_ui.size.y * 0.50)
	var active_camera := get_viewport().get_camera_3d()
	if is_instance_valid(active_camera):
		var world_position := Vector3.ZERO
		if over_opponent and is_instance_valid(opponent_mesh):
			world_position = opponent_mesh.global_position + Vector3.UP * 2.45
		elif is_instance_valid(player_controller) and is_instance_valid(player_controller.camera):
			var player_camera := player_controller.camera
			world_position = player_camera.global_position - player_camera.global_transform.basis.z * 0.85 - player_camera.global_transform.basis.y * 0.20
		if not active_camera.is_position_behind(world_position):
			start_position = active_camera.unproject_position(world_position)
	start_position.x = clampf(start_position.x, 24.0, root_ui.size.x - 120.0)
	start_position.y = clampf(start_position.y, 90.0, root_ui.size.y - 190.0)
	label.position = start_position
	label.pivot_offset = Vector2(36.0, 14.0)
	label.scale = Vector2(1.32, 1.32) if not bool(settings.get("reduced_motion", false)) else Vector2.ONE
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", start_position + Vector2(0, -52), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.72).set_delay(0.18)
	tween.chain().tween_callback(label.queue_free)

func _deal_player_damage(move: Dictionary, multiplier: float) -> void:
	var acc := float(move.get("accuracy", 100.0))
	var m_id := str(move.get("id", ""))
	if player_combo_ready and m_id in ["hook", "uppercut", "haymaker", "overhand", "body_shot"]:
		acc += 12.0
	if player_counter_window:
		acc += 15.0
	if rng.randf() * 100.0 > acc:
		_log("%s misses. The crowd groans." % str(move.get("name", "Your move")))
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("crowd_gasp", -6.5)
		return

	var damage_range: Array = move.get("damage", [5.0, 10.0])
	if damage_range.size() < 2:
		return

	var amount := rng.randf_range(
		float(damage_range[0]),
		float(damage_range[1])
	)

	amount += float(player.get("damage", 0.0)) * 0.45
	if has_perk("glass_knuckles"):
		amount += 5.0
	var lv := _move_level(m_id)
	if lv > 1:
		amount *= (1.0 + 0.22 * float(lv - 1))
	if has_perk("iron_chin") and float(player.get("health", 100.0)) <= float(player.get("max_health", 100.0)) * 0.35:
		amount *= 1.30
	if has_perk("combo_addict") and combo_streak > 0:
		amount *= (1.0 + minf(0.60, 0.15 * float(combo_streak)))
	if has_perk("sucker_punch") and round_first_hit_available:
		round_first_hit_available = false
		amount *= 1.55
		enemy.stamina = maxf(0.0, enemy.stamina - 8.0)
	else:
		round_first_hit_available = false
	if momentum_spent_turn and has_perk("momentum_king"):
		amount *= 1.25
		_grant_adrenaline(12.0)
	momentum_spent_turn = false
	amount *= multiplier
	amount += loaded_bonus
	loaded_bonus = 0
	if brass_charges > 0:
		brass_charges -= 1
		amount += 12.0
		enemy_staggered = true

	var is_finisher := (adrenaline >= 100.0)
	if is_finisher:
		adrenaline = 0.0
		amount *= 1.75
		enemy_staggered = true
		if not training_active:
			cash += 25
			fight_big_hits += 1
			respect += 5

	if loaded_tape_risk:
		loaded_tape_risk = false
		var tape_dq := 0.06 if str(current_bout_modifier.get("id", "")) == "back_alley" else 0.12
		if rng.randf() < tape_dq:
			_log("The referee spots the loaded tape. DISQUALIFIED.")
			_end_run(false, "Disqualified for using loaded tape.")
			return

	var critical := id_is_crit() or is_finisher
	if critical and not is_finisher:
		amount *= 1.5
		fight_big_hits += 1
		enemy_staggered = true

	var reduced := maxf(
		1.0,
		amount * (1.0 - float(enemy.defence) / 100.0)
	)

	if str(enemy.get("trick", "")) == "guard" and float(enemy.stamina) > 0.0:
		reduced *= 0.88
		_log("Their tight guard absorbs part of the impact.")

	enemy.health = maxf(0.0, enemy.health - reduced)
	run_highest_hit = maxi(run_highest_hit, roundi(reduced))
	if has_perk("bloodthirst") and critical:
		var heal_bt := minf(10.0, float(player.max_health) - float(player.health))
		player.health += heal_bt
		if heal_bt > 0.5:
			_show_floating_number(heal_bt, false, false, true)
	if not is_finisher:
		_grant_adrenaline(22.0)

	# Opponent Phase 2 Enrage at <= 50% HP for Berserker & Champion
	if not enemy_enraged and float(enemy.health) > 0.0 and float(enemy.health) <= float(enemy.max_health) * 0.50 and str(enemy.get("trick", "")) in ["berserker", "boss"]:
		enemy_enraged = true
		enemy.damage = float(enemy.damage) * 1.18
		enemy.stamina = minf(float(enemy.max_stamina), float(enemy.stamina) + 25.0)
		var mid_lore := TLRStory.get_fighter_lore(str(enemy.get("id", "")))
		var mid_txt := str(mid_lore.get("mid_line", "shifts into overdrive!"))
		_log("PHASE 2! %s: “%s”" % [str(enemy.get("name", "Opponent")), mid_txt])
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("crowd_gasp", -3.5)

	_show_floating_number(reduced, false, true)

	if arena_visuals and arena_visuals.has_method("opponent_hit"):
		arena_visuals.opponent_hit()
	if screen_shake and arena_visuals and arena_visuals.has_method("impact_shake") and (critical or multiplier > 1.1 or reduced >= 14.0):
		arena_visuals.impact_shake(1.45 if is_finisher else (1.3 if critical else 0.85))
	if is_instance_valid(audio_engine):
		if critical or is_finisher:
			audio_engine.play_sfx("crit_ko", -2.0)
			audio_engine.play_sfx("crowd_cheer", -4.5)
			_trigger_impact_flash(Color(1.0, 0.72, 0.28, 0.25) if is_finisher else Color(1.0, 0.92, 0.80, 0.20))
		else:
			audio_engine.play_sfx("punch_heavy" if multiplier > 1.1 else "punch_jab", -3.0)

	if is_finisher:
		_log("LIGHTS OUT FINISHER! %s obliterates for %d (+$25)!" % [str(move.get("name", "Your move")), int(reduced)])
	elif critical:
		_log("CRITICAL! %s lands for %d." % [str(move.get("name", "Your move")), int(reduced)])
	else:
		_log("%s connects for %d damage." % [str(move.get("name", "Your move")), int(reduced)])


func id_is_crit() -> bool:
	var chance := 0.05

	if player.health <= player.max_health * 0.25:
		chance += 0.08
	if str(current_bout_modifier.get("id", "")) == "glass_pit":
		chance += 0.10
	elif str(current_bout_modifier.get("id", "")) == "championship":
		chance += 0.12

	return rng.randf() < chance


func _prepare_enemy_telegraph() -> void:
	if training_active:
		var drills: Array[Dictionary] = [
			{"name": "Heavy Right", "tell": "Coach loads his right shoulder and draws the glove back.", "damage": 1.0, "accuracy": 100.0, "cost": 0.0, "kind": "attack"},
			{"name": "Body Shot", "tell": "Coach dips his level and turns toward your ribs.", "damage": 0.85, "accuracy": 100.0, "cost": 0.0, "kind": "attack"},
			{"name": "Quick Jab", "tell": "Coach steps in with a short, quick jab.", "damage": 0.65, "accuracy": 100.0, "cost": 0.0, "kind": "attack"},
			{"name": "Heavy Right", "tell": "Coach repeats the loaded right. He wants to see if you learned.", "damage": 1.0, "accuracy": 100.0, "cost": 0.0, "kind": "attack"},
			{"name": "Reset", "tell": "Coach lowers his gloves and gives you room to breathe.", "damage": 0.0, "accuracy": 100.0, "cost": 0.0, "kind": "recovery"},
			{"name": "Combination", "tell": "Coach rolls his shoulders and steps in with a controlled two-punch combination.", "damage": 1.05, "accuracy": 100.0, "cost": 0.0, "kind": "attack"},
			{"name": "High Guard", "tell": "Coach shells both gloves tight! Crack guard with Body Shot or Feint (triggers Momentum!).", "damage": 0.45, "accuracy": 75.0, "cost": 0.0, "kind": "guard"},
			{"name": "Showboat Taunt", "tell": "Coach drops his gloves to showboat! Unleash your 100% Lights Out Finisher now!", "damage": 0.0, "accuracy": 100.0, "cost": 0.0, "kind": "taunt"}
		]
		enemy_next_action = drills[mini(training_turn, drills.size() - 1)].duplicate(true)
		if arena_visuals and arena_visuals.has_method("show_enemy_telegraph"):
			var t_pose := str(enemy_next_action.get("name", ""))
			if str(enemy_next_action.get("kind", "")) == "guard":
				t_pose = "guard"
			elif str(enemy_next_action.get("kind", "")) == "taunt":
				t_pose = "taunt"
			elif str(enemy_next_action.get("kind", "")) == "recovery":
				t_pose = "recovery"
			arena_visuals.show_enemy_telegraph(t_pose)
		return

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

	if enemy.stamina < float(enemy.max_stamina) * 0.30:
		if enemy.stamina < 14.0:
			enemy_next_action = {
				"name": "Catching Breath",
				"tell": "Drops his gloves and breathes heavily — clean opening!",
				"damage": 0.0,
				"accuracy": 0.0,
				"cost": 0.0,
				"kind": "recovery"
			}
		else:
			enemy_next_action = {
				"name": "Desperate Swing",
				"tell": "Breathes heavily and drops his guard.",
				"damage": 0.72,
				"accuracy": 70.0,
				"cost": 5.0,
				"kind": "attack"
			}
	else:
		# Inject real tactical stances (High Guard & Recovery) alongside attacks
		var roll := rng.randf()
		var guard_chance := 0.30 if trick == "guard" else (0.20 if trick in ["counter", "boss"] else 0.14)
		var rec_chance := 0.18 if float(enemy.stamina) < float(enemy.max_stamina) * 0.55 else 0.06
		if enemy_staggered:
			guard_chance = 0.0
		if roll < guard_chance:
			enemy_next_action = {
				"name": "High Guard",
				"tell": "Raises both gloves tight around his jaw. Crack with Body Shot or Overhand.",
				"damage": 0.45,
				"accuracy": 75.0,
				"cost": 0.0,
				"kind": "guard"
			}
		elif trick in ["showboat", "boss"] and not enemy_staggered and roll < guard_chance + 0.20:
			enemy_next_action = {
				"name": "Showboat Taunt",
				"tell": "Waves you in with gloves dropped! Hit now to interrupt or he surges +35%!",
				"damage": 0.0,
				"accuracy": 100.0,
				"cost": 0.0,
				"kind": "taunt"
			}
		elif roll < guard_chance + rec_chance:
			enemy_next_action = {
				"name": "Catching Breath",
				"tell": "Drops his gloves slightly to catch his breath — punish or rest.",
				"damage": 0.0,
				"accuracy": 0.0,
				"cost": 0.0,
				"kind": "recovery"
			}
		else:
			enemy_next_action = options[rng.randi_range(0, options.size() - 1)].duplicate(true)
			enemy_next_action["kind"] = "attack"

	# Keep the existing fighter-specific tell as a fallback for custom data.
	if str(enemy_next_action.get("tell", "")).is_empty():
		enemy_next_action["tell"] = str(enemy.get("tell", "Studies your guard."))
	if arena_visuals and arena_visuals.has_method("show_enemy_telegraph"):
		var pose_key := str(enemy_next_action.get("name", ""))
		if str(enemy_next_action.get("kind", "")) == "guard":
			pose_key = "guard"
		elif str(enemy_next_action.get("kind", "")) == "recovery":
			pose_key = "recovery"
		elif str(enemy_next_action.get("kind", "")) == "taunt":
			pose_key = "taunt"
		arena_visuals.show_enemy_telegraph(pose_key)


	# The enemy response is resolved as one turn; show its resource changes as feedback.
func _enemy_turn() -> void:
	var player_stamina_before := float(player.get("stamina", 0.0))
	if enemy_drained > 0:
		enemy.stamina = maxf(0.0, enemy.stamina - 8.0)
		enemy_drained -= 1

	var action := enemy_next_action
	if action.is_empty():
		_prepare_enemy_telegraph()
		action = enemy_next_action

	var action_kind := str(action.get("kind", "attack"))
	if action_kind == "recovery":
		var rec_sta := 9.0 if bool(action.get("recover_interrupted", false)) else 18.0
		enemy.stamina = minf(enemy.max_stamina, enemy.stamina + rec_sta)
		_log("Opponent catches their breath (+%d STA)." % int(rec_sta))
		enemy_staggered = false
		return

	if action_kind == "taunt":
		if bool(action.get("taunt_broken", false)) or enemy_staggered:
			enemy_staggered = false
			_log("You shut his mouth mid-taunt!")
		else:
			enemy_taunt_buff = true
			enemy.stamina = minf(enemy.max_stamina, enemy.stamina + 10.0)
			_log("Opponent showboats to the crowd! Next swing hits +35% harder!")
		return

	if action_kind == "guard":
		enemy.stamina = minf(enemy.max_stamina, enemy.stamina + 6.0)
		if enemy_staggered:
			enemy_staggered = false
			_log("Their guard was cracked — too shaken to fire back!")
			return

	if enemy.stamina <= 0.0:
		enemy.stamina = minf(
			enemy.max_stamina,
			enemy.stamina + 12.0
		)
		player_counter_window = true
		_log("Opponent is gassed and struggles to recover — Counter Window open!")
		player.stamina = minf(player.max_stamina, player.stamina + 4.0)
		_show_floating_number(4.0, true, false, true)
		enemy_staggered = false
		return

	var enemy_accuracy := float(action.get("accuracy", enemy.accuracy))
	if enemy_blinded > 0:
		enemy_accuracy -= 15.0
		enemy_blinded -= 1
	if enemy_staggered:
		enemy_accuracy -= 15.0

	var archetype_damage_bonus := 1.0
	if str(enemy.get("trick", "")) == "aggressive" and str(action.get("name", "")) == "Heavy Right":
		archetype_damage_bonus = 1.12
	if str(current_bout_modifier.get("id", "")) == "short_fuse" and float(action.get("damage", 1.0)) >= 1.1:
		archetype_damage_bonus *= 1.18
	if enemy_taunt_buff:
		archetype_damage_bonus *= 1.35
		enemy_taunt_buff = false
	if enemy_staggered:
		archetype_damage_bonus *= 0.65
		enemy_staggered = false

	var enemy_damage := maxf(
		0.0,
		float(enemy.damage) * float(action.get("damage", 1.0)) * archetype_damage_bonus
		+ rng.randf_range(-2.0, 2.0)
	)

	enemy.stamina = maxf(
		0.0,
		enemy.stamina - float(action.get("cost", 10.0))
	)

	if arena_visuals and arena_visuals.has_method("enemy_attack"):
		arena_visuals.enemy_attack(str(action.get("name", "")))
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("whoosh_slip", -6.0)

	var dodged := player_slipping or (
		rng.randf() * 100.0 < _speed_chance(player.speed)
	)

	if dodged:
		player_counter_window = true
		_grant_adrenaline(24.0)
		_log("DODGED! " + str(action.get("name", "Their attack")) + " misses cleanly — Counter Window open!")
		if has_perk("greasy_gloves"):
			enemy.health = maxf(0.0, enemy.health - 6.0)
			_show_floating_number(6.0, false, true)
			_log("Greasy Gloves snap a free 6 DMG counter-jab!")
			if enemy.health <= 0.0:
				_win_fight()
				return
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("foot_shuffle", -5.0)
		var wind_recovery := minf(float(passive.get("wind", 0.0)), player.max_stamina - player.stamina)
		player.stamina = minf(player.max_stamina, player.stamina + wind_recovery)
		if wind_recovery > 0.0:
			_show_floating_number(wind_recovery, true, false, true)
		return

	if rng.randf() * 100.0 > enemy_accuracy:
		player_counter_window = true
		_log("Opponent's %s whiffs wide — Counter Window open!" % str(action.get("name", "attack")))
		return

	var eff_def := float(player.defence) + (5.0 if (has_perk("iron_chin") and float(player.health) <= float(player.max_health) * 0.35) else 0.0)
	var damage := enemy_damage * (
		1.0 - minf(65.0, eff_def) / 100.0
	)

	if player_blocking:
		damage *= (0.15 if has_perk("rope_a_dope") else 0.32)
		if has_perk("rope_a_dope"):
			enemy.health = maxf(0.0, enemy.health - 5.0)
			_show_floating_number(5.0, false, true)
			if enemy.health <= 0.0:
				_win_fight()
				return
	else:
		combo_streak = 0
		_grant_adrenaline(12.0)

	# Bleeder inflicts lingering cut damage unless blocked or dodged
	if str(enemy.get("trick", "")) == "bleeder" and not player_blocking:
		player_bleeding = 2
		_log("A sharp slice opens a cut! (-4 HP per turn)")
	if player_bleeding > 0:
		player_bleeding -= 1
		player.health = maxf(0.0, player.health - 4.0)
		_show_floating_number(4.0, false, false)

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
	_show_floating_number(damage, false, false)
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("block_thud" if player_blocking else "player_hit", -3.5)
		if not player_blocking and damage >= 14.0:
			audio_engine.play_sfx("crowd_gasp", -5.5)
		if float(player.stamina) < 15.0:
			audio_engine.play_sfx("heavy_breath", -6.0)
	if not player_blocking:
		_trigger_impact_flash(Color(0.85, 0.14, 0.14, 0.18))
	if screen_shake and arena_visuals and arena_visuals.has_method("impact_shake"):
		arena_visuals.impact_shake()

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

	var stamina_change := float(player.stamina) - player_stamina_before
	if absf(stamina_change) >= 1.0:
		_show_floating_number(absf(stamina_change), true, false, stamina_change > 0.0)

	if player.health <= 0.0:
		if not revive_used and inventory.has("salts"):
			inventory.erase("salts")
			revive_used = true
			player.health = 30.0
			_log("SMELLING SALTS! You drag yourself back to your feet.")
		else:
			_end_run(false, "You were knocked out.")



func _check_round() -> void:
	fight_turns_total += 1
	turn_no += 1

	if turn_no > 6:
		round_no += 1
		turn_no = 1
		round_first_hit_available = true

		player.stamina = minf(
			player.max_stamina,
			player.stamina + 14.0
		)
		if has_perk("second_heart"):
			player.health = minf(player.max_health, player.health + 8.0)

		enemy.stamina = minf(
			enemy.max_stamina,
			enemy.stamina + 10.0
		)

		_log("BELL! Corner break. You recover 14 stamina." + (" (+8 HP Second Heart)" if has_perk("second_heart") else ""))
		if is_instance_valid(audio_engine):
			audio_engine.play_sfx("bell_end", -4.0, 0.01)

		if round_no > 3:
			if player.health >= enemy.health:
				_win_fight()
			else:
				_end_run(false, "The judges give it to your opponent.")
		else:
			round_transition_open = true
			animate_round_transition = true
			combat_banner_title = "END OF ROUND %02d" % (round_no - 1)
			combat_banner_sub = "+14 stamina recovered in your corner"
			animate_combat_banner = true

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
	run_knockouts += 1
	var bout_pay := 30 + fight_index * 8
	var bonus_msg := ""
	var bounty_tag := _current_bout_bounty()
	if fight_turns_total <= 7:
		bout_pay += 15
		bonus_msg += " +$15 Fast KO"
	if bounty_tag == "cash":
		bout_pay += 35
		bonus_msg += " +$35 Purse"
	elif bounty_tag == "recovery":
		player.health = minf(player.max_health, player.health + 22.0)
		bonus_msg += " +22 HP Recovery"
	elif bounty_tag == "skill_manual" and not owned_moves.is_empty():
		var m_pick := str(owned_moves[rng.randi_range(0, owned_moves.size() - 1)])
		move_levels[m_pick] = mini(3, _move_level(m_pick) + 1)
		bonus_msg += " +1 Move Lv"
	if has_perk("belt_hunter"):
		bout_pay += 22
		bonus_msg += " +$22 Hunter"
	if contract_accepted:
		var c := _contract_for_fight(fight_index)
		var cid := str(c.get("id", ""))
		var c_won := false
		match cid:
			"speed_ko": c_won = fight_turns_total <= 8
			"no_block": c_won = not fight_used_block
			"showstopper": c_won = fight_big_hits >= 2
			"untouched": c_won = float(player.health) >= float(player.max_health) * 0.55
		if c_won:
			var cb := int(c.get("bonus", 50))
			bout_pay += cb
			bonus_msg += " +$%d Contract!" % cb
		contract_accepted = false
	if str(current_bout_modifier.get("id", "")) == "high_roller":
		bout_pay = roundi(float(bout_pay) * 1.5)
		bonus_msg += " ×1.5 High Roller"
	cash += bout_pay
	shop_bought_flags.clear()
	shop_reroll_count = 0
	hub_event_done = false

	_log("KNOCKOUT! Won $%d Pit Cash%s." % [bout_pay, bonus_msg])

	if fight_index == FIGHT_COUNT - 1:
		var def_lore := TLRStory.get_fighter_lore(str(enemy.get("id", "")))
		var def_txt := str(def_lore.get("defeat_line", ""))
		if not def_txt.is_empty():
			_log("%s: “%s”" % [str(enemy.get("name", "Champion")), def_txt])
		if bool(settings.get("story_cutscenes", true)) and not story_seen_ids.has("epilogue") and DisplayServer.get_name() != "headless":
			story_seen_ids.append("epilogue")
			_play_story_cutscene("epilogue", _end_run.bind(true, "You became the underground champion."))
		else:
			_end_run(true, "You became the underground champion.")
		return

	if is_instance_valid(audio_engine):
		audio_engine.set_ambience("menu")
		audio_engine.play_sfx("win_fight", -2.5, 0.01)
		audio_engine.play_sfx("crowd_cheer", -3.0)

	_show_rewards()


func _weighted_random_item(min_rarity: String = "common") -> Dictionary:
	var rank := {"common": 0, "uncommon": 1, "rare": 2, "contraband": 3}
	var min_rank := int(rank.get(min_rarity, 0))
	var weighted: Array[Dictionary] = []
	var hunter_bonus := 1.8 if has_perk("belt_hunter") else 1.0
	for item_variant in item_templates:
		var candidate: Dictionary = item_variant
		var cid := str(candidate.get("id", ""))
		if cid == "salts" and (inventory.has("salts") or revive_used):
			continue
		var rar := str(candidate.get("rarity", "common")).to_lower()
		var r_rank := int(rank.get(rar, 0))
		if r_rank < min_rank:
			continue
		var copies := 4
		match rar:
			"uncommon": copies = 3 + mini(2, fight_index / 2)
			"rare": copies = roundi((1.0 + float(fight_index) * 0.45) * hunter_bonus)
			"contraband": copies = roundi((0.5 if fight_index < 2 else (1.0 + float(fight_index - 1) * 0.35)) * hunter_bonus)
		for _c in range(maxi(1, copies)):
			weighted.append(candidate)
	if weighted.is_empty():
		return item_templates[0] if not item_templates.is_empty() else {}
	return weighted[rng.randi_range(0, weighted.size() - 1)]


func _show_rewards() -> void:
	game_state = "reward"
	_disable_realtime_combat()
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()

	var bounty_tag := _current_bout_bounty()
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

	var unowned_pool := pool.filter(
		func(move):
			return not owned_moves.has(str(move.get("id", "")))
	)
	if not pool.is_empty():
		var m_src := unowned_pool if (has_move_space and not unowned_pool.is_empty()) else pool
		options.append({
			"type": "move",
			"data": m_src[rng.randi_range(0, m_src.size() - 1)]
		})

	# Build distinct reward categories: Move/Upgrade, Fighting Trait, Rarity-weighted Item, or Stat
	var unowned_perks: Array[Dictionary] = []
	for p in PERK_CATALOG:
		if not owned_perks.has(str(p.get("id", ""))):
			unowned_perks.append(p.duplicate(true))

	var force_trait := (bounty_tag == "trait_drop")
	if owned_perks.size() < PERK_MAX and not unowned_perks.is_empty() and (force_trait or fight_index % 2 == 0 or not has_move_space):
		options.append({
			"type": "perk",
			"data": unowned_perks[rng.randi_range(0, unowned_perks.size() - 1)]
		})

	var force_rare_item := (bounty_tag == "rare_item")
	if (
		options.size() < 3
		and inventory.size() < 3
		and (force_rare_item or rng.randf() < 0.72)
		and not item_templates.is_empty()
	):
		var item: Dictionary = _weighted_random_item("rare" if force_rare_item else "common")
		if not item.is_empty():
			options.append({"type": "item", "data": item})

	if options.size() < 3 and owned_perks.size() < PERK_MAX and not unowned_perks.is_empty():
		var already_perk := false
		for o in options:
			if str(o.get("type", "")) == "perk":
				already_perk = true
				break
		if not already_perk and rng.randf() < 0.65:
			options.append({
				"type": "perk",
				"data": unowned_perks[rng.randi_range(0, unowned_perks.size() - 1)]
			})

	var used_stats: Array[String] = []
	while options.size() < 3:
		var upg := _random_upgrade(used_stats)
		used_stats.append(str(upg.get("name", "")))
		options.append({
			"type": "stat",
			"data": upg
		})

	options.shuffle()
	reward_options = options
	selected_reward_index = -1
	TLRScreens.build_rewards(self, screen_canvas, reward_options)


func _reroll_rewards() -> void:
	if cash < 20 or game_state != "reward":
		return
	cash -= 20
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_confirm", -4.0)
	_show_rewards()


func _select_reward_option(idx: int) -> void:
	if idx < 0 or idx >= reward_options.size():
		return
	selected_reward_index = idx
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_rewards(self, screen_canvas, reward_options)


func _confirm_selected_reward() -> void:
	if selected_reward_index < 0 or selected_reward_index >= reward_options.size():
		return
	var opt: Dictionary = reward_options[selected_reward_index]
	match str(opt.get("type", "")):
		"move":
			_choose_move(str(opt.data.get("id", "")))
		"item":
			_choose_item(str(opt.data.get("id", "")))
		"perk":
			_choose_perk(str(opt.data.get("id", "")))
		_:
			_choose_upgrade(opt.data)



func _random_upgrade(exclude_names: Array[String] = []) -> Dictionary:
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
	if int(passive.get("slots", 0)) < 2:
		pool.append({
			"name": "Open Stance",
			"description": "+1 Move Slot (max 6) and +6 max stamina.",
			"stat": "slots",
			"value": 1
		})

	var filtered := pool.filter(func(u): return not exclude_names.has(str(u.get("name", ""))))
	var src := filtered if not filtered.is_empty() else pool
	return src[rng.randi_range(0, src.size() - 1)].duplicate(true)


func _choose_move(id: String) -> void:
	var move := _get_move(id)
	var m_name := str(move.get("name", id))
	var detail := ""
	var summary := ""
	if owned_moves.has(id):
		var new_lv := mini(3, _move_level(id) + 1)
		move_levels[id] = new_lv
		player.damage += 1.0
		_log("%s upgraded to Lv.%d! (+22%% move damage, -1 STA, +1 DMG)" % [m_name, new_lv])
		detail = "%s Lv.%d unlocked: +22%% move power, -1 STA cost, and +1 fighter damage." % [m_name, new_lv]
		summary = "LOADOUT / %s UPGRADED TO LV.%d (BASE DMG %d)" % [m_name.to_upper(), new_lv, int(player.damage)]
	else:
		if owned_moves.size() >= 4 + int(passive.get("slots", 0)):
			_show_rewards()
			return

		owned_moves.append(id)
		move_levels[id] = 1
		_log("New move unlocked: " + m_name)
		detail = _move_reward_details(move)
		summary = "LOADOUT / %s ADDED TO YOUR MOVES" % m_name.to_upper()

	_after_reward(m_name, detail, summary)


func _choose_perk(perk_id: String) -> void:
	var p := _get_perk_data(perk_id)
	if p.is_empty():
		return
	if not owned_perks.has(perk_id) and owned_perks.size() < PERK_MAX:
		owned_perks.append(perk_id)
		if perk_id == "glass_knuckles":
			player.max_health = maxf(40.0, float(player.max_health) - 15.0)
			player.health = minf(float(player.health), float(player.max_health))
		elif perk_id == "greasy_gloves":
			player.speed = minf(60.0, float(player.speed) + 8.0)
	var p_name := str(p.get("name", perk_id))
	_log("Trait unlocked: " + p_name + "!")
	_after_reward(p_name, str(p.get("desc", "")), "CORNER TRAITS (%d / %d): %s" % [owned_perks.size(), PERK_MAX, ", ".join(owned_perks).to_upper()])


func _choose_item(id: String) -> void:
	if inventory.size() >= 3:
		return

	inventory.append(id)
	var i_name := _get_item_name(id)
	_log("Added to your corner bag: " + i_name + ".")
	var idata := _get_item_data(id)
	_after_reward(i_name, str(idata.get("description", "")), "CORNER BAG / %d OF 3 SLOTS OCCUPIED" % inventory.size())


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

		"slots":
			passive["slots"] = mini(2, int(passive.get("slots", 0)) + int(upgrade.value))
			player.max_stamina += 6.0
			player.stamina = minf(player.max_stamina, player.stamina + 6.0)

		"heal":
			player.health = minf(
				player.max_health,
				player.health + float(upgrade.value)
			)

	var move_names: Array[String] = []
	for m_id in owned_moves:
		move_names.append(str(_get_move(str(m_id)).get("name", m_id)).to_upper())
	var item_names: Array[String] = []
	for i_id in inventory:
		item_names.append(str(_get_item_name(str(i_id))).to_upper())
	var bag_str := ", ".join(item_names) if not item_names.is_empty() else "EMPTY"
	_after_reward(str(upgrade.get("name", "Upgrade")), str(upgrade.get("description", "")), "YOUR BUILD / MOVES: %s  •  BAG: %s\nRESULTING STATS: HP %d/%d  •  STA %d/%d  •  DMG %d  •  DEF %d" % [", ".join(move_names), bag_str, int(player.health), int(player.max_health), int(player.stamina), int(player.max_stamina), int(player.damage), int(player.defence)])


func _after_reward(headline: String = "", detail: String = "", summary: String = "") -> void:
	fight_index += 1

	player.health = minf(
		player.max_health,
		player.health + 10.0
	)

	player.stamina = minf(
		player.max_stamina,
		player.stamina + 20.0
	)
	_generate_shop_stock(true)
	_roll_hub_event()

	_save_run()
	if headline.is_empty():
		_show_bracket()
	else:
		game_state = "reward_confirmed"
		animate_screen_enter = true
		_clear_ui()
		TLRScreens.build_reward_confirmed(self, screen_canvas, headline, detail, summary)


func _opponent_template_index(index: int) -> int:
	if index >= 0 and index < bout_branches.size() and int(bout_branches[index]) == 1 and index < alt_roster.size():
		return int(alt_roster[index])
	if index >= 0 and index < run_roster.size():
		return int(run_roster[index])
	if index < 0 or index >= FIGHT_ROSTER.size():
		return -1
	return int(FIGHT_ROSTER[index])


func _select_bout_branch(branch: int) -> void:
	if fight_index >= 0 and fight_index < bout_branches.size():
		bout_branches[fight_index] = clampi(branch, 0, 1)
	var b_tag := _current_bout_bounty()
	hub_notice = "CHALLENGER LOCKED: %s  (%s)" % [_next_opponent_name().to_upper(), _bounty_label(b_tag)]
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_hub(self, screen_canvas)


func _toggle_hub_contract() -> void:
	contract_accepted = not contract_accepted
	var c := _contract_for_fight(fight_index)
	hub_notice = "CONTRACT ACCEPTED: %s" % str(c.get("name", "")) if contract_accepted else "Side contract declined."
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_hub(self, screen_canvas)


func _generate_shop_stock(reset_bought: bool = true) -> void:
	if reset_bought:
		shop_bought_flags.clear()
	var items_stock: Array = []
	var used_ids: Array[String] = []
	for slot_i in range(3):
		var min_rar := "uncommon" if slot_i == 2 else ("rare" if (slot_i == 1 and fight_index >= 3) else "common")
		var cand: Dictionary = _weighted_random_item(min_rar)
		var guard := 0
		while used_ids.has(str(cand.get("id", ""))) and guard < 8:
			cand = _weighted_random_item(min_rar)
			guard += 1
		if not cand.is_empty():
			used_ids.append(str(cand.get("id", "")))
			items_stock.append({
				"id": str(cand.get("id", "ice")),
				"price": int(cand.get("price", 20)),
				"rarity": str(cand.get("rarity", "common")),
				"sold": false
			})

	var unowned_perks: Array[Dictionary] = []
	for p in PERK_CATALOG:
		if not owned_perks.has(str(p.get("id", ""))):
			unowned_perks.append(p)
	var perk_offer := {}
	if not unowned_perks.is_empty():
		var pk: Dictionary = unowned_perks[rng.randi_range(0, unowned_perks.size() - 1)]
		perk_offer = {"id": str(pk.get("id", "")), "price": int(pk.get("price", 42)), "rarity": str(pk.get("rarity", "common")), "sold": false}

	var move_offer := {}
	var max_slots := 4 + int(passive.get("slots", 0))
	var cand_moves := moves.filter(func(mv): return not owned_moves.has(str(mv.get("id", ""))))
	if owned_moves.size() < max_slots and not cand_moves.is_empty():
		var mv: Dictionary = cand_moves[rng.randi_range(0, cand_moves.size() - 1)]
		move_offer = {"id": str(mv.get("id", "")), "price": 42 + fight_index * 2, "is_upgrade": false, "sold": false}
	elif not owned_moves.is_empty():
		var upg_candidates: Array[String] = []
		for om in owned_moves:
			if _move_level(om) < 3:
				upg_candidates.append(om)
		var m_src := upg_candidates if not upg_candidates.is_empty() else owned_moves
		var m_id := str(m_src[rng.randi_range(0, m_src.size() - 1)])
		move_offer = {"id": m_id, "price": 38 + _move_level(m_id) * 10, "is_upgrade": true, "sold": false}

	shop_stock = {"items": items_stock, "perk": perk_offer, "move": move_offer}


func _open_shop() -> void:
	_disable_realtime_combat()
	if shop_stock.is_empty() or not shop_stock.has("items"):
		_generate_shop_stock(false)
	game_state = "shop"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_shop(self, screen_canvas)


func _reroll_shop() -> void:
	if cash < 15:
		return
	cash -= 15
	shop_reroll_count += 1
	_generate_shop_stock(false)
	hub_notice = "Shop stock refreshed (-$15)."
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_confirm", -4.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_shop(self, screen_canvas)


func _shop_buy_item(idx: int) -> void:
	var items_arr: Array = shop_stock.get("items", [])
	if idx < 0 or idx >= items_arr.size() or inventory.size() >= 3:
		return
	var entry: Dictionary = items_arr[idx]
	if bool(entry.get("sold", false)):
		return
	var cost := int(entry.get("price", 20))
	if cash < cost:
		return
	cash -= cost
	entry["sold"] = true
	items_arr[idx] = entry
	shop_stock["items"] = items_arr
	var item_id := str(entry.get("id", "ice"))
	inventory.append(item_id)
	hub_notice = "Bought %s (-$%d)." % [_get_item_name(item_id), cost]
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("item_use", -4.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_shop(self, screen_canvas)


func _shop_sell_bag_item(inv_slot: int) -> void:
	if inv_slot < 0 or inv_slot >= inventory.size():
		return
	var item_id := str(inventory[inv_slot])
	var data := _get_item_data(item_id)
	var refund := maxi(8, int(roundf(float(data.get("price", 18)) * 0.5)))
	inventory.remove_at(inv_slot)
	cash += refund
	selected_hub_item_slot = clampi(selected_hub_item_slot, 0, maxi(0, inventory.size() - 1))
	hub_notice = "Sold %s (+$%d Pit Cash)." % [_get_item_name(item_id), refund]
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_confirm", -5.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_shop(self, screen_canvas)


func _shop_buy_perk() -> void:
	var pk: Dictionary = shop_stock.get("perk", {})
	if pk.is_empty() or bool(pk.get("sold", false)) or owned_perks.size() >= PERK_MAX:
		return
	var cost := int(pk.get("price", 42))
	if cash < cost:
		return
	var pid := str(pk.get("id", ""))
	if pid.is_empty() or owned_perks.has(pid):
		return
	cash -= cost
	pk["sold"] = true
	shop_stock["perk"] = pk
	owned_perks.append(pid)
	if pid == "glass_knuckles":
		player.max_health = maxf(40.0, float(player.max_health) - 15.0)
		player.health = minf(float(player.health), float(player.max_health))
	elif pid == "greasy_gloves":
		player.speed = minf(60.0, float(player.speed) + 8.0)
	var pdata := _get_perk_data(pid)
	hub_notice = "Bought Trait '%s' (-$%d)!" % [str(pdata.get("name", pid)), cost]
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_confirm", -3.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_shop(self, screen_canvas)


func _shop_buy_move() -> void:
	var mo: Dictionary = shop_stock.get("move", {})
	if mo.is_empty() or bool(mo.get("sold", false)):
		return
	var cost := int(mo.get("price", 42))
	if cash < cost:
		return
	var m_id := str(mo.get("id", ""))
	var is_upg := bool(mo.get("is_upgrade", false))
	var max_slots := 4 + int(passive.get("slots", 0))
	if not is_upg and owned_moves.size() >= max_slots:
		return
	cash -= cost
	mo["sold"] = true
	shop_stock["move"] = mo
	if owned_moves.has(m_id):
		var n_lv := mini(3, _move_level(m_id) + 1)
		move_levels[m_id] = n_lv
		player.damage += 1.0
		hub_notice = "Mastered %s -> Lv.%d (-$%d)!" % [str(_get_move(m_id).get("name", m_id)), n_lv, cost]
	else:
		owned_moves.append(m_id)
		move_levels[m_id] = 1
		hub_notice = "Learned %s (-$%d)!" % [str(_get_move(m_id).get("name", m_id)), cost]
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_confirm", -3.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_shop(self, screen_canvas)


func _shop_buy_service(svc: String) -> void:
	if bool(shop_bought_flags.get(svc, false)):
		return
	match svc:
		"heal":
			if cash < 20 or float(player.health) >= float(player.max_health):
				return
			cash -= 20
			shop_bought_flags["heal"] = true
			player.health = minf(float(player.max_health), float(player.health) + 25.0)
			hub_notice = "Cutman stitched you up (+25 HP)."
		"train":
			if cash < 35:
				return
			cash -= 35
			shop_bought_flags["train"] = true
			player.damage += 2.0
			hub_notice = "Heavy bag drill complete (+2 Base DMG)."
		"sta":
			if cash < 26:
				return
			cash -= 26
			shop_bought_flags["sta"] = true
			player.max_stamina += 12.0
			player.stamina = minf(float(player.max_stamina), float(player.stamina) + 12.0)
			hub_notice = "Roadwork complete (+12 Max STA)."
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("item_use", -4.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	if game_state == "shop":
		TLRScreens.build_shop(self, screen_canvas)
	else:
		TLRScreens.build_hub(self, screen_canvas)


func _hub_buy_heal() -> void:
	_shop_buy_service("heal")


func _hub_buy_train() -> void:
	_shop_buy_service("train")


func _hub_buy_perk() -> void:
	if cash < 45 or owned_perks.size() >= PERK_MAX or bool(shop_bought_flags.get("perk", false)):
		return
	var unowned: Array[Dictionary] = []
	for p in PERK_CATALOG:
		if not owned_perks.has(str(p.get("id", ""))):
			unowned.append(p)
	if unowned.is_empty():
		return
	var pick: Dictionary = unowned[rng.randi_range(0, unowned.size() - 1)]
	var pid := str(pick.get("id", ""))
	cash -= 45
	shop_bought_flags["perk"] = true
	owned_perks.append(pid)
	if pid == "glass_knuckles":
		player.max_health = maxf(40.0, float(player.max_health) - 15.0)
		player.health = minf(float(player.health), float(player.max_health))
	elif pid == "greasy_gloves":
		player.speed = minf(60.0, float(player.speed) + 8.0)
	hub_notice = "Paid $45: Learned Trait '%s'!" % str(pick.get("name", pid))
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_confirm", -3.0)
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_hub(self, screen_canvas)


func _roll_hub_event() -> void:
	var events: Array[Dictionary] = [
		{
			"id": "alley_cutman",
			"title": "BACK-ALLEY CUTMAN",
			"desc": "An unlicensed medic leans out of a doorway under flickering sodium light, holding smelling salts and mystery tape.",
			"choices": [
				{"label": "PATCH WOUNDS ($20)", "detail": "Pay $20 Cash -> Heal +28 HP.", "cost_cash": 20},
				{"label": "MYSTERY VIAL (-12 HP)", "detail": "Suffer -12 HP now -> Gain 1 Rare Item (requires >16 HP).", "min_hp": 17},
				{"label": "SWAP STORIES", "detail": "Save your skin and pocket +$12 in corner tips.", "cost_cash": 0}
			]
		},
		{
			"id": "contraband_drop",
			"title": "SMUGGLED RING LOCKER",
			"desc": "A promoter left the equipment locker cracked open beside the freight elevator.",
			"choices": [
				{"label": "CRACK CONTRABAND ($35)", "detail": "Pay $35 -> Guaranteed Contraband Item!", "cost_cash": 35},
				{"label": "DRILL TAPE ($22)", "detail": "Pay $22 -> Upgrade a random Move (+1 Level).", "cost_cash": 22},
				{"label": "GRAB WATER BOTTLES", "detail": "Free: Gain 1 Uncommon/Common Item + 10 HP.", "cost_cash": 0}
			]
		},
		{
			"id": "iron_spar",
			"title": "BASEMENT IRON SPAR",
			"desc": "Old bare-knuckle veterans are trading heavy leather behind closed doors. Step in for a round?",
			"choices": [
				{"label": "HARD ROUNDS (-16 HP)", "detail": "Take 16 HP wear -> Permanent +3 Base DMG & +1 DEF.", "min_hp": 22},
				{"label": "FOOTWORK COACH ($20)", "detail": "Pay $20 -> Permanent +5% Speed.", "cost_cash": 20},
				{"label": "STRETCH & BREATHE", "detail": "Safe: +14 Max STA immediately.", "cost_cash": 0}
			]
		},
		{
			"id": "shady_bookie",
			"title": "THE PIT BOOKIE",
			"desc": "A slick bookie waves a wad of singles. He wants you to bend the odds before the next bell.",
			"choices": [
				{"label": "TAKE THE ADVANCE (+$55)", "detail": "Instant +$55 Cash, but next opponent gets +6% Speed.", "cost_cash": 0},
				{"label": "BUY INSIDER TRAIT ($42)", "detail": "Pay $42 -> Gain 1 random Fighting Trait!", "cost_cash": 42},
				{"label": "DOUBLE DOWN BET ($25)", "detail": "Bet $25 -> 65% chance to win +$65 right now!", "cost_cash": 25}
			]
		}
	]
	current_hub_event = events[rng.randi_range(0, events.size() - 1)].duplicate(true)
	hub_event_done = false


func _open_hub_event() -> void:
	if hub_event_done:
		return
	if current_hub_event.is_empty():
		_roll_hub_event()
	game_state = "event"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_event(self, screen_canvas, current_hub_event)


func _resolve_hub_event(choice_idx: int) -> void:
	if hub_event_done or current_hub_event.is_empty():
		_show_bracket()
		return
	var eid := str(current_hub_event.get("id", ""))
	var ev_title := str(current_hub_event.get("title", "STREET ENCOUNTER"))
	var out_status := "win"
	var out_headline := "DEAL COMPLETE"
	var out_detail := ""
	var out_summary := ""
	match eid:
		"alley_cutman":
			match choice_idx:
				0:
					if cash < 20: return
					cash -= 20
					var before_h := float(player.health)
					player.health = minf(player.max_health, player.health + 28.0)
					var gained_h := int(roundf(float(player.health) - before_h))
					out_status = "trade"
					out_headline = "PATCHED UP (+%d HP)" % gained_h
					out_detail = "You paid the back-alley cutman $20 for quick stitches and ice."
					out_summary = "CASH: -$20 (Now $%d)  •  HEALTH: +%d HP (Now %d/%d)" % [cash, gained_h, int(player.health), int(player.max_health)]
				1:
					if float(player.health) <= 16.0: return
					player.health = maxf(1.0, player.health - 12.0)
					var rare_it := _weighted_random_item("rare")
					if inventory.size() < 3 and not rare_it.is_empty():
						var r_name := _get_item_name(str(rare_it.get("id", "")))
						inventory.append(str(rare_it.get("id", "adrenaline_shot")))
						out_status = "win"
						out_headline = "SECURED %s!" % r_name.to_upper()
						out_detail = "You endured a sting from the mystery vial and pocketed rare corner gear."
						out_summary = "HEALTH: -12 HP  •  ADDED ITEM: %s (%s)" % [r_name.to_upper(), str(rare_it.get("rarity", "rare")).to_upper()]
					else:
						cash += 35
						out_status = "trade"
						out_headline = "SOLD VIAL FOR +$35"
						out_detail = "Your Corner Bag was full, so you flipped the vial to another cornerman."
						out_summary = "HEALTH: -12 HP  •  CASH: +$35 (Now $%d)" % cash
				2:
					cash += 12
					out_status = "win"
					out_headline = "POCKETED +$12 IN TIPS"
					out_detail = "No risks taken. You kept healthy and left with a few extra bucks."
					out_summary = "CASH: +$12 (Now $%d)  •  HEALTH INTACT" % cash
		"contraband_drop":
			match choice_idx:
				0:
					if cash < 35: return
					cash -= 35
					var c_it := _weighted_random_item("contraband")
					var cid := str(c_it.get("id", "nitro_salts"))
					if inventory.size() < 3:
						var cn := _get_item_name(cid)
						inventory.append(cid)
						out_status = "win"
						out_headline = "CONTRABAND ACQUIRED: %s!" % cn.to_upper()
						out_detail = "You popped the smuggled locker and stashed Contraband gear."
						out_summary = "CASH: -$35 (Now $%d)  •  GAINED: %s" % [cash, cn.to_upper()]
					else:
						player.damage += 3.0
						out_status = "win"
						out_headline = "WEIGHTED WRAPS (+3 BASE DMG)!"
						out_detail = "Bag full — you laced dense brass wraps directly under your gloves."
						out_summary = "CASH: -$35  •  BASE DAMAGE: +3 (Now %d DMG)" % int(player.damage)
				1:
					if cash < 22: return
					cash -= 22
					if not owned_moves.is_empty():
						var mid := str(owned_moves[rng.randi_range(0, owned_moves.size() - 1)])
						move_levels[mid] = mini(3, _move_level(mid) + 1)
						var mv_n := str(_get_move(mid).get("name", mid)).to_upper()
						out_status = "win"
						out_headline = "%s MASTERED -> LV.%d!" % [mv_n, _move_level(mid)]
						out_detail = "Secret corner notes sharpen your technique power and efficiency."
						out_summary = "CASH: -$22  •  %s LV.%d (+22%% DMG, -1 STA)" % [mv_n, _move_level(mid)]
				2:
					var before_h2 := float(player.health)
					player.health = minf(player.max_health, player.health + 10.0)
					var gh2 := int(roundf(float(player.health) - before_h2))
					var unc := _weighted_random_item("common")
					if inventory.size() < 3 and not unc.is_empty():
						var un := _get_item_name(str(unc.get("id", "")))
						inventory.append(str(unc.get("id", "ice")))
						out_status = "win"
						out_headline = "FREE LOOT: %s!" % un.to_upper()
						out_detail = "Quietly grabbed supplies from the open crate with zero downside."
						out_summary = "HEALTH: +%d HP  •  ADDED ITEM: %s" % [gh2, un.to_upper()]
					else:
						out_status = "win"
						out_headline = "CORNER REFRESH (+%d HP)" % gh2
						out_detail = "Grabbed fresh cold water and recovered safely."
						out_summary = "HEALTH: +%d HP (Now %d/%d)" % [gh2, int(player.health), int(player.max_health)]
		"iron_spar":
			match choice_idx:
				0:
					if float(player.health) <= 21.0: return
					player.health = maxf(1.0, player.health - 16.0)
					player.damage += 3.0
					player.defence += 1.0
					out_status = "trade"
					out_headline = "FORGED IN STEEL (+3 DMG / +1 DEF)"
					out_detail = "Bruising bare-knuckle rounds hardened both your fists and guard."
					out_summary = "HEALTH: -16 HP  •  DAMAGE +3 (%d)  •  DEFENCE +1 (%d)" % [int(player.damage), int(player.defence)]
				1:
					if cash < 20: return
					cash -= 20
					player.speed = minf(60.0, float(player.speed) + 5.0)
					out_status = "win"
					out_headline = "FOOTWORK SHARPENED (+5% SPD)"
					out_detail = "Clean pad drills paid off immediately."
					out_summary = "CASH: -$20  •  DODGE SPEED: %d%%" % int(_speed_chance(float(player.speed)))
				2:
					player.max_stamina += 14.0
					player.stamina = minf(player.max_stamina, player.stamina + 14.0)
					out_status = "win"
					out_headline = "LUNG CAPACITY (+14 MAX STA)"
					out_detail = "Deep conditioning leaves more gas for combos."
					out_summary = "MAX STAMINA: +14 (Now %d/%d STA)" % [int(player.stamina), int(player.max_stamina)]
		"shady_bookie":
			match choice_idx:
				0:
					cash += 55
					event_enemy_speed_buff += 6.0
					out_status = "trade"
					out_headline = "ADVANCE COLLECTED (+$55 CASH)"
					out_detail = "You pocketed the bookie's advance, though word got back to your next challenger."
					out_summary = "CASH: +$55 (Now $%d)  •  NEXT OPPONENT +6%% SPEED" % cash
				1:
					if cash < 42 or owned_perks.size() >= PERK_MAX: return
					var unowned: Array[Dictionary] = []
					for p in PERK_CATALOG:
						if not owned_perks.has(str(p.get("id", ""))):
							unowned.append(p)
					if unowned.is_empty(): return
					cash -= 42
					var pk: Dictionary = unowned[rng.randi_range(0, unowned.size() - 1)]
					var pid := str(pk.get("id", ""))
					owned_perks.append(pid)
					if pid == "glass_knuckles":
						player.max_health = maxf(40.0, float(player.max_health) - 15.0)
						player.health = minf(float(player.health), float(player.max_health))
					elif pid == "greasy_gloves":
						player.speed = minf(60.0, float(player.speed) + 8.0)
					var pk_n := str(pk.get("name", pid)).to_upper()
					out_status = "win"
					out_headline = "TRAIT UNLOCKED: %s!" % pk_n
					out_detail = str(pk.get("desc", ""))
					out_summary = "CASH: -$42  •  TRAITS: %d / %d" % [owned_perks.size(), PERK_MAX]
				2:
					if cash < 25: return
					cash -= 25
					if rng.randf() < 0.65:
						cash += 65
						out_status = "win"
						out_headline = "WAGER WON! (+$65 PAYOUT)"
						out_detail = "The bookie curses and counts out crisp bills (+40 net profit!)."
						out_summary = "STAKE: $25  •  PAYOUT: +$65  •  CASH NOW: $%d" % cash
					else:
						out_status = "fail"
						out_headline = "WAGER BUSTED! (-$25 LOST)"
						out_detail = "Bad beat — the house swept your chips off the crate."
						out_summary = "LOST: -$25 STAKE  •  CASH REMAINING: $%d" % cash
	hub_event_done = true
	hub_notice = ev_title + ": " + out_headline
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("ui_retry" if out_status == "fail" else "ui_confirm", -4.0)
	game_state = "event_result"
	animate_screen_enter = true
	_clear_ui()
	TLRScreens.build_event_result(self, screen_canvas, ev_title, out_headline, out_detail, out_summary, out_status)


func _next_opponent_name() -> String:
	if fight_index >= FIGHT_COUNT:
		return "THE CROWN"

	var roster_index := _opponent_template_index(fight_index)
	if roster_index < 0 or roster_index >= enemy_templates.size():
		return "UNKNOWN FIGHTER"

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
		"bleeder":
			return "Targets cuts to inflict Bleeding (-4 HP/turn). Guard clean or bring Vaseline."
		"berserker":
			return "Enrages below 50% HP (+25% power). Save Adrenaline to burst through Phase 2."
		"showboat":
			return "Taunts for +35% next-hit power. Land an attack to interrupt the showboat."
		"boss":
			return "The champion surges on turns 3 and 6. Keep stamina ready to defend those turns."
		_:
			return "Watch the shoulders closely before committing heavy stamina."


func _show_bracket() -> void:
	game_state = "hub"
	_disable_realtime_combat()
	selected_hub_item_slot = clampi(selected_hub_item_slot, 0, maxi(0, inventory.size() - 1))
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_hub(self, screen_canvas)


func _select_hub_item_slot(slot: int) -> void:
	if slot < 0 or slot >= inventory.size():
		return
	selected_hub_item_slot = slot
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_hub(self, screen_canvas)


func _use_hub_item_slot(slot: int) -> void:
	if slot < 0 or slot >= inventory.size():
		return
	var item_id := str(inventory[slot])
	if item_id not in ["ice", "sparring_tonics"]:
		return
	inventory.remove_at(slot)
	var before_hp := float(player.health)
	if item_id == "sparring_tonics":
		player.max_health += 12.0
		player.health = minf(player.max_health, player.health + 18.0)
	else:
		player.health = minf(player.max_health, player.health + 22.0)
	var gained := int(roundf(float(player.health) - before_hp))
	hub_notice = ("TONIC +12 MAX HP / +%d HP" % gained) if item_id == "sparring_tonics" else ("RECOVERED +%d HP / %d CAP" % [gained, int(player.max_health)])
	selected_hub_item_slot = clampi(selected_hub_item_slot, 0, maxi(0, inventory.size() - 1))
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_hub(self, screen_canvas)


func _use_heal_between() -> void:
	var idx := inventory.find("ice")
	if idx == -1:
		idx = inventory.find("sparring_tonics")
	if idx != -1:
		_use_hub_item_slot(idx)


# ---------------------------------------------------------
# ITEMS
# ---------------------------------------------------------

func _use_item(id: String) -> void:
	# Combat items can only be activated during an unpaused fight.
	if game_state != "combat" or combat_paused or round_transition_open:
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

		"cutman_kit":
			player_bleeding = 0
			player.health = minf(player.max_health, player.health + 16.0)
			player.stamina = minf(player.max_stamina, player.stamina + 12.0)

		"pepper_wrap":
			enemy.stamina = maxf(0.0, enemy.stamina - 10.0)
			player_counter_window = true
			enemy_taunt_buff = false

		"adrenaline_shot":
			adrenaline = 100.0
			player.stamina = minf(player.max_stamina, player.stamina + 12.0)

		"sparring_tonics":
			player.max_health += 12.0
			player.health = minf(player.max_health, player.health + 18.0)

		"brass_duster":
			if not bribe_ready and rng.randf() < (0.05 if str(current_bout_modifier.get("id", "")) == "back_alley" else 0.10):
				_log("The referee spots the brass insert! DISQUALIFIED.")
				_end_run(false, "Disqualified for wearing brass knuckles.")
				return
			bribe_ready = false
			brass_charges = 3

		"nitro_salts":
			player.stamina = player.max_stamina
			player.health = minf(player.max_health, player.health + 22.0)
			player_combo_ready = true

	var item_name := _get_item_name(id)
	var item_data := _get_item_data(id)
	var quick_use: bool = (id in ["cutman_kit", "adrenaline_shot", "nitro_salts"]) and not training_active
	combat_banner_title = ("QUICK ITEM / %s" if quick_use else "ITEM USED / %s") % item_name.to_upper()
	combat_banner_sub = str(item_data.get("description", "Item activated.")) + (" • Turn kept!" if quick_use else "")
	_log("Used " + item_name + ".")
	if is_instance_valid(audio_engine):
		audio_engine.play_sfx("item_use", -4.0)

	if quick_use and game_state == "combat":
		animate_combat_banner = true
		animate_phase_banner = true
		_show_combat()
		return

	if game_state == "combat":
		_enemy_turn()
		player_blocking = false
		player_slipping = false

		# Energy Drink's crash is charged after the opponent's response. Keep
		# this in the shared item path so using the drink always pays its cost.
		if energy_penalty_pending and game_state == "combat":
			player.stamina = maxf(0.0, player.stamina - 10.0)
			energy_penalty_pending = false
			_show_floating_number(10.0, true, false, false)
			_log("The energy drink crash costs 10 stamina.")

		if game_state == "combat":
			if training_active:
				player.health = maxf(25.0, float(player.health))
				training_retry_flag = false
				training_feedback = "Coach: Good! Using an item applies now and costs your turn — watch what follows."
				_prepare_enemy_telegraph()
				animate_combat_banner = true
				animate_phase_banner = true
				_show_combat()
				return
			_check_round()
			if game_state == "combat":
				_prepare_enemy_telegraph()
			animate_combat_banner = true
			animate_phase_banner = true
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
	if is_instance_valid(audio_engine):
		audio_engine.set_ambience("menu")
		if won:
			audio_engine.play_sfx("win_champion", -2.0, 0.01)
			audio_engine.play_sfx("crowd_cheer", -2.5)
		else:
			audio_engine.play_sfx("lose_ko", -2.0, 0.01)

	if won:
		respect += 100

	# Persist career progress before rendering the summary so the displayed
	# lifetime total and rank include this run's Respect award.
	_save_meta()

	var completed_slot_path := _slot_save_path(selected_slot)
	if FileAccess.file_exists(completed_slot_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(completed_slot_path))

	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_run_end(self, screen_canvas, won, reason)


# ---------------------------------------------------------
# SAVE / CONTINUE
# ---------------------------------------------------------

func _slot_save_path(slot: int) -> String:
	return "user://the_last_round_slot_%d.json" % [slot + 1]


func _slot_status(slot: int) -> String:
	var path := _slot_save_path(slot)
	if not FileAccess.file_exists(path):
		return "EMPTY"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "SAVE UNAVAILABLE"
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION:
		return "DAMAGED / INCOMPATIBLE"
	var fight := clampi(int(parsed.get("fight_index", 0)), 0, FIGHT_COUNT - 1)
	return "CHECKPOINT — FIGHT %d / %d" % [fight + 1, FIGHT_COUNT]


func _slot_info(slot: int) -> Dictionary:
	var path := _slot_save_path(slot)
	if not FileAccess.file_exists(path):
		return {"has_save": false, "fight_index": 0, "corrupt": false}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"has_save": false, "fight_index": 0, "corrupt": true}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION:
		return {"has_save": false, "fight_index": 0, "corrupt": true}
	var fight := clampi(int(parsed.get("fight_index", 0)), 0, FIGHT_COUNT - 1)
	return {"has_save": true, "fight_index": fight, "corrupt": false}


func _save_run() -> void:
	var save_path := _slot_save_path(selected_slot)
	var temp_path := "user://the_last_round_slot_%d.tmp" % [selected_slot + 1]
	var backup_path := "user://the_last_round_slot_%d.bak" % [selected_slot + 1]
	var data := {
		"version": SAVE_VERSION,
		"slot": selected_slot,
		"fight_index": fight_index,
		"player": player,
		"owned_moves": owned_moves,
		"move_levels": move_levels,
		"owned_perks": owned_perks,
		"run_roster": run_roster,
		"alt_roster": alt_roster,
		"bout_branches": bout_branches,
		"bout_bounties": bout_bounties,
		"player_style": player_style,
		"inventory": inventory,
		"respect": respect,
		"cash": cash,
		"shop_bought_flags": shop_bought_flags,
		"shop_stock": shop_stock,
		"shop_reroll_count": shop_reroll_count,
		"current_hub_event": current_hub_event,
		"hub_event_done": hub_event_done,
		"event_enemy_speed_buff": event_enemy_speed_buff,
		"contract_accepted": contract_accepted,
		"story_seen_ids": story_seen_ids,
		"run_highest_hit": run_highest_hit,
		"run_knockouts": run_knockouts,
		"seed": run_seed,
		"passive": passive,
		"revive_used": revive_used,
		"bribe_ready": bribe_ready,
		"heart_active": heart_active,
		"energy_penalty_pending": energy_penalty_pending,
		"next_fight_speed_bonus": next_fight_speed_bonus
	}

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not create temporary run save for slot %d." % [selected_slot + 1])
		hub_notice = "SAVE FAILED — could not create a checkpoint."
		if game_state == "hub":
			_show_bracket()
		return

	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	var save_absolute := ProjectSettings.globalize_path(save_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	var had_previous_save := FileAccess.file_exists(save_path)

	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)

	if had_previous_save:
		var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			push_error("Could not back up slot %d. Error: %d" % [selected_slot + 1, backup_error])
			DirAccess.remove_absolute(temp_absolute)
			hub_notice = "SAVE FAILED — your previous checkpoint was left untouched."
			if game_state == "hub":
				_show_bracket()
			return

	var rename_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if rename_error != OK:
		push_error("Could not replace slot %d save. Error: %d" % [selected_slot + 1, rename_error])
		DirAccess.remove_absolute(temp_absolute)
		var restore_error := OK
		if had_previous_save:
			restore_error = DirAccess.rename_absolute(backup_absolute, save_absolute)
		hub_notice = "SAVE FAILED — previous checkpoint restored." if restore_error == OK else "SAVE FAILED — checkpoint restoration needs attention."
	else:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_absolute)
		hub_notice = "SLOT %d SAVED — your corner is waiting." % [selected_slot + 1]

	if game_state == "hub":
		_show_bracket()


func _continue_run(slot: int = -1) -> void:
	if slot >= 0 and slot < SAVE_SLOT_COUNT:
		selected_slot = slot
	var save_path := _slot_save_path(selected_slot)
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		menu_notice = "NO VALID SAVE FOUND IN SLOT %d. Start a new run." % [selected_slot + 1]
		_show_main_menu()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_reject_run_save("The run save is damaged or unreadable.")
		return

	var data: Dictionary = parsed
	if int(data.get("version", -1)) != SAVE_VERSION or int(data.get("slot", -1)) != selected_slot:
		_reject_run_save("This run save uses an unsupported version or belongs to another slot.")
		return

	var saved_player = data.get("player", {})
	var saved_moves = data.get("owned_moves", [])
	var saved_inventory = data.get("inventory", [])
	var saved_passive = data.get("passive", {})
	var saved_fight := int(data.get("fight_index", -1))

	if (
		saved_fight < 0
		or saved_fight >= FIGHT_COUNT
		or not saved_player is Dictionary
		or saved_player.is_empty()
		or not saved_moves is Array
		or saved_moves.is_empty()
		or not saved_inventory is Array
		or not saved_passive is Dictionary
	):
		_reject_run_save("The run save is incomplete or has invalid data.")
		return

	for required_stat in ["health", "max_health", "stamina", "max_stamina", "damage", "speed", "defence"]:
		if not saved_player.has(required_stat) or not (saved_player[required_stat] is int or saved_player[required_stat] is float):
			_reject_run_save("The run save is missing valid fighter stats.")
			return

	if float(saved_player.health) <= 0.0 or float(saved_player.max_health) <= 0.0:
		_reject_run_save("The saved fighter state cannot be continued.")
		return

	for move_id in saved_moves:
		if _get_move(str(move_id)).is_empty():
			_reject_run_save("The run save contains an unknown move.")
			return

	for item_id in saved_inventory:
		if _get_item_data(str(item_id)).is_empty():
			_reject_run_save("The run save contains an unknown item.")
			return

	run_ended = false
	fight_index = saved_fight
	player = saved_player.duplicate(true)
	owned_moves.clear()
	for move_id in saved_moves:
		owned_moves.append(str(move_id))
	inventory = saved_inventory.duplicate()
	respect = maxi(0, int(data.get("respect", 0)))
	run_seed = int(data.get("seed", 0))
	move_levels = data.get("move_levels", {}).duplicate(true)
	owned_perks.clear()
	for pk in data.get("owned_perks", []):
		owned_perks.append(str(pk))
	var saved_roster = data.get("run_roster", [])
	if saved_roster is Array and saved_roster.size() == FIGHT_COUNT:
		run_roster.clear()
		for ri in saved_roster:
			run_roster.append(int(ri))
	else:
		run_roster = _generate_run_roster(run_seed)
	var saved_alt = data.get("alt_roster", [])
	if saved_alt is Array and saved_alt.size() == FIGHT_COUNT:
		alt_roster.clear()
		for ai in saved_alt:
			alt_roster.append(int(ai))
	var saved_branches = data.get("bout_branches", [])
	if saved_branches is Array and saved_branches.size() == FIGHT_COUNT:
		bout_branches.clear()
		for bi in saved_branches:
			bout_branches.append(int(bi))
	else:
		bout_branches = [0, 0, 0, 0, 0, 0, 0, 0]
	var saved_bounties = data.get("bout_bounties", [])
	if saved_bounties is Array and saved_bounties.size() == FIGHT_COUNT:
		bout_bounties = saved_bounties.duplicate(true)
	player_style = str(data.get("player_style", "slugger"))
	cash = maxi(0, int(data.get("cash", 30)))
	shop_bought_flags = data.get("shop_bought_flags", {}).duplicate(true)
	shop_stock = data.get("shop_stock", {}).duplicate(true)
	shop_reroll_count = int(data.get("shop_reroll_count", 0))
	current_hub_event = data.get("current_hub_event", {}).duplicate(true)
	hub_event_done = bool(data.get("hub_event_done", false))
	event_enemy_speed_buff = float(data.get("event_enemy_speed_buff", 0.0))
	contract_accepted = bool(data.get("contract_accepted", false))
	story_seen_ids.clear()
	for sid in data.get("story_seen_ids", []):
		story_seen_ids.append(str(sid))
	run_highest_hit = int(data.get("run_highest_hit", 0))
	run_knockouts = int(data.get("run_knockouts", 0))
	passive = saved_passive.duplicate(true)
	revive_used = bool(data.get("revive_used", false))
	bribe_ready = bool(data.get("bribe_ready", false))
	heart_active = bool(data.get("heart_active", false))
	energy_penalty_pending = bool(data.get("energy_penalty_pending", false))
	next_fight_speed_bonus = float(data.get("next_fight_speed_bonus", 0.0))

	rng.seed = run_seed + fight_index * 991
	menu_notice = "SLOT %d CONTINUED — back to the circuit." % [selected_slot + 1]
	_show_bracket()


func _reject_run_save(reason: String) -> void:
	push_warning(reason)
	var save_path := _slot_save_path(selected_slot)
	var corrupt_path := "user://the_last_round_slot_%d.corrupt.json" % [selected_slot + 1]
	var save_absolute := ProjectSettings.globalize_path(save_path)
	var corrupt_absolute := ProjectSettings.globalize_path(corrupt_path)
	var quarantine_error := OK
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(corrupt_path):
			DirAccess.remove_absolute(corrupt_absolute)
		quarantine_error = DirAccess.rename_absolute(save_absolute, corrupt_absolute)

	if quarantine_error == OK:
		menu_notice = "SLOT %d UNAVAILABLE: %s Damaged save preserved for recovery." % [selected_slot + 1, reason]
	else:
		menu_notice = "SLOT %d UNAVAILABLE: %s The original file was left in place." % [selected_slot + 1, reason]
		push_error("Could not quarantine invalid slot save. Error: %d" % quarantine_error)
	_show_main_menu()


func _remove_legacy_save_files() -> void:
	var legacy_paths := [
		"user://underdog_save.json",
		"user://underdog_save.tmp",
		"user://underdog_save.bak",
		"user://underdog_save.corrupt.json",
		"user://underdog_meta.json"
	]
	for legacy_path in legacy_paths:
		if FileAccess.file_exists(legacy_path):
			var absolute_path := ProjectSettings.globalize_path(legacy_path)
			var remove_error := DirAccess.remove_absolute(absolute_path)
			if remove_error != OK:
				push_warning("Could not remove legacy save file: " + legacy_path)


func _has_any_slot_save() -> bool:
	for s in range(SAVE_SLOT_COUNT):
		if FileAccess.file_exists(_slot_save_path(s)):
			return true
	return false


func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		lifetime_respect = 0
		tutorial_completed = _has_any_slot_save()
		return

	var file := FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		lifetime_respect = 0
		tutorial_completed = _has_any_slot_save()
		return

	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		lifetime_respect = maxi(0, int(data.get("respect_total", 0)))
		if data.has("tutorial_completed"):
			tutorial_completed = bool(data.get("tutorial_completed", false))
		else:
			tutorial_completed = (lifetime_respect > 0 or _has_any_slot_save())
	else:
		lifetime_respect = 0
		tutorial_completed = _has_any_slot_save()


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


func _save_meta_flags() -> void:
	var data := {
		"respect_total": lifetime_respect,
		"tutorial_completed": tutorial_completed
	}
	var file := FileAccess.open(META_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func _save_meta() -> void:
	lifetime_respect += respect
	tutorial_completed = true
	_save_meta_flags()


# ---------------------------------------------------------
# CODEX AND SETTINGS
# ---------------------------------------------------------

func _show_tutorial() -> void:
	_start_training(false)


func _start_training(is_first_run: bool = false) -> void:
	_disable_realtime_combat()
	training_active = true
	training_retry_flag = false
	pending_first_run_tutorial = is_first_run
	tutorial_completed = true
	_save_meta_flags()
	training_turn = 0
	training_feedback = "First time down the stairs? Read my shoulders before Bout 1 — or press SKIP TO RUN anytime." if is_first_run else "Eyes on my rear shoulder. Read the pose, then answer using slots 1–8."
	animate_screen_enter = true
	combat_paused = false
	combat_drawer_open = false
	combat_review_open = false
	round_transition_open = false
	combat_banner_title = ""
	combat_banner_sub = ""
	game_state = "combat"
	run_ended = false
	fight_index = 0
	round_no = 1
	turn_no = 1
	adrenaline = 0.0
	player_momentum = false
	move_levels.clear()
	owned_perks.clear()
	owned_moves = ["jab", "block", "slip", "counter", "clinch", "rest", "feint", "body_shot"]
	inventory = ["energy", "ice", "salts"]
	passive = {"damage": 0.0, "health": 0.0, "stamina": 0.0, "defence": 0.0, "speed": 0.0, "slots": 0, "wind": 0}
	player = {
		"health": 100.0,
		"max_health": 100.0,
		"stamina": 100.0,
		"max_stamina": 100.0,
		"damage": 10.0,
		"speed": 0.0,
		"defence": 5.0,
		"heart": false,
		"knockdowns": 0
	}
	enemy = {
		"name": "COACH",
		"archetype": "Training Partner",
		"health": 200.0,
		"max_health": 200.0,
		"stamina": 100.0,
		"max_stamina": 100.0,
		"damage": 7.0,
		"speed": 0.0,
		"defence": 0.0,
		"tell": "Studies your guard.",
		"trick": "training",
		"accuracy": 100.0
	}
	hud_player_hp = -1.0
	hud_player_stamina = -1.0
	hud_enemy_hp = -1.0
	hud_enemy_stamina = -1.0
	player_blocking = false
	player_slipping = false
	enemy_blinded = 0
	enemy_drained = 0
	loaded_bonus = 0
	loaded_tape_risk = false
	energy_penalty_pending = false
	revive_used = false
	bribe_ready = false
	heart_active = false
	next_fight_speed_bonus = 0.0
	player_last_move_id = ""
	log_lines.clear()
	if is_instance_valid(opponent_mat):
		opponent_mat.albedo_color = Color(0.28, 0.38, 0.40)
	_prepare_enemy_telegraph()
	if is_instance_valid(audio_engine):
		audio_engine.set_ambience("combat")
		audio_engine.play_sfx("bell_round", -5.0, 0.02)
	_show_combat()


func _training_recommended_moves() -> Array:
	var acceptable_by_exchange: Array = [
		["block", "slip", "counter"],
		["block", "slip", "clinch"],
		["jab", "body_shot", "block", "slip"],
		["block", "slip", "counter"],
		["rest"],
		["block", "slip", "clinch"],
		["feint", "body_shot"],
		["jab", "body_shot", "feint"]
	]
	return acceptable_by_exchange[mini(training_turn, acceptable_by_exchange.size() - 1)]


func _training_lesson_prompt() -> String:
	var prompts := [
		"Eyes on the rear shoulder. Block [2], Slip [3], or Counter [4] the heavy right.",
		"Watch the dip toward your ribs. Block [2], Slip [3], or Clinch [5].",
		"Quick jab incoming! Answer with Jab [1], Body Shot [8], Block [2], or Slip [3].",
		"Same loaded right again — read the shoulder and punish or defend cleanly.",
		"Safe breathing window! Use Rest [6] now to refill stamina without risk.",
		"Two-punch combination coming. Shut down the rush with Block, Slip, or Clinch.",
		"Tight High Guard blocks normal punches! Crack it with Feint [7] or Body Shot [8] for Momentum.",
		"Showboat leaves him open (+35% next hit)! Interrupt with Jab, Body Shot, or Feint."
	]
	return prompts[mini(training_turn, prompts.size() - 1)]


func _training_move_is_acceptable(id: String) -> bool:
	return _training_recommended_moves().has(id)


func _training_retry_feedback(id: String) -> String:
	var incoming := str(enemy_next_action.get("name", ""))
	var move := _get_move(id)
	var move_name := str(move.get("name", id))
	match incoming:
		"Heavy Right":
			return "Not that one. The loaded right is dangerous. Choose Block, Slip or Counter. This exchange will repeat."
		"Body Shot":
			return "Not that one. The level change signals a body attack. Choose Block, Slip or Clinch. This exchange will repeat."
		"Quick Jab":
			return "Try an active response here: Jab, Body Shot, Block or Slip. This exchange will repeat."
		"Reset":
			return "This is your safe breathing window. Choose Rest to recover stamina. This exchange will repeat."
		"Combination":
			return "The combination is coming. Choose Block, Slip or Clinch to handle the pressure. This exchange will repeat."
		"High Guard":
			return "Punches bounce off High Guard! Use Feint or Body Shot to crack it open and earn Momentum."
		"Showboat Taunt":
			return "He's wide open and about to buff +35%! Throw Jab, Body Shot, or Feint with 100% Lights Out!"
	return "%s is not the lesson for this exchange. Choose a suggested response and try again." % move_name


func _training_feedback_for_move(id: String) -> String:
	var incoming := str(enemy_next_action.get("name", ""))
	if incoming == "Heavy Right":
		if id in ["block", "slip"]:
			return "Coach: Good. You respected the loaded right and defended instead of trading."
		if id == "counter":
			return "Coach: Excellent read. You saw the right hand coming and timed the counter."
		if id == "rest":
			return "Coach: Rest refills stamina, but leaves you open. Save it for a safer window."
		return "Coach: You attacked into the big tell. A block cuts damage; a slip avoids it."
	if incoming == "Body Shot":
		if id in ["block", "slip", "clinch"]:
			return "Coach: Nice. You shut down the body attack. A clinch can break pressure and recover gas."
		if id == "rest":
			return "Coach: Rest is useful, but you left your body open during my level change."
		return "Coach: Watch the level change. Body shots punish an open guard."
	if incoming == "Quick Jab":
		if id == "rest":
			return "Coach: Rest gets stamina back, but you leave yourself open. Pick the moment."
		return "Coach: Good exchange. Keep an eye on stamina; every action has a cost."
	if incoming == "Reset":
		return "Coach: That's your breathing window. Rest now if your gas tank needs it."
	if incoming == "Combination":
		if id in ["block", "slip", "clinch"]:
			return "Coach: Good defence. Block, Slip or Clinch can interrupt a combination and stop you getting overwhelmed."
		return "Coach: Don't admire your work after landing a punch. Be ready for the follow-up."
	if incoming == "High Guard":
		return "Coach: CRACKED IT! Feint & Guard Breaks earn MOMENTUM — a free follow-up punch before the opponent swings!"
	if incoming == "Showboat Taunt":
		return "Coach: LIGHTS OUT! Interrupting taunts stops their +35% buff and unleashes your 100% Adrenaline Finisher!"
	if id == "counter":
		return "Coach: Counters need a read. Match the tell before you spend the stamina."
	return "Coach: Keep reading my shoulders. Don't spend stamina just because you can."


func _finish_training() -> void:
	if not training_active:
		return
	training_active = false
	pending_first_run_tutorial = false
	tutorial_completed = true
	_save_meta_flags()
	adrenaline = 0.0
	player_momentum = false
	_disable_realtime_combat()
	_show_training_complete()


func _show_training_complete() -> void:
	game_state = "training_complete"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_training_complete(self, screen_canvas)


func _show_training_items() -> void:
	_disable_realtime_combat()
	game_state = "training_items"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_training_items(self, screen_canvas)


func _toggle_item_lesson_demo() -> void:
	item_lesson_demo_used = not item_lesson_demo_used
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_training_items(self, screen_canvas)


func _toggle_item_lesson_scope() -> void:
	item_lesson_show_all = not item_lesson_show_all
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_training_items(self, screen_canvas)


func _show_telegraph_practice() -> void:
	_disable_realtime_combat()
	training_active = false
	if game_state != "hub":
		game_state = "telegraph_practice"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_telegraph_practice(self, screen_canvas)


func _select_practice_pose(pose: String) -> void:
	practice_pose = pose
	animate_screen_enter = false
	animate_cards_enter = false
	_clear_ui()
	TLRScreens.build_telegraph_practice(self, screen_canvas)


func _show_codex() -> void:
	_disable_realtime_combat()
	if game_state != "hub":
		game_state = "codex"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_codex(self, screen_canvas)


func _set_codex_tab(tab_id: String) -> void:
	codex_tab = tab_id
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_codex(self, screen_canvas)


func _show_settings() -> void:
	_disable_realtime_combat()
	game_state = "settings"
	animate_screen_enter = true
	animate_cards_enter = true
	_clear_ui()
	TLRScreens.build_settings(self, screen_canvas)


func _set_settings_tab(tab_id: String) -> void:
	settings_tab = tab_id
	settings_saved_notice = false
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_settings(self, screen_canvas)


func _set_setting_value(key: String, value) -> void:
	settings[key] = value
	settings_saved_notice = false
	_apply_settings()
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_settings(self, screen_canvas)


func _save_settings() -> void:
	_apply_settings()
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
	settings_saved_notice = true
	animate_screen_enter = false
	_clear_ui()
	TLRScreens.build_settings(self, screen_canvas)


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed.keys():
			settings[key] = parsed[key]


func _apply_settings() -> void:
	screen_shake = bool(settings.get("screen_shake", false))
	crt_enabled = bool(settings.get("crt_enabled", true))
	TLRTheme.apply_accessibility(
		str(settings.get("text_size", "Standard")) == "Large",
		str(settings.get("contrast", "Standard")) == "High"
	)
	if is_instance_valid(arena_visuals) and arena_visuals.has_method("set_reduced_motion"):
		arena_visuals.set_reduced_motion(bool(settings.get("reduced_motion", false)))
	if is_instance_valid(audio_engine):
		audio_engine.apply_volumes(settings)
	if is_instance_valid(crt_overlay):
		crt_overlay.visible = crt_enabled
	if is_instance_valid(brightness_overlay):
		var br := int(settings.get("brightness", 50))
		if br < 50:
			brightness_overlay.color = Color(0.0, 0.0, 0.0, clampf((50.0 - float(br)) / 80.0, 0.0, 0.45))
		elif br > 50:
			brightness_overlay.color = Color(1.0, 1.0, 1.0, clampf((float(br) - 50.0) / 160.0, 0.0, 0.18))
		else:
			brightness_overlay.color = Color(0, 0, 0, 0)
	if DisplayServer.get_name() != "headless":
		var win := get_window()
		if is_instance_valid(win):
			var am := str(settings.get("aspect_mode", "Auto (Fill)"))
			match am:
				"16:9", "Keep 16:9":
					win.content_scale_size = Vector2i(1600, 900)
					win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
				"16:10":
					win.content_scale_size = Vector2i(1600, 1000)
					win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
				"21:9":
					win.content_scale_size = Vector2i(1920, 822)
					win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
				"4:3":
					win.content_scale_size = Vector2i(1440, 1080)
					win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
				_:
					win.content_scale_size = Vector2i(1600, 900)
					win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		var vsync_on := bool(settings.get("vsync", true))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_on else DisplayServer.VSYNC_DISABLED)
	if DisplayServer.get_name() != "headless" and not Engine.is_embedded_in_editor():
		var mode := str(settings.get("window_mode", "Windowed"))
		if mode == "Fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		elif mode == "Borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res_str := str(settings.get("resolution", "Auto"))
			var scr_rect := DisplayServer.screen_get_usable_rect()
			if res_str == "Auto":
				var auto_w := maxi(1280, int(roundf(float(scr_rect.size.x) * 0.85)))
				var auto_h := maxi(720, int(roundf(float(scr_rect.size.y) * 0.85)))
				DisplayServer.window_set_size(Vector2i(auto_w, auto_h))
				DisplayServer.window_set_position(scr_rect.position + (scr_rect.size - Vector2i(auto_w, auto_h)) / 2)
			else:
				var res_parts := res_str.split("×")
				if res_parts.size() >= 2:
					var rw := int(res_parts[0].strip_edges())
					var rh := int(res_parts[1].strip_edges())
					if rw >= 800 and rh >= 600:
						DisplayServer.window_set_size(Vector2i(rw, rh))
						if scr_rect.size.x >= rw and scr_rect.size.y >= rh:
							DisplayServer.window_set_position(scr_rect.position + (scr_rect.size - Vector2i(rw, rh)) / 2)
	call_deferred("_layout_ui")
	call_deferred("_update_scene_framing")


func _toggle_shake() -> void:
	screen_shake = not screen_shake
	settings["screen_shake"] = screen_shake
	_show_settings()


func _toggle_crt() -> void:
	crt_enabled = not crt_enabled
	settings["crt_enabled"] = crt_enabled
	_apply_settings()
	_show_settings()


func _trigger_impact_flash(col: Color) -> void:
	if not is_instance_valid(flash_overlay) or not bool(settings.get("flash_effects", true)) or bool(settings.get("reduced_motion", false)):
		return
	flash_overlay.color = col
	var tw := create_tween()
	tw.tween_property(flash_overlay, "color:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
