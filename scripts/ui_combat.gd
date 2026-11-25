extends RefCounted

const TLRTheme = preload("res://scripts/ui_theme.gd")
const TLRScreens = preload("res://scripts/ui_screens.gd")

static var _vig_shader: Shader
static var _edge_vig_shader: Shader
static var _top_tex_norm: GradientTexture2D
static var _top_tex_low: GradientTexture2D
static var _bot_tex: GradientTexture2D


static func _get_vig_shader() -> Shader:
	if _vig_shader == null:
		_vig_shader = Shader.new()
		_vig_shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 d = (UV - vec2(0.5, 0.50)) * vec2(1.0, 1.15);
	float dist = length(d);
	float v = smoothstep(0.28, 0.78, dist);
	COLOR = vec4(0.48, 0.04, 0.07, v * 0.42);
}
"""
	return _vig_shader


static func _get_edge_vig_shader() -> Shader:
	if _edge_vig_shader == null:
		_edge_vig_shader = Shader.new()
		_edge_vig_shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 d = abs(UV - vec2(0.5, 0.5)) * 2.0;
	float edge = max(smoothstep(0.76, 1.0, d.x), smoothstep(0.74, 1.0, d.y));
	COLOR = vec4(0.01, 0.02, 0.04, edge * 0.52);
}
"""
	return _edge_vig_shader


static func _get_top_tex(low_hp: bool) -> GradientTexture2D:
	if low_hp:
		if _top_tex_low == null:
			var g := Gradient.new()
			var col := Color(0.055, 0.015, 0.025, 0.90)
			g.colors = PackedColorArray([col, Color(col.r, col.g, col.b, 0.80), Color(col.r, col.g, col.b, 0.0)])
			g.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
			_top_tex_low = GradientTexture2D.new()
			_top_tex_low.gradient = g
			_top_tex_low.fill_from = Vector2(0.5, 0.0)
			_top_tex_low.fill_to = Vector2(0.5, 1.0)
		return _top_tex_low
	if _top_tex_norm == null:
		var g := Gradient.new()
		var col := Color(0.012, 0.039, 0.082, 0.94)
		g.colors = PackedColorArray([col, Color(col.r, col.g, col.b, 0.80), Color(col.r, col.g, col.b, 0.0)])
		g.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
		_top_tex_norm = GradientTexture2D.new()
		_top_tex_norm.gradient = g
		_top_tex_norm.fill_from = Vector2(0.5, 0.0)
		_top_tex_norm.fill_to = Vector2(0.5, 1.0)
	return _top_tex_norm


static func _get_bot_tex() -> GradientTexture2D:
	if _bot_tex == null:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(0.008, 0.024, 0.048, 0.0), Color(0.008, 0.024, 0.048, 0.86)])
		g.offsets = PackedFloat32Array([0.0, 1.0])
		_bot_tex = GradientTexture2D.new()
		_bot_tex.gradient = g
		_bot_tex.fill_from = Vector2(0.5, 0.0)
		_bot_tex.fill_to = Vector2(0.5, 1.0)
	return _bot_tex


static func build_combat_hud(main: Node, root_ui: Control) -> Control:
	var hud := Control.new()
	hud.name = "CombatHUD"
	hud.position = Vector2.ZERO
	hud.size = root_ui.size if root_ui.size.x > 0.0 and root_ui.size.y > 0.0 else Vector2(1600.0, 900.0)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_PASS
	root_ui.add_child(hud)

	var w: float = hud.size.x
	var h: float = hud.size.y
	if w <= 0.0: w = 1600.0
	if h <= 0.0: h = 900.0
	# Uniform scale preserves true 45-deg bar geometry and square buttons across any aspect ratio
	var s: float = minf(w / 1600.0, h / 900.0)
	var cx: float = w * 0.5
	var cy: float = h * 0.5

	var low_hp := float(main.player.get("health", 100.0)) <= float(main.player.get("max_health", 100.0)) * 0.25
	var min_attack_cost := _lowest_move_cost(main)
	var low_sta := float(main.player.get("stamina", 0.0)) < min_attack_cost

	# Subtle dark industrial screen-edge border vignette (Buckshot Roulette framing)
	var edge_vig := ColorRect.new()
	edge_vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edge_mat := ShaderMaterial.new()
	edge_mat.shader = _get_edge_vig_shader()
	edge_vig.material = edge_mat
	hud.add_child(edge_vig)

	# Low-health radial crimson gradient vignette (cached shader)
	if low_hp:
		var vig := ColorRect.new()
		vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vig_mat := ShaderMaterial.new()
		vig_mat.shader = _get_vig_shader()
		vig.material = vig_mat
		hud.add_child(vig)

	# Top smooth fade gradient edge-to-edge
	var top_band := TextureRect.new()
	top_band.texture = _get_top_tex(low_hp)
	top_band.position = Vector2.ZERO
	top_band.size = Vector2(w, 170.0 * s)
	top_band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_band)

	# Bottom smooth fade gradient behind bag/move cards edge-to-edge
	var bot_band := TextureRect.new()
	bot_band.texture = _get_bot_tex()
	bot_band.position = Vector2(0.0, h - 290.0 * s)
	bot_band.size = Vector2(w, 290.0 * s)
	bot_band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bot_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bot_band)

	# --- PLAYER STATUS (TOP LEFT) ---
	var rx := w - 40.0 * s
	var plate_w := clampf(w - 920.0 * s, 190.0 * s, 240.0 * s)
	var side_avail := maxf(180.0 * s, (w - plate_w) * 0.5 - 156.0 * s)
	var bar_w := minf(452.0 * s, side_avail)
	var sta_w := minf(412.0 * s, bar_w * 0.91)

	var player_header := "YOU  /  COACH SPAR" if main.training_active else ("YOU  /  %s" % str(main._respect_rank()))
	TLRTheme.make_abs_label(hud, player_header, Rect2(40 * s, 18 * s, bar_w + 68 * s, 22 * s), 14, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(hud, str(int(roundf(float(main.player.health)))), Rect2(40 * s, 42 * s, 76 * s, 44 * s), 42, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(hud, "/ %d" % int(main.player.max_health), Rect2(40 * s, 86 * s, 76 * s, 18 * s), 12, TLRTheme.TEXT_MUTED, true)

	_make_slanted_combat_bar(hud, Rect2(126 * s, 48 * s, bar_w, 18 * s), float(main.player.health), float(main.player.max_health), TLRTheme.CORAL, TLRTheme.CORAL_GHOST, main.hud_player_hp, main, false)
	main.hud_player_hp = float(main.player.health)

	_make_slanted_combat_bar(hud, Rect2(126 * s, 72 * s, sta_w, 13 * s), float(main.player.stamina), float(main.player.max_stamina), TLRTheme.BLUE, TLRTheme.BLUE_GHOST, main.hud_player_stamina, main, false)
	main.hud_player_stamina = float(main.player.stamina)

	TLRTheme.make_abs_label(hud, "%d / %d STA" % [int(roundf(float(main.player.stamina))), int(main.player.max_stamina)], Rect2(126 * s, 92 * s, 220 * s, 20 * s), 13, TLRTheme.BLUE, true)
	TLRTheme.make_abs_label(hud, "DMG %d   DEF %d   SPD %d%%" % [int(main.player.damage), int(main.player.defence), int(main._speed_chance(float(main.player.speed)))], Rect2(126 * s, 114 * s, bar_w, 20 * s), 12, TLRTheme.TEXT_MUTED, false)

	# --- OPPONENT STATUS (TOP RIGHT, DOCKED TO RIGHT EDGE) ---
	var enemy_name := "COACH  /  TRAINING PARTNER" if main.training_active else str(main.enemy.get("name", "OPPONENT")).to_upper()
	TLRTheme.make_abs_label(hud, enemy_name, Rect2(rx - bar_w - 84 * s, 18 * s, bar_w + 84 * s, 22 * s), 14, TLRTheme.TEXT_PRIMARY, true, HORIZONTAL_ALIGNMENT_RIGHT)
	TLRTheme.make_abs_label(hud, str(int(roundf(float(main.enemy.health)))), Rect2(rx - 76 * s, 42 * s, 76 * s, 44 * s), 42, TLRTheme.TEXT_PRIMARY, true, HORIZONTAL_ALIGNMENT_RIGHT)
	TLRTheme.make_abs_label(hud, "/ %d" % int(main.enemy.max_health), Rect2(rx - 76 * s, 86 * s, 76 * s, 18 * s), 12, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)

	_make_slanted_combat_bar(hud, Rect2(rx - 86 * s - bar_w, 48 * s, bar_w, 18 * s), float(main.enemy.health), float(main.enemy.max_health), TLRTheme.CORAL, TLRTheme.CORAL_GHOST, main.hud_enemy_hp, main, true)
	main.hud_enemy_hp = float(main.enemy.health)

	_make_slanted_combat_bar(hud, Rect2(rx - 86 * s - sta_w, 72 * s, sta_w, 13 * s), float(main.enemy.stamina), float(main.enemy.max_stamina), TLRTheme.BLUE, TLRTheme.BLUE_GHOST, main.hud_enemy_stamina, main, true)
	main.hud_enemy_stamina = float(main.enemy.stamina)

	TLRTheme.make_abs_label(hud, "%d / %d STA" % [int(roundf(float(main.enemy.stamina))), int(main.enemy.max_stamina)], Rect2(rx - 306 * s, 92 * s, 220 * s, 20 * s), 13, TLRTheme.BLUE, true, HORIZONTAL_ALIGNMENT_RIGHT)
	TLRTheme.make_abs_label(hud, "DMG %d   DEF %d   SPD %d%%" % [int(main.enemy.damage), int(main.enemy.defence), int(main._speed_chance(float(main.enemy.speed)))], Rect2(rx - 86 * s - bar_w, 114 * s, bar_w, 20 * s), 12, TLRTheme.TEXT_MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)

	# --- CENTER ROUND / TURN PLATE (CENTERED AT cx) ---
	var plate := TLRTheme.make_panel(hud, Rect2(cx - plate_w * 0.5, 22 * s, plate_w, 106 * s), Color(0.047, 0.102, 0.173, 0.96), Color(0.169, 0.271, 0.369, 0.95), 1, 0, 0)
	var vdiv := ColorRect.new()
	vdiv.position = Vector2(plate_w * 0.5, 18 * s)
	vdiv.size = Vector2(1, 70 * s)
	vdiv.color = Color(0.169, 0.271, 0.369, 0.85)
	plate.add_child(vdiv)
	var plate_left_lbl := "SPAR" if main.training_active else "ROUND"
	var plate_right_lbl := "EXCHANGE" if main.training_active else "TURN"
	var train_ex := mini(int(main.training_turn) + 1, int(main.TRAINING_EXCHANGES))
	var plate_right_val := "%02d / %02d" % [train_ex, int(main.TRAINING_EXCHANGES)] if main.training_active else ("%02d / 06" % int(main.turn_no))
	TLRTheme.make_abs_label(plate, plate_left_lbl, Rect2(8 * s, 12 * s, plate_w * 0.5 - 16 * s, 18 * s), 11, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	TLRTheme.make_abs_label(plate, plate_right_lbl, Rect2(plate_w * 0.5 + 8 * s, 12 * s, plate_w * 0.5 - 16 * s, 18 * s), 11, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	TLRTheme.make_abs_label(plate, "%02d" % int(main.round_no), Rect2(8 * s, 36 * s, plate_w * 0.5 - 16 * s, 52 * s), 38, TLRTheme.TEXT_PRIMARY, true, HORIZONTAL_ALIGNMENT_CENTER)
	TLRTheme.make_abs_label(plate, plate_right_val, Rect2(plate_w * 0.5 + 4 * s, 42 * s, plate_w * 0.5 - 8 * s, 40 * s), 24, TLRTheme.TEXT_PRIMARY, true, HORIZONTAL_ALIGNMENT_CENTER)

	# --- PHASE STRIP (CENTERED AT cx) ---
	var phase_text := "YOUR TURN  /  CHOOSE A MOVE"
	var phase_bg := Color(0.047, 0.153, 0.204, 0.92)
	var phase_border := Color(0.231, 0.475, 0.494, 0.98)
	var phase_col := TLRTheme.MINT
	if main.combat_paused:
		phase_text = "TRAINING  /  PAUSED" if main.training_active else "YOUR TURN  /  PAUSED"
		phase_bg = TLRTheme.SURFACE_AMBER
		phase_border = TLRTheme.BORDER_AMBER
		phase_col = TLRTheme.AMBER
	elif main.training_active:
		if main.training_retry_flag:
			phase_text = "RETRY EXCHANGE  /  READ THE TELL"
			phase_bg = TLRTheme.SURFACE_AMBER
			phase_border = TLRTheme.BORDER_AMBER
			phase_col = TLRTheme.AMBER
		else:
			phase_text = "COACH SPAR  /  READ & RESPOND"
	elif main.round_transition_open:
		phase_text = "ROUND %02d  /  COMPLETE" % maxi(1, int(main.round_no) - 1)
	elif low_hp:
		phase_text = "DANGER  /  %d HEALTH REMAINING" % int(roundf(float(main.player.health)))
		phase_bg = TLRTheme.SURFACE_CRIMSON
		phase_border = TLRTheme.BORDER_CRIMSON
		phase_col = TLRTheme.CORAL
	elif low_sta:
		phase_text = "FATIGUED  /  %d STAMINA" % int(roundf(float(main.player.stamina)))
		phase_bg = TLRTheme.SURFACE_AMBER
		phase_border = TLRTheme.BORDER_AMBER
		phase_col = TLRTheme.AMBER

	var phase_w := 300.0 * s
	var phase_panel := TLRTheme.make_panel(hud, Rect2(cx - phase_w * 0.5, 152 * s, phase_w, 38 * s), phase_bg, phase_border, 2, 0, 0)
	TLRTheme.make_abs_label(phase_panel, phase_text, Rect2(8 * s, 3 * s, 284 * s, 32 * s), 13, phase_col, true, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	if main.animate_phase_banner and not bool(main.settings.get("reduced_motion", false)):
		main.animate_phase_banner = false
		_animate_pop(main, phase_panel, Vector2(0.0, -10.0 * s), 0.20)
	else:
		main.animate_phase_banner = false

	# --- LEFT ACTIVE EFFECT PILLS (11 Combat — Buffs and debuffs.png) ---
	var status_pills: Array[Dictionary] = []
	if main.heart_active:
		status_pills.append({"text": "HEART / +8% CRIT CHANCE", "bg": TLRTheme.SURFACE_CRIMSON, "border": TLRTheme.BORDER_CRIMSON, "col": TLRTheme.CORAL})
	if int(main.enemy_blinded) > 0:
		status_pills.append({"text": "VASELINE / -15%% OPP ACC (%dT)" % int(main.enemy_blinded), "bg": TLRTheme.SURFACE_TEAL, "border": TLRTheme.BORDER_TEAL, "col": TLRTheme.MINT})
	if int(main.enemy_drained) > 0:
		status_pills.append({"text": "ROSIN / -8 OPP STA (%dT)" % int(main.enemy_drained), "bg": TLRTheme.SURFACE_TEAL, "border": TLRTheme.BORDER_TEAL, "col": TLRTheme.MINT})
	if int(main.loaded_bonus) > 0:
		status_pills.append({"text": "LOADED TAPE / +%d NEXT HIT" % int(main.loaded_bonus), "bg": TLRTheme.SURFACE_AMBER, "border": TLRTheme.BORDER_AMBER, "col": TLRTheme.AMBER})
	if main.bribe_ready:
		status_pills.append({"text": "BRIBE READY / DIRTY MOVE SAFE", "bg": TLRTheme.SURFACE_TEAL, "border": TLRTheme.BORDER_TEAL, "col": TLRTheme.MINT})
	if main.energy_penalty_pending:
		status_pills.append({"text": "ENERGY CRASH / -10 STA NEXT TURN", "bg": TLRTheme.SURFACE_CRIMSON, "border": TLRTheme.BORDER_CRIMSON, "col": TLRTheme.CORAL})
	if float(main.next_fight_speed_bonus) > 0.0:
		status_pills.append({"text": "CROWD FAVOURITE / +%d%% SPD NEXT FIGHT" % int(main.next_fight_speed_bonus), "bg": TLRTheme.SURFACE_TEAL, "border": TLRTheme.BORDER_TEAL, "col": TLRTheme.MINT})

	for pi in range(status_pills.size()):
		var sp: Dictionary = status_pills[pi]
		var pill := TLRTheme.make_panel(hud, Rect2(40 * s, (166 + pi * 36) * s, 310 * s, 28 * s), sp.bg, sp.border, 1, 0, 0)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TLRTheme.make_abs_label(pill, str(sp.text), Rect2(10 * s, 3 * s, 290 * s, 22 * s), 11, sp.col, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)

	# --- RINGSIDE COMMENTARY / COACH CUE (DOCKED TO RIGHT EDGE) ---
	if main.training_active:
		var cw := 264.0 * s
		var ch := 244.0 * s
		var comm := TLRTheme.make_panel(hud, Rect2(rx - cw, cy - ch * 0.5 - 52.0 * s, cw, ch), Color(0.031, 0.082, 0.133, 0.92), TLRTheme.BORDER_TEAL, 1, 0, 0)
		comm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TLRTheme.make_abs_label(comm, "■  COACH / LESSON %02d" % train_ex, Rect2(14 * s, 12 * s, 236 * s, 18 * s), 11, TLRTheme.MINT, true)
		var tell_line := str(main.enemy_next_action.get("tell", "Coach studies your guard."))
		TLRTheme.make_abs_label(comm, tell_line, Rect2(14 * s, 38 * s, 236 * s, 64 * s), 13, TLRTheme.CYAN, false)
		TLRTheme.make_abs_label(comm, "“%s”" % str(main.training_feedback), Rect2(14 * s, 108 * s, 236 * s, 92 * s), 13, TLRTheme.TEXT_PRIMARY, false)
		var rec_ids: Array = main._training_recommended_moves()
		var rec_names: Array[String] = []
		for r_id in rec_ids:
			rec_names.append(str(main._get_move(str(r_id)).get("name", r_id)).to_upper())
		TLRTheme.make_abs_label(comm, "TRY: " + " · ".join(rec_names), Rect2(14 * s, 212 * s, 236 * s, 20 * s), 10, TLRTheme.MINT, true)
	elif bool(main.settings.get("subtitles", true)):
		var cw := 232.0 * s
		var ch := 174.0 * s
		var comm := TLRTheme.make_panel(hud, Rect2(rx - cw, cy - ch * 0.5 - 64.0 * s, cw, ch), Color(0.031, 0.082, 0.133, 0.90), TLRTheme.BORDER_SUBTLE, 1, 0, 0)
		comm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TLRTheme.make_abs_label(comm, "■  RINGSIDE / LIVE", Rect2(14 * s, 12 * s, 204 * s, 20 * s), 11, TLRTheme.MINT, true)
		var corner_line := "Keep it sharp. Make every point of stamina count."
		if not main.log_lines.is_empty():
			corner_line = str(main.log_lines[main.log_lines.size() - 1])
		TLRTheme.make_abs_label(comm, "“%s”" % corner_line, Rect2(14 * s, 40 * s, 204 * s, 96 * s), 14, TLRTheme.TEXT_PRIMARY, false)
		TLRTheme.make_abs_label(comm, "THE VOICE OF THE PIT", Rect2(14 * s, 146 * s, 204 * s, 18 * s), 10, TLRTheme.TEXT_DIM, true)

	# --- BOTTOM-CENTER EXCHANGE TOAST ---
	var bot_base := h - 900.0 * s
	var toast_title := str(main.combat_banner_title)
	var toast_sub := str(main.combat_banner_sub)
	if toast_title.is_empty() and low_hp:
		toast_title = "ON THE ROPES"
		toast_sub = "Smelling Salts ready • Defend to survive" if main.inventory.has("salts") else "Smelling Salts not owned • Defend to survive"
	elif toast_title.is_empty() and low_sta:
		toast_title = "NOT ENOUGH STAMINA"
		toast_sub = "Rest to recover 24 • Energy Drink restores 35"
	if not toast_title.is_empty():
		var toast_w := 480.0 * s
		var toast := TLRTheme.make_panel(hud, Rect2(cx - toast_w * 0.5, bot_base + 590 * s, toast_w, 68 * s), Color(0.031, 0.082, 0.133, 0.94), TLRTheme.c_border_subtle(), 2, 0, 0)
		toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TLRTheme.make_abs_label(toast, toast_title.to_upper(), Rect2(16 * s, 8 * s, 448 * s, 24 * s), 17, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(toast, toast_sub, Rect2(16 * s, 34 * s, 448 * s, 26 * s), 13, TLRTheme.TEXT_MUTED, false)
		if main.animate_combat_banner and not bool(main.settings.get("reduced_motion", false)):
			main.animate_combat_banner = false
			_animate_pop(main, toast, Vector2(0.0, 22.0 * s), 0.24)
		else:
			main.animate_combat_banner = false

	# --- FLOATING TOOLTIP PANEL ---
	var tooltip_panel := TLRTheme.make_panel(hud, Rect2(cx, bot_base + 456 * s, 340 * s, 204 * s), Color(0.039, 0.090, 0.157, 0.98), TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	tooltip_panel.name = "HoverTooltip"
	tooltip_panel.visible = false
	tooltip_panel.z_index = 50
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- CORNER BAG (DOCKED BOTTOM LEFT, 3 SLOTS) ---
	var card_scale := clampf((w - 110.0 * s) / (1184.0 * s), 0.72, 1.0)
	var cs := s * card_scale
	var cw_card := 120.0 * cs
	var cstep := 128.0 * cs
	var ch_card := 124.0 * s

	var bag_icon := TLRTheme.UIIcon.new("salts", TLRTheme.CYAN, Vector2(16 * s, 16 * s))
	bag_icon.position = Vector2(40 * s, bot_base + 681 * s)
	hud.add_child(bag_icon)
	TLRTheme.make_abs_label(hud, "CORNER BAG", Rect2(62 * s, bot_base + 678 * s, 188 * cs, 24 * s), 15, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(hud, "%d / 3 SLOTS" % main.inventory.size(), Rect2(40 * s + 3.0 * cstep - 130 * cs, bot_base + 678 * s, 122 * cs, 24 * s), 12, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)

	for slot in range(3):
		var item_id := str(main.inventory[slot]) if slot < main.inventory.size() else ""
		var item_key: String = ["Q", "W", "E"][slot]
		var ix := 40.0 * s + float(slot) * cstep
		var iy := bot_base + 708.0 * s
		var iw := cw_card
		var ih := ch_card
		var usable := not item_id.is_empty() and item_id not in ["ice", "salts"]
		var btn := _make_slot_card_button(
			hud,
			Rect2(ix, iy, iw, ih),
			main._use_item.bind(item_id) if usable else Callable(),
			not usable,
			false
		)

		if item_id.is_empty():
			TLRTheme.make_abs_label(btn, item_key, Rect2(iw - 26 * cs, 10 * s, 16 * cs, 18 * s), 11, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)
			TLRTheme.make_abs_label(btn, "EMPTY", Rect2(8 * cs, 54 * s, iw - 16 * cs, 24 * s), 13, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var icon := TLRTheme.UIIcon.new(item_id, TLRTheme.TEXT_PRIMARY if usable else TLRTheme.TEXT_MUTED, Vector2(20 * cs, 20 * cs))
			icon.position = Vector2(12 * cs, 12 * s)
			btn.add_child(icon)
			TLRTheme.make_abs_label(btn, "×1", Rect2(iw - 44 * cs, 12 * s, 32 * cs, 18 * s), 11, TLRTheme.BLUE if usable else TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)
			var short_name := str(main._get_item_name(item_id)).to_upper()
			if item_id == "energy": short_name = "ENERGY"
			elif item_id == "ice": short_name = "CORNER ICE"
			elif item_id == "salts": short_name = "LAST STAND"
			TLRTheme.make_abs_label(btn, short_name, Rect2(10 * cs, 60 * s, iw - 28 * cs, 24 * s), roundi(17 * card_scale), TLRTheme.TEXT_PRIMARY if usable else TLRTheme.TEXT_MUTED, true)
			TLRTheme.make_abs_label(btn, item_key, Rect2(iw - 24 * cs, 62 * s, 16 * cs, 20 * s), 11, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)
			TLRTheme.make_abs_label(btn, TLRScreens._item_short_hint(item_id), Rect2(10 * cs, 90 * s, iw - 18 * cs, 26 * s), 11, TLRTheme.TEXT_MUTED if usable else TLRTheme.TEXT_DIM, false)

			var idata: Dictionary = main._get_item_data(item_id)
			var t_cat := "ITEM / COMBAT USE" if usable else ("ITEM / HUB ONLY" if item_id == "ice" else "ITEM / PASSIVE")
			var t_cost := "KEY %s" % item_key
			var t_desc := str(idata.get("description", ""))
			var t_foot: String = str(main._item_timing(item_id))
			btn.mouse_entered.connect(_show_rich_tooltip.bind(tooltip_panel, ix, iy, w, s, t_cat, str(main._get_item_name(item_id)).to_upper(), t_cost, t_desc, t_foot))
			btn.mouse_exited.connect(_hide_rich_tooltip.bind(tooltip_panel))

	TLRTheme.make_abs_label(hud, "Using a combat item spends your turn.", Rect2(40 * s, bot_base + 842 * s, 376 * cs, 20 * s), 11, TLRTheme.TEXT_DIM, false)

	# --- CHOOSE YOUR MOVE (DOCKED BOTTOM RIGHT, 6 SLOTS) ---
	var moves_x0 := rx - (5.0 * cstep + cw_card)
	TLRTheme.make_abs_label(hud, "CHOOSE YOUR MOVE", Rect2(moves_x0, bot_base + 678 * s, 280 * cs, 24 * s), 15, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(hud, "One move ends your turn.", Rect2(rx - 320 * cs, bot_base + 678 * s, 320 * cs, 24 * s), 12, TLRTheme.TEXT_MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)

	for slot in range(6):
		var move_id := str(main.owned_moves[slot]) if slot < main.owned_moves.size() else ""
		var slot_key := str(slot + 1)
		var mx := moves_x0 + float(slot) * cstep
		var my := bot_base + 708.0 * s
		var mw := cw_card
		var mh := ch_card

		if move_id.is_empty():
			var empty_btn := _make_slot_card_button(hud, Rect2(mx, my, mw, mh), Callable(), true, false)
			TLRTheme.make_abs_label(empty_btn, slot_key, Rect2(mw - 24 * cs, 10 * s, 14 * cs, 18 * s), 11, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)
			TLRTheme.make_abs_label(empty_btn, "EMPTY", Rect2(8 * cs, 54 * s, mw - 16 * cs, 24 * s), 13, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
			continue

		var md: Dictionary = main._get_move(move_id)
		var move_cost := float(md.get("cost", 0.0))
		var enough := float(main.player.get("stamina", 0.0)) >= move_cost
		var is_rec: bool = bool(main.training_active) and main._training_recommended_moves().has(move_id) and enough
		var is_sel: bool = (move_id == str(main.player_last_move_id)) or is_rec
		var btn := _make_slot_card_button(hud, Rect2(mx, my, mw, mh), main._player_move.bind(move_id), not enough, is_sel)

		var icon := TLRTheme.UIIcon.new(move_id, TLRTheme.TEXT_PRIMARY if enough else TLRTheme.TEXT_DIM, Vector2(20 * cs, 20 * cs))
		icon.position = Vector2(12 * cs, 12 * s)
		btn.add_child(icon)
		TLRTheme.make_abs_label(btn, "%d STA" % int(move_cost), Rect2(36 * cs, 12 * s, mw - 46 * cs, 18 * s), 11, TLRTheme.BLUE if enough else TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)

		var m_name := str(md.get("name", move_id)).to_upper()
		TLRTheme.make_abs_label(btn, m_name, Rect2(10 * cs, 58 * s, mw - 24 * cs, 24 * s), roundi(18 * card_scale), TLRTheme.TEXT_PRIMARY if enough else TLRTheme.TEXT_DIM, true)
		TLRTheme.make_abs_label(btn, slot_key, Rect2(mw - 22 * cs, 60 * s, 14 * cs, 18 * s), 11, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)
		var sub_hint := TLRScreens._move_short_hint(move_id, md) if enough else ("Need %d STA" % int(move_cost))
		TLRTheme.make_abs_label(btn, sub_hint, Rect2(10 * cs, 88 * s, mw - 18 * cs, 28 * s), 11, TLRTheme.TEXT_MUTED if enough else TLRTheme.TEXT_DIM, false)

		var dmg: Array = md.get("damage", [0, 0])
		var dmg_line := "%d–%d base damage • %d%% accuracy" % [int(dmg[0]), int(dmg[1]), int(md.get("accuracy", 100))] if dmg.size() >= 2 and int(dmg[1]) > 0 else ("%d%% accuracy • %s" % [int(md.get("accuracy", 100)), str(md.get("kind", "utility")).capitalize()])
		var t_cat := "MOVE / %s" % str(md.get("kind", "action")).to_upper()
		var t_foot: String = dmg_line + ("\nReady • Ends your turn" if enough else ("\nUNAVAILABLE — need %d more stamina" % int(move_cost - float(main.player.stamina))))
		btn.mouse_entered.connect(_show_rich_tooltip.bind(tooltip_panel, mx, my, w, s, t_cat, m_name, "%d STAMINA" % int(move_cost), str(md.get("description", "")), t_foot))
		btn.mouse_exited.connect(_hide_rich_tooltip.bind(tooltip_panel))

	# --- BOTTOM CENTER DRAWER BAR & ESC PAUSE ---
	var tab_w := minf(372.0 * s, maxf(240.0 * s, w - 760.0 * cs))
	var tab_x := clampf(cx - tab_w * 0.5, 40.0 * s + 3.0 * cstep + 8.0 * s, rx - 440.0 * s - tab_w if main.training_active else rx - 84.0 * s - tab_w)
	TLRTheme.make_abs_button(hud, "TAB  /  ITEMS, MOVES & STATS   %s" % ("⌄" if main.combat_drawer_open else "⌃"), Rect2(tab_x, bot_base + 844 * s, tab_w, 42 * s), main._toggle_combat_drawer, "default", false, 11 if tab_w < 300.0 * s else 12)
	if main.training_active:
		TLRTheme.make_abs_button(hud, "WATCH SIX TELLS", Rect2(rx - 420 * s, bot_base + 844 * s, 166 * s, 42 * s), main._show_telegraph_practice, "default", false, 11)
		TLRTheme.make_abs_button(hud, "EXIT SPAR", Rect2(rx - 244 * s, bot_base + 844 * s, 162 * s, 42 * s), main._exit_training_to_menu, "default", false, 11)
	TLRTheme.make_abs_button(hud, "ESC  II", Rect2(rx - 72 * s, bot_base + 844 * s, 72 * s, 42 * s), main._resume_combat if main.combat_paused else main._toggle_combat_pause, "default", false, 12)

	# --- OVERLAYS ---
	if main.combat_drawer_open:
		_build_fighter_drawer(main, hud, w, h, s, cx, cy)
	if main.round_transition_open:
		_build_round_transition(main, hud, s, cx, cy)
	if main.combat_paused:
		_build_pause_overlay(main, hud, s, cx, cy)
	if main.combat_review_open:
		main._show_combat_review_overlay(s, s, hud)

	return hud


static func _lowest_move_cost(main: Node) -> float:
	var low := 999.0
	for m_id in main.owned_moves:
		var md: Dictionary = main._get_move(str(m_id))
		if not md.is_empty():
			low = minf(low, float(md.get("cost", 0.0)))
	return low if low < 999.0 else 0.0


static func _make_slanted_combat_bar(
	parent: Control,
	rect: Rect2,
	value: float,
	maximum: float,
	fill: Color,
	ghost: Color,
	previous: float,
	main: Node,
	rtl: bool = false
) -> void:
	var max_v := maxf(1.0, maximum)
	var cur_ratio := clampf(value / max_v, 0.0, 1.0)
	var prev_ratio := cur_ratio if previous < 0.0 else clampf(previous / max_v, 0.0, 1.0)

	var bar := TLRTheme.UISlantedBar.new(rect, prev_ratio, prev_ratio, fill, ghost, TLRTheme.CORAL_TRAIL, rtl)
	parent.add_child(bar)

	if not is_equal_approx(prev_ratio, cur_ratio):
		var tw := main.create_tween()
		tw.tween_method(bar.set_ratio, prev_ratio, cur_ratio, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func _make_slot_card_button(
	parent: Control,
	rect: Rect2,
	callback: Callable,
	disabled: bool,
	selected: bool
) -> Button:
	var btn := Button.new()
	btn.position = rect.position
	btn.size = rect.size
	btn.disabled = disabled
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not disabled else Control.CURSOR_ARROW
	var bg := Color(0.090, 0.208, 0.282, 0.96) if selected else Color(0.031, 0.075, 0.133, 0.94)
	var border := Color(0.28, 0.72, 0.75, 1.0) if selected else TLRTheme.c_border_card()
	var normal := TLRTheme.style_box(bg, border, 2, 0, 0, 0)
	var hover := TLRTheme.style_box(TLRTheme.SURFACE_HOVER, TLRTheme.BORDER_HOVER, 2, 0, 0, 0)
	var dis := TLRTheme.style_box(Color(0.022, 0.048, 0.086, 0.86), Color(0.11, 0.18, 0.26, 0.80), 2, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", dis)
	if callback.is_valid():
		btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


static func _show_rich_tooltip(
	panel: Panel,
	card_x: float,
	card_y: float,
	screen_w: float,
	s: float,
	cat: String,
	title: String,
	cost_str: String,
	desc: String,
	footer: String
) -> void:
	for ch in panel.get_children():
		ch.queue_free()
	var w := 360.0 * s
	var h := 204.0 * s
	panel.size = Vector2(w, h)
	panel.position = Vector2(clampf(card_x, 40.0 * s, screen_w - w - 40.0 * s), card_y - h - 14.0 * s)

	TLRTheme.make_abs_label(panel, cat, Rect2(20 * s, 16 * s, w - 40 * s, 18 * s), 11, TLRTheme.TEXT_MUTED, true)
	TLRTheme.make_abs_label(panel, title, Rect2(20 * s, 42 * s, w - 130 * s, 34 * s), 26, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(panel, cost_str, Rect2(w - 130 * s, 48 * s, 110 * s, 22 * s), 13, TLRTheme.BLUE, true, HORIZONTAL_ALIGNMENT_RIGHT)
	TLRTheme.make_abs_label(panel, desc, Rect2(20 * s, 84 * s, w - 40 * s, 48 * s), 14, TLRTheme.TEXT_PRIMARY, false)

	var line := ColorRect.new()
	line.position = Vector2(20 * s, 138 * s)
	line.size = Vector2(w - 40 * s, 1)
	line.color = Color(0.18, 0.28, 0.38, 0.85)
	panel.add_child(line)

	TLRTheme.make_abs_label(panel, footer, Rect2(20 * s, 146 * s, w - 40 * s, 48 * s), 12, TLRTheme.TEXT_MUTED, false)
	var target_y := panel.position.y
	panel.modulate.a = 0.0
	panel.position.y = target_y + 8.0 * s
	panel.visible = true
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "position:y", target_y, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func _hide_rich_tooltip(panel: Panel) -> void:
	if is_instance_valid(panel):
		panel.visible = false


static func _build_fighter_drawer(main: Node, hud: Control, w: float, h: float, s: float, cx: float, cy: float) -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.024, 0.042, 0.74)
	shade.z_index = 80
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(shade)

	var dw := 1160.0 * s
	var dh := 540.0 * s
	var drawer := TLRTheme.make_panel(shade, Rect2(cx - dw * 0.5, cy - dh * 0.5 + 44.0 * s, dw, dh), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(drawer, "YOUR FIGHTER", Rect2(32 * s, 26 * s, 400 * s, 38 * s), 30, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(drawer, "Combat waits while you inspect. Using a move ends your turn.", Rect2(32 * s, 68 * s, 680 * s, 22 * s), 14, TLRTheme.TEXT_MUTED, false)
	TLRTheme.make_abs_button(drawer, "TAB / CLOSE", Rect2(dw - 178 * s, 28 * s, 146 * s, 40 * s), main._toggle_combat_drawer, "default", false, 13)

	# Column 1: Items
	TLRTheme.make_abs_label(drawer, "ITEMS / %d OF 3 SLOTS" % main.inventory.size(), Rect2(32 * s, 114 * s, 320 * s, 22 * s), 14, TLRTheme.CYAN, true)
	for slot in range(3):
		var iy := (148 + slot * 114) * s
		var card := TLRTheme.make_panel(drawer, Rect2(32 * s, iy, 324 * s, 102 * s), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_CARD, 1, 0, 0)
		var item_id := str(main.inventory[slot]) if slot < main.inventory.size() else ""
		if item_id.is_empty():
			TLRTheme.make_abs_label(card, "EMPTY BAG SLOT", Rect2(16 * s, 38 * s, 290 * s, 24 * s), 13, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var ic := TLRTheme.UIIcon.new(item_id, TLRTheme.TEXT_PRIMARY, Vector2(22 * s, 22 * s))
			ic.position = Vector2(16 * s, 16 * s)
			card.add_child(ic)
			TLRTheme.make_abs_label(card, str(main._get_item_name(item_id)).to_upper(), Rect2(48 * s, 14 * s, 260 * s, 24 * s), 15, TLRTheme.TEXT_PRIMARY, true)
			var idata: Dictionary = main._get_item_data(item_id)
			TLRTheme.make_abs_label(card, str(idata.get("description", "")) + "\n" + str(main._item_timing(item_id)), Rect2(16 * s, 44 * s, 292 * s, 50 * s), 12, TLRTheme.TEXT_MUTED, false)

	# Column 2: Moves
	TLRTheme.make_abs_label(drawer, "MOVES / LOADOUT (%d)" % main.owned_moves.size(), Rect2(388 * s, 114 * s, 380 * s, 22 * s), 14, TLRTheme.CYAN, true)
	for mi in range(mini(6, main.owned_moves.size())):
		var m_id := str(main.owned_moves[mi])
		var md: Dictionary = main._get_move(m_id)
		var my := (148 + mi * 58) * s
		var row := TLRTheme.make_panel(drawer, Rect2(388 * s, my, 404 * s, 50 * s), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_CARD, 1, 0, 0)
		var m_cost := float(md.get("cost", 0.0))
		var ready := float(main.player.stamina) >= m_cost
		TLRTheme.make_abs_label(row, str(md.get("name", m_id)).to_upper(), Rect2(14 * s, 6 * s, 160 * s, 20 * s), 14, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(row, "%d STA" % int(m_cost), Rect2(180 * s, 6 * s, 80 * s, 20 * s), 12, TLRTheme.BLUE, true)
		TLRTheme.make_abs_label(row, "READY" if ready else "LOW STA", Rect2(290 * s, 6 * s, 100 * s, 20 * s), 11, TLRTheme.MINT if ready else TLRTheme.AMBER, true, HORIZONTAL_ALIGNMENT_RIGHT)
		TLRTheme.make_abs_label(row, str(md.get("description", "")), Rect2(14 * s, 26 * s, 376 * s, 18 * s), 11, TLRTheme.TEXT_MUTED, false)

	# Column 3: Stats & Active Effects
	TLRTheme.make_abs_label(drawer, "FIGHTER STATS", Rect2(824 * s, 114 * s, 300 * s, 22 * s), 14, TLRTheme.CYAN, true)
	var stat_rows := [
		["HEALTH", "%d / %d" % [int(main.player.health), int(main.player.max_health)]],
		["STAMINA", "%d / %d" % [int(main.player.stamina), int(main.player.max_stamina)]],
		["DAMAGE", str(int(main.player.damage))],
		["DEFENCE", str(int(main.player.defence))],
		["SPEED", "%d%%" % int(main._speed_chance(float(main.player.speed)))]
	]
	for si in range(stat_rows.size()):
		var sy_pos := (152 + si * 34) * s
		TLRTheme.make_abs_label(drawer, stat_rows[si][0], Rect2(824 * s, sy_pos, 140 * s, 22 * s), 13, TLRTheme.TEXT_MUTED, true)
		TLRTheme.make_abs_label(drawer, stat_rows[si][1], Rect2(970 * s, sy_pos, 150 * s, 24 * s), 18, TLRTheme.TEXT_PRIMARY, true, HORIZONTAL_ALIGNMENT_RIGHT)

	TLRTheme.make_abs_label(drawer, "ACTIVE EFFECTS & LAST STAND", Rect2(824 * s, 344 * s, 300 * s, 22 * s), 13, TLRTheme.CYAN, true)
	var eff: Array[String] = []
	if main.loaded_bonus > 0: eff.append("Loaded Tape +%d next hit" % int(main.loaded_bonus))
	if int(main.enemy_blinded) > 0: eff.append("Vaseline -15% opp acc (%dT)" % int(main.enemy_blinded))
	if int(main.enemy_drained) > 0: eff.append("Rosin -8 opp STA (%dT)" % int(main.enemy_drained))
	if main.bribe_ready: eff.append("Dirty move protected")
	if main.energy_penalty_pending: eff.append("Energy crash (-10 STA next turn)")
	var salts_str := "Salts: SPENT" if main.revive_used else ("Salts: READY" if main.inventory.has("salts") else "Salts: NOT IN BAG")
	var eff_text := (", ".join(eff) if not eff.is_empty() else "No temporary effects active.") + "\n" + salts_str
	TLRTheme.make_abs_label(drawer, eff_text, Rect2(824 * s, 374 * s, 300 * s, 80 * s), 13, TLRTheme.TEXT_MUTED, false)

	TLRTheme.make_abs_label(drawer, "CAREER RESPECT %d  •  %s" % [int(main.lifetime_respect), str(main._respect_rank())], Rect2(824 * s, 468 * s, 300 * s, 42 * s), 12, TLRTheme.TEXT_DIM, false)

	TLRTheme.make_abs_button(shade, "TAB  /  CLOSE FIGHTER DRAWER   ⌄", Rect2(cx - 186 * s, h - 56 * s, 372 * s, 42 * s), main._toggle_combat_drawer, "teal", false, 12)
	if main.animate_drawer_open and not bool(main.settings.get("reduced_motion", false)):
		main.animate_drawer_open = false
		shade.modulate.a = 0.0
		var stw := main.create_tween()
		stw.tween_property(shade, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_animate_pop(main, drawer, Vector2(0.0, 48.0 * s), 0.24)
	else:
		main.animate_drawer_open = false


static func _build_round_transition(main: Node, hud: Control, s: float, cx: float, cy: float) -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.024, 0.042, 0.74)
	shade.z_index = 80
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(shade)

	var cw := 740.0 * s
	var ch := 240.0 * s
	var card := TLRTheme.make_panel(shade, Rect2(cx - cw * 0.5, cy - ch * 0.5 - 26.0 * s, cw, ch), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 2, 0, 0)
	TLRTheme.make_abs_label(card, "END OF ROUND %02d" % maxi(1, int(main.round_no) - 1), Rect2(36 * s, 28 * s, 400 * s, 22 * s), 13, TLRTheme.TEXT_MUTED, true)
	TLRTheme.make_abs_label(card, "BACK TO YOUR CORNER", Rect2(36 * s, 64 * s, 668 * s, 44 * s), 34, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(card, "Health and stamina carry into the next round. (+14 stamina recovered)", Rect2(36 * s, 118 * s, 668 * s, 26 * s), 15, TLRTheme.TEXT_MUTED, false)
	TLRTheme.make_abs_button(card, "BEGIN ROUND %02d" % int(main.round_no), Rect2(36 * s, 164 * s, 310 * s, 48 * s), main._dismiss_round_transition, "teal", false, 14)
	if main.animate_round_transition and not bool(main.settings.get("reduced_motion", false)):
		main.animate_round_transition = false
		shade.modulate.a = 0.0
		var stw := main.create_tween()
		stw.tween_property(shade, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_animate_pop(main, card, Vector2(0.0, 36.0 * s), 0.28)
	else:
		main.animate_round_transition = false


static func _build_pause_overlay(main: Node, hud: Control, s: float, cx: float, cy: float) -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.024, 0.042, 0.78)
	shade.z_index = 85
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(shade)

	var is_train := bool(main.training_active)
	var cw := 480.0 * s
	var ch := (446.0 if is_train else 386.0) * s
	var card := TLRTheme.make_panel(shade, Rect2(cx - cw * 0.5, cy - ch * 0.5, cw, ch), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 2, 0, 0)
	TLRTheme.make_abs_label(card, "THE LAST ROUND / COACH SPAR" if is_train else "THE LAST ROUND", Rect2(36 * s, 28 * s, 360 * s, 22 * s), 13, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(card, "TRAINING PAUSED" if is_train else "FIGHT PAUSED", Rect2(36 * s, 56 * s, 408 * s, 48 * s), 38, TLRTheme.TEXT_PRIMARY, true)
	var train_ex := mini(int(main.training_turn) + 1, int(main.TRAINING_EXCHANGES))
	var pause_sub := "Exchange %02d of %02d  •  No run progress changed" % [train_ex, int(main.TRAINING_EXCHANGES)] if is_train else ("Fight %02d  •  Round %02d  •  Turn %02d" % [int(main.fight_index) + 1, int(main.round_no), int(main.turn_no)])
	TLRTheme.make_abs_label(card, pause_sub, Rect2(36 * s, 112 * s, 408 * s, 24 * s), 14, TLRTheme.TEXT_MUTED, false)

	if is_train:
		TLRTheme.make_abs_button(card, "RESUME TRAINING", Rect2(36 * s, 156 * s, 408 * s, 48 * s), main._resume_combat, "teal", false, 14)
		TLRTheme.make_abs_button(card, "CORNER BAG LESSON", Rect2(36 * s, 218 * s, 408 * s, 48 * s), main._show_training_items, "default", false, 14)
		TLRTheme.make_abs_button(card, "WATCH ALL SIX TELLS", Rect2(36 * s, 280 * s, 408 * s, 48 * s), main._show_telegraph_practice, "default", false, 14)
		TLRTheme.make_abs_button(card, "EXIT TO MAIN MENU", Rect2(36 * s, 342 * s, 408 * s, 48 * s), main._exit_training_to_menu, "default", false, 14)
		TLRTheme.make_abs_label(card, "ESC / Resume   •   Keys 1–6 / Choose Move   •   Q W E / Items", Rect2(36 * s, 406 * s, 408 * s, 22 * s), 12, TLRTheme.TEXT_DIM, false)
	else:
		TLRTheme.make_abs_button(card, "RESUME FIGHT", Rect2(36 * s, 156 * s, 408 * s, 48 * s), main._resume_combat, "teal", false, 14)
		TLRTheme.make_abs_button(card, "REVIEW ALL COMBAT STATES", Rect2(36 * s, 218 * s, 408 * s, 48 * s), main._open_review_from_pause, "default", false, 14)
		TLRTheme.make_abs_button(card, "FORFEIT RUN", Rect2(36 * s, 280 * s, 408 * s, 48 * s), main._forfeit_run, "default", false, 14)
		TLRTheme.make_abs_label(card, "ESC / Resume   •   F1 / Combat review index", Rect2(36 * s, 344 * s, 408 * s, 22 * s), 12, TLRTheme.TEXT_DIM, false)

	if main.animate_pause_open and not bool(main.settings.get("reduced_motion", false)):
		main.animate_pause_open = false
		shade.modulate.a = 0.0
		var stw := main.create_tween()
		stw.tween_property(shade, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_animate_pop(main, card, Vector2(0.0, 24.0 * s), 0.22)
	else:
		main.animate_pause_open = false


static func _animate_pop(main: Node, node: Control, offset: Vector2, duration: float) -> void:
	var target_pos := node.position
	node.position = target_pos + offset
	node.modulate.a = 0.0
	var tw := main.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
