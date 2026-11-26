extends RefCounted

const TLRTheme = preload("res://scripts/ui_theme.gd")
const TLRBoxerPreview = preload("res://scripts/ui_boxer_preview.gd")
const TLRStory = preload("res://scripts/story_data.gd")


static func _next_milestone(lifetime_respect: int) -> Dictionary:
	if lifetime_respect < 50:
		return {"target": 50, "label": "GRIT", "desc": "Grit (+5 max HP) unlocks at 50 Respect."}
	if lifetime_respect < 200:
		return {"target": 200, "label": "CONDITIONING", "desc": "Conditioning (+5 max STA) unlocks at 200 Respect."}
	if lifetime_respect < 500:
		return {"target": 500, "label": "POWER", "desc": "Power (+1 DMG) unlocks at 500 Respect."}
	if lifetime_respect < 1000:
		return {"target": 1000, "label": "GUARD", "desc": "Guard (+1 DEF) unlocks at 1000 Respect."}
	return {"target": 1000, "label": "LEGEND", "desc": "All permanent career perks unlocked."}


static func _move_short_hint(move_id: String, move_data: Dictionary) -> String:
	match move_id:
		"jab": return "Fast, reliable hit"
		"block": return "Reduce damage"
		"slip": return "Evade the blow"
		"counter": return "Punish a whiff"
		"clinch": return "Smother attack"
		"rest": return "+24 STA; exposed"
		"uppercut": return "Heavy power punch"
		"hook": return "Heavy side shot"
		"haymaker": return "Huge risk & power"
		"body_shot": return "Drains enemy STA"
		"overhand": return "Cracks tight guard"
		"feint": return "Disrupts enemy tell"
		"one_two": return "Two quick punches"
		"headbutt": return "Dirty; 18% DQ risk"
		"low_blow": return "Dirty; 27% DQ risk"
		_: return str(move_data.get("description", ""))


static func _item_short_hint(item_id: String) -> String:
	match item_id:
		"energy": return "+35 STA now"
		"ice": return "Hub use only"
		"salts": return "Triggers on KO"
		"vaseline": return "-15% opp acc (2T)"
		"rosin": return "-8 opp STA (2T)"
		"loaded_tape": return "+18 dmg; 12% DQ"
		"bribe": return "Protects dirty move"
		"crowd": return "+5 SPD next fight"
		"cutman_kit": return "Quick: +16HP/Cure"
		"pepper_wrap": return "Opening & -10 STA"
		"adrenaline_shot": return "Quick: 100% Finisher"
		"sparring_tonics": return "+12 Max & +18 HP"
		"brass_duster": return "+12 DMG ×3; 10% DQ"
		"nitro_salts": return "Quick: Full STA+22HP"
		_: return "Corner item"


static func _opponent_color_for_fight(f_idx: int) -> Color:
	if f_idx == 7:
		return Color(0.18, 0.16, 0.22)
	match f_idx % 4:
		0: return Color(0.54, 0.34, 0.24)
		1: return Color(0.62, 0.42, 0.30)
		2: return Color(0.42, 0.28, 0.24)
		_: return Color(0.50, 0.35, 0.28)


# ---------------------------------------------------------
# 1. TITLE SCREEN (UI/The Last Round — Title screen.png)
# ---------------------------------------------------------

static func build_title_screen(main: Node, parent: Control) -> void:
	# Cool steel-blue atmospheric haze on the right over the arena (UI/The Last Round — Title screen.png)
	var haze := Gradient.new()
	haze.colors = PackedColorArray([
		Color(0.016, 0.047, 0.110, 0.96),
		Color(0.016, 0.047, 0.110, 0.82),
		Color(0.075, 0.215, 0.345, 0.30),
		Color(0.020, 0.065, 0.135, 0.58)
	])
	haze.offsets = PackedFloat32Array([0.0, 0.38, 0.72, 1.0])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = haze
	grad_tex.fill_from = Vector2(0.0, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	var bg_overlay := TextureRect.new()
	bg_overlay.texture = grad_tex
	bg_overlay.position = Vector2(-700, -300)
	bg_overlay.size = Vector2(3000, 1500)
	bg_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg_overlay)

	# Bottom dark fade behind the 3 corner cards
	var bottom_grad := Gradient.new()
	bottom_grad.colors = PackedColorArray([Color(0.016, 0.047, 0.110, 0.0), Color(0.016, 0.047, 0.110, 0.96)])
	bottom_grad.offsets = PackedFloat32Array([0.0, 1.0])
	var bottom_tex := GradientTexture2D.new()
	bottom_tex.gradient = bottom_grad
	bottom_tex.fill_from = Vector2(0.5, 0.0)
	bottom_tex.fill_to = Vector2(0.5, 1.0)
	var bottom_fade := TextureRect.new()
	bottom_fade.texture = bottom_tex
	bottom_fade.position = Vector2(-700, 440)
	bottom_fade.size = Vector2(3000, 820)
	bottom_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bottom_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bottom_fade)

	# Top-left accent bar + eyebrow
	var orange_bar := ColorRect.new()
	orange_bar.position = Vector2(40, 42)
	orange_bar.size = Vector2(3, 14)
	orange_bar.color = TLRTheme.ACCENT_ORANGE
	parent.add_child(orange_bar)
	TLRTheme.make_abs_label(parent, "AN UNDERGROUND BOXING ROGUELIKE", Rect2(52, 40, 520, 20), 13, TLRTheme.TEXT_MUTED, true)

	# Stacked Condensed Hero Title
	var hero_1 := TLRTheme.make_abs_label(parent, "THE LAST", Rect2(38, 92, 760, 112), 116, TLRTheme.TEXT_PRIMARY, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	var hero_2 := TLRTheme.make_abs_label(parent, "ROUND", Rect2(38, 192, 760, 112), 116, TLRTheme.ACCENT_ORANGE, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)

	# Tagline
	var tag_1 := TLRTheme.make_abs_label(parent, "NO CONTRACT. NO CORNER. NO WAY OUT.", Rect2(40, 326, 650, 24), 15, TLRTheme.TEXT_PRIMARY, true)
	var tag_2 := TLRTheme.make_abs_label(parent, "Eight fights stand between you and the Crown.", Rect2(40, 354, 650, 24), 16, TLRTheme.TEXT_MUTED, false)

	# Notice banner if present
	if not str(main.menu_notice).is_empty():
		var notice_panel := TLRTheme.make_panel(parent, Rect2(40, 384, 520, 32), TLRTheme.SURFACE_AMBER, TLRTheme.BORDER_AMBER, 1, 0, 0)
		TLRTheme.make_abs_label(notice_panel, str(main.menu_notice), Rect2(12, 4, 496, 24), 12, TLRTheme.AMBER, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
		main.menu_notice = ""

	# Primary CTA next to active slot badge
	var active_info: Dictionary = main._slot_info(main.selected_slot)
	var active_has_save := bool(active_info.get("has_save", false))
	var cta_text := "CONTINUE RUN" if active_has_save else "START NEW RUN"
	var cta_cb: Callable = main._continue_run.bind(main.selected_slot) if active_has_save else main._request_new_run.bind(main.selected_slot)
	var cta_btn := TLRTheme.make_abs_button(parent, cta_text, Rect2(40, 424, 286, 56), cta_cb, "orange", false, 20)
	cta_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	TLRTheme.make_abs_label(cta_btn, "→", Rect2(240, 14, 30, 28), 20, Color(0.04, 0.06, 0.09, 1.0), true, HORIZONTAL_ALIGNMENT_RIGHT)
	cta_btn.grab_focus()

	var slot_badge := "SLOT %d  /  FIGHT %d OF 8" % [main.selected_slot + 1, int(active_info.get("fight_index", 0)) + 1] if active_has_save else "SLOT %d  /  EMPTY SLOT" % [main.selected_slot + 1]
	TLRTheme.make_abs_label(parent, slot_badge, Rect2(346, 441, 340, 24), 13, TLRTheme.TEXT_MUTED, true)

	# Top-right Career Record
	var cr_x := 1190.0
	TLRTheme.make_abs_label(parent, "CAREER RECORD", Rect2(cr_x, 40, 370, 20), 12, TLRTheme.TEXT_MUTED, true)
	var cr_line := ColorRect.new()
	cr_line.position = Vector2(cr_x, 66)
	cr_line.size = Vector2(370, 1)
	cr_line.color = Color(0.24, 0.34, 0.44, 0.6)
	parent.add_child(cr_line)

	TLRTheme.make_abs_label(parent, str(main.lifetime_respect), Rect2(cr_x, 76, 120, 54), 48, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(parent, "RESPECT", Rect2(cr_x + 115, 98, 160, 24), 13, TLRTheme.TEXT_MUTED, true)
	TLRTheme.make_abs_label(parent, str(main._respect_rank()), Rect2(cr_x, 134, 370, 24), 16, TLRTheme.TEXT_PRIMARY, true)

	var milestone := _next_milestone(main.lifetime_respect)
	var target := int(milestone.target)
	TLRTheme.add_progress_bar(parent, Rect2(cr_x, 168, 370, 3), float(main.lifetime_respect), float(target), TLRTheme.ACCENT_ORANGE, Color(0.18, 0.24, 0.31, 0.7))
	var mile_text := "%d / %d RESPECT  •  UNLOCK %s" % [main.lifetime_respect, target, str(milestone.label)] if main.lifetime_respect < 1000 else "%d RESPECT  •  MAX RANK" % main.lifetime_respect
	TLRTheme.make_abs_label(parent, mile_text, Rect2(cr_x, 180, 370, 20), 11, TLRTheme.TEXT_MUTED, true)
	TLRTheme.make_abs_label(parent, "CAREER PERKS: " + str(main._career_perk_summary()), Rect2(cr_x, 204, 370, 42), 11, TLRTheme.TEXT_DIM, false)
	if int(main.lifetime_respect) > 0:
		var rst_lbl := "CONFIRM RESET RECORD?" if bool(main.confirm_career_reset) else "RESET CAREER RECORD"
		var rst_btn := TLRTheme.make_abs_button(parent, rst_lbl, Rect2(cr_x, 250, 190, 28), main._reset_career_record, "ghost", false, 11)
		rst_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if bool(main.confirm_career_reset):
			rst_btn.add_theme_color_override("font_color", TLRTheme.CORAL)

	# Bottom section header
	TLRTheme.make_abs_label(parent, "CHOOSE YOUR CORNER", Rect2(40, 542, 400, 24), 17, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(parent, "3 SAVE SLOTS  /  EVERY RUN LEAVES A MARK", Rect2(1060, 544, 500, 22), 12, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)

	# 3 Slot Cards
	var card_w := 496.0
	var card_h := 196.0
	var gap := 16.0
	var slot_cards: Array = []
	for slot in range(main.SAVE_SLOT_COUNT):
		var cx := 40.0 + float(slot) * (card_w + gap)
		var cy := 576.0
		var info: Dictionary = main._slot_info(slot)
		var is_selected: bool = (slot == int(main.selected_slot))
		var has_save := bool(info.get("has_save", false))
		var is_corrupt := bool(info.get("corrupt", false))
		var border_col := TLRTheme.ACCENT_ORANGE if is_selected else TLRTheme.BORDER_CARD
		var border_w := 2 if is_selected else 1
		var card := TLRTheme.make_panel(parent, Rect2(cx, cy, card_w, card_h), Color(0.035, 0.075, 0.133, 0.94), border_col, border_w, 0, 0)
		slot_cards.append(card)

		var select_hit := Button.new()
		select_hit.position = Vector2(0, 0)
		select_hit.size = Vector2(card_w, 138)
		select_hit.flat = true
		select_hit.focus_mode = Control.FOCUS_NONE
		select_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		select_hit.pressed.connect(main._select_slot.bind(slot))
		card.add_child(select_hit)

		var num_col := TLRTheme.ACCENT_ORANGE if is_selected else TLRTheme.TEXT_PRIMARY
		TLRTheme.make_abs_label(card, "%02d" % (slot + 1), Rect2(22, 18, 64, 54), 44, num_col, true)

		var slot_eyebrow := "CHECKPOINT" if has_save else ("DAMAGED SAVE" if is_corrupt else "EMPTY SLOT")
		TLRTheme.make_abs_label(card, slot_eyebrow, Rect2(96, 20, 220, 20), 11, TLRTheme.TEXT_MUTED, true)

		var right_tag := "SELECTED" if is_selected else ("SELECT SLOT →" if has_save else "")
		var right_col := TLRTheme.ACCENT_ORANGE if is_selected else TLRTheme.TEXT_MUTED
		if not right_tag.is_empty():
			TLRTheme.make_abs_label(card, right_tag, Rect2(card_w - 150, 20, 128, 20), 11, right_col, true, HORIZONTAL_ALIGNMENT_RIGHT)

		if has_save:
			var f_idx := int(info.get("fight_index", 0))
			TLRTheme.make_abs_label(card, "FIGHT %d / 8" % (f_idx + 1), Rect2(96, 44, 360, 34), 28, TLRTheme.TEXT_PRIMARY, true)
			var seg := TLRTheme.UISegmentBar.new(8, f_idx + 1, TLRTheme.ACCENT_ORANGE if is_selected else TLRTheme.TEXT_PRIMARY)
			seg.position = Vector2(96, 92)
			seg.size = Vector2(368, 3)
			card.add_child(seg)
		elif is_corrupt:
			TLRTheme.make_abs_label(card, "UNAVAILABLE", Rect2(96, 44, 360, 34), 26, TLRTheme.AMBER, true)
			TLRTheme.make_abs_label(card, "Start a new run to overwrite or inspect.", Rect2(96, 84, 370, 22), 13, TLRTheme.TEXT_MUTED, false)
		else:
			TLRTheme.make_abs_label(card, "A NEW CONTENDER", Rect2(96, 44, 360, 34), 26, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(card, "Your first bell is waiting.", Rect2(96, 84, 360, 22), 13, TLRTheme.TEXT_MUTED, false)

		var div := ColorRect.new()
		div.position = Vector2(22, 138)
		div.size = Vector2(card_w - 44, 1)
		div.color = Color(0.16, 0.25, 0.35, 0.7)
		card.add_child(div)

		var action_lbl := "NEW RUN IN SLOT %d" % (slot + 1) if has_save else "START NEW RUN"
		var new_btn := TLRTheme.make_abs_button(card, action_lbl, Rect2(12, 144, card_w - 24, 46), main._request_new_run.bind(slot), "ghost", false, 13)
		new_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var arrow_col := TLRTheme.ACCENT_ORANGE if is_selected else (TLRTheme.TEXT_PRIMARY if not has_save else TLRTheme.TEXT_MUTED)
		new_btn.add_theme_color_override("font_color", TLRTheme.TEXT_PRIMARY if not has_save else TLRTheme.TEXT_MUTED)
		TLRTheme.make_abs_label(card, "↗", Rect2(card_w - 42, 154, 22, 26), 15, arrow_col, true, HORIZONTAL_ALIGNMENT_RIGHT)

	# Footer bar
	var foot_line := ColorRect.new()
	foot_line.position = Vector2(40, 816)
	foot_line.size = Vector2(1520, 1)
	foot_line.color = Color(0.14, 0.22, 0.31, 0.7)
	parent.add_child(foot_line)

	TLRTheme.make_abs_label(parent, "↑ ↓  SELECT SLOT       ↵  CONFIRM       A fight is a conversation. Make sure you get the last word.", Rect2(40, 836, 760, 28), 12, TLRTheme.TEXT_DIM, false)
	TLRTheme.make_abs_button(parent, "FIGHTER TRAINING", Rect2(960, 828, 170, 42), main._show_tutorial, "ghost", false, 14)
	TLRTheme.make_abs_button(parent, "CODEX", Rect2(1140, 828, 120, 42), main._show_codex, "ghost", false, 14)
	TLRTheme.make_abs_button(parent, "SETTINGS", Rect2(1270, 828, 130, 42), main._show_settings, "ghost", false, 14)
	TLRTheme.make_abs_button(parent, "QUIT GAME", Rect2(1410, 828, 150, 42), main._quit_game, "ghost", false, 14)

	if bool(main.animate_cards_enter):
		main.animate_cards_enter = false
		TLRTheme.stagger_enter(main, slot_cards, Vector2(0.0, 10.0), 0.16, 0.025)


# ---------------------------------------------------------
# 2. OVERWRITE CONFIRMATION (UI/R03 • Replace saved run.png)
# ---------------------------------------------------------

static func build_overwrite_confirm(main: Node, parent: Control, slot: int) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / RUN SETUP / SAVE SAFETY",
		"REPLACE THIS RUN?",
		"The existing checkpoint will be replaced only after you confirm."
	)

	var card := TLRTheme.make_panel(parent, Rect2(300, 224, 1000, 360), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	var info: Dictionary = main._slot_info(slot)
	var f_num := int(info.get("fight_index", 0)) + 1
	TLRTheme.make_abs_label(card, "SLOT %02d  /  CHECKPOINT  /  FIGHT %d OF 8" % [slot + 1, f_num], Rect2(36, 36, 920, 32), 24, TLRTheme.AMBER, true)
	TLRTheme.make_abs_label(card, "Your current run progress in this slot will be lost.\nYour career Respect and permanent perks are kept.\nThe other two slots will remain untouched.", Rect2(36, 96, 920, 96), 18, TLRTheme.TEXT_PRIMARY, false)

	TLRTheme.make_abs_button(card, "KEEP CHECKPOINT", Rect2(36, 252, 420, 56), main._show_main_menu, "default", false, 15)
	TLRTheme.make_abs_button(card, "REPLACE & CHOOSE STYLE", Rect2(480, 252, 480, 56), main._show_style_select.bind(slot), "teal", false, 15)

	TLRTheme.make_abs_button(parent, "MAIN MENU", Rect2(40, 814, 190, 46), main._show_main_menu, "default", false, 14)


static func build_style_select(main: Node, parent: Control) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / SLOT %02d SETUP" % (int(main.selected_slot) + 1),
		"CHOOSE YOUR FIGHTING STYLE",
		"Pick your corner background before the first bell. Every style changes your kit, stats, cash, and starting trait."
	)

	var styles: Array = main.STYLE_CATALOG
	var card_w := 368.0
	var card_h := 534.0
	var gap := 16.0
	var cards: Array = []

	for i in range(styles.size()):
		var st: Dictionary = styles[i]
		var s_id := str(st.get("id", "slugger"))
		var cx := 40.0 + float(i) * (card_w + gap)
		var is_wild := (s_id == "wildcard")
		var bg := TLRTheme.SURFACE_AMBER if is_wild else TLRTheme.SURFACE_SOLID
		var border := TLRTheme.BORDER_AMBER if is_wild else TLRTheme.BORDER_SUBTLE
		var card := TLRTheme.make_panel(parent, Rect2(cx, 174, card_w, card_h), bg, border, 2, 0, 0)
		cards.append(card)

		TLRTheme.make_abs_label(card, "KEY %d  •  %s" % [i + 1, str(st.get("tag", ""))], Rect2(24, 24, card_w - 48, 22), 13, TLRTheme.AMBER if is_wild else TLRTheme.CYAN, true)
		TLRTheme.make_abs_label(card, str(st.get("name", "")), Rect2(24, 60, card_w - 48, 66), 28, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(card, str(st.get("desc", "")), Rect2(24, 140, card_w - 48, 76), 16, TLRTheme.TEXT_MUTED, false)
		TLRTheme.make_abs_label(card, "STARTING STATS", Rect2(24, 232, card_w - 48, 20), 12, TLRTheme.TEXT_DIM, true)
		TLRTheme.make_abs_label(card, str(st.get("stats", "")), Rect2(24, 258, card_w - 48, 52), 14, TLRTheme.CYAN, true)
		TLRTheme.make_abs_label(card, "CORNER KIT & TRAIT", Rect2(24, 322, card_w - 48, 20), 12, TLRTheme.TEXT_DIM, true)
		TLRTheme.make_abs_label(card, str(st.get("kit", "")), Rect2(24, 348, card_w - 48, 92), 15, TLRTheme.MINT, false)

		TLRTheme.make_abs_button(card, "PLAY AS %s  →" % str(st.get("name", "")), Rect2(24, 460, card_w - 48, 48), main._start_story_run.bind(int(main.selected_slot), s_id), "orange" if is_wild else "teal", false, 14)

	TLRTheme.make_abs_button(parent, "BACK TO MENU", Rect2(40, 814, 210, 48), main._show_main_menu, "default", false, 14)
	if bool(main.animate_cards_enter):
		main.animate_cards_enter = false
		TLRTheme.stagger_enter(main, cards, Vector2(0.0, 20.0), 0.22, 0.04)


static func build_cutscene(main: Node, parent: Control, scene: Dictionary, beat_idx: int) -> Dictionary:
	var beats: Array = scene.get("beats", [])
	var total := maxi(1, beats.size())
	var idx := clampi(beat_idx, 0, total - 1)
	var beat: Dictionary = beats[idx] if idx < beats.size() else {}

	var acc_key := str(beat.get("accent", "cyan"))
	var acc_col := TLRTheme.CYAN
	match acc_key:
		"amber": acc_col = TLRTheme.AMBER
		"coral": acc_col = TLRTheme.CORAL
		"mint": acc_col = TLRTheme.MINT
		"violet": acc_col = Color(0.72, 0.56, 0.96)

	# Full-viewport transparent click catcher over the 3D arena
	var hit := Button.new()
	hit.position = Vector2(0, 96)
	hit.size = Vector2(1600, 576)
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.add_theme_stylebox_override("normal", TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))
	hit.add_theme_stylebox_override("hover", TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))
	hit.add_theme_stylebox_override("pressed", TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))
	hit.pressed.connect(main._advance_cutscene)
	parent.add_child(hit)

	# Top Widescreen Letterbox Bar
	var top_bar := TLRTheme.make_panel(parent, Rect2(0, 0, 1600, 96), Color(0.008, 0.014, 0.024, 0.96), TLRTheme.BORDER_SUBTLE, 0, 0, 0)
	var top_line := ColorRect.new()
	top_line.position = Vector2(0, 95)
	top_line.size = Vector2(1600, 1)
	top_line.color = Color(acc_col.r, acc_col.g, acc_col.b, 0.45)
	top_bar.add_child(top_line)

	TLRTheme.make_abs_label(top_bar, str(scene.get("eyebrow", "THE LAST ROUND // STORY")), Rect2(44, 16, 760, 22), 13, acc_col, true)
	TLRTheme.make_abs_label(top_bar, str(scene.get("title", "THE GLASS PIT")), Rect2(44, 42, 760, 36), 28, TLRTheme.TEXT_PRIMARY, true)

	# Beat progress pips
	var pip_w := 30.0
	var pip_gap := 8.0
	var pip_start_x := 1310.0 - float(total) * (pip_w + pip_gap)
	for pi in range(total):
		var pip := ColorRect.new()
		pip.position = Vector2(pip_start_x + float(pi) * (pip_w + pip_gap), 44)
		pip.size = Vector2(pip_w, 5)
		pip.color = acc_col if pi == idx else (Color(acc_col.r, acc_col.g, acc_col.b, 0.40) if pi < idx else Color(0.20, 0.28, 0.36, 0.55))
		top_bar.add_child(pip)
	TLRTheme.make_abs_label(top_bar, "%02d / %02d" % [idx + 1, total], Rect2(1180, 16, 130, 20), 12, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)
	TLRTheme.make_abs_button(top_bar, "SKIP SCENE  [ESC]", Rect2(1346, 26, 210, 44), main._skip_cutscene, "ghost", false, 13)

	# Bottom Widescreen Letterbox Dialogue Bar
	var bot_bar := TLRTheme.make_panel(parent, Rect2(0, 672, 1600, 228), Color(0.008, 0.014, 0.024, 0.96), TLRTheme.BORDER_SUBTLE, 0, 0, 0)
	var bot_line := ColorRect.new()
	bot_line.position = Vector2(0, 0)
	bot_line.size = Vector2(1600, 2)
	bot_line.color = Color(acc_col.r, acc_col.g, acc_col.b, 0.60)
	bot_bar.add_child(bot_line)

	var stripe := ColorRect.new()
	stripe.position = Vector2(44, 26)
	stripe.size = Vector2(5, 168)
	stripe.color = acc_col
	bot_bar.add_child(stripe)

	TLRTheme.make_abs_label(bot_bar, str(beat.get("speaker", "THE VOICE")), Rect2(68, 22, 620, 32), 22, acc_col, true)
	TLRTheme.make_abs_label(bot_bar, str(beat.get("role", "")), Rect2(700, 26, 520, 24), 13, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)

	var body_lbl := TLRTheme.make_abs_label(bot_bar, str(beat.get("line", "")), Rect2(68, 62, 1140, 132), 22, TLRTheme.TEXT_PRIMARY, false)
	body_lbl.visible_characters = 0

	if idx > 0:
		TLRTheme.make_abs_button(bot_bar, "←  PREV", Rect2(1248, 146, 116, 46), main._prev_cutscene_beat, "default", false, 13)
	var is_last := idx >= total - 1
	var next_caption := "BEGIN  →" if is_last else "NEXT  →"
	var next_btn := TLRTheme.make_abs_button(bot_bar, next_caption, Rect2(1378, 146, 178, 46), main._advance_cutscene, "teal" if not is_last else "orange", false, 14)
	TLRTheme.make_abs_label(bot_bar, "SPACE / CLICK TO CONTINUE", Rect2(1248, 112, 308, 22), 11, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)

	return {"text_label": body_lbl, "next_btn": next_btn, "is_last": is_last}


# ---------------------------------------------------------
# 3. HUB / YOUR CORNER (UI/R05, R17, R18)
# ---------------------------------------------------------

static func build_hub(main: Node, parent: Control) -> void:
	var cleared := int(main.fight_index)
	var title := "BEFORE THE FIRST BELL" if cleared == 0 else ("%s CLEARED. %s TO GO." % [_word_num(cleared), _word_num(8 - cleared)])
	var next_name: String = str(main._next_opponent_name())
	var act_info := TLRStory.hub_act_banner(cleared, next_name, str(main._boss_name()), str(main.player_style))
	var eyebrow := str(act_info.get("eyebrow", "THE LAST ROUND / YOUR CORNER"))
	var subtitle := str(act_info.get("sub", "Prepare for %s." % next_name))

	TLRTheme.add_page_header(parent, eyebrow, title, subtitle)

	if not str(main.hub_notice).is_empty():
		var notice_p := TLRTheme.make_panel(parent, Rect2(1040, 46, 520, 46), TLRTheme.SURFACE_TEAL, TLRTheme.BORDER_TEAL, 1, 0, 0)
		TLRTheme.make_abs_label(notice_p, str(main.hub_notice), Rect2(14, 8, 492, 30), 13, TLRTheme.MINT, true, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		main.hub_notice = ""

	# 8-Tile Horizontal Bracket with connecting lines
	var tile_w := 176.0
	var tile_gap := 16.0
	for i in range(8):
		var tx := 40.0 + float(i) * (tile_w + tile_gap)
		var is_cleared := i < cleared
		var is_next := i == cleared
		if i < 7:
			var conn := ColorRect.new()
			conn.position = Vector2(tx + tile_w, 205.0)
			conn.size = Vector2(tile_gap, 2.0)
			conn.color = TLRTheme.MINT if is_cleared else (TLRTheme.BORDER_TEAL if is_next else TLRTheme.BORDER_SUBTLE)
			parent.add_child(conn)
		var b_bg := TLRTheme.SURFACE_TEAL if is_next else (Color(0.042, 0.095, 0.098, 0.92) if is_cleared else TLRTheme.SURFACE_DARK)
		var b_col := TLRTheme.BORDER_TEAL if is_next else (Color(0.22, 0.56, 0.48, 0.85) if is_cleared else TLRTheme.BORDER_SUBTLE)
		var tile := TLRTheme.make_panel(parent, Rect2(tx, 152, tile_w, 108), b_bg, b_col, 2 if is_next else 1, 0, 0)
		var num_col := TLRTheme.MINT if is_cleared else (TLRTheme.CYAN if is_next else TLRTheme.TEXT_MUTED)
		TLRTheme.make_abs_label(tile, "%02d" % (i + 1), Rect2(14, 12, 80, 36), 30, num_col, true)
		var r_idx: int = main._opponent_template_index(i)
		var opp_short := "OPPONENT"
		if r_idx >= 0 and r_idx < main.enemy_templates.size():
			opp_short = str(main.enemy_templates[r_idx].get("name", "Fighter"))
		var status_str := "CLEARED ✓" if is_cleared else ("NEXT FIGHT" if is_next else "LOCKED")
		var status_col := TLRTheme.MINT if is_cleared else (TLRTheme.CYAN if is_next else TLRTheme.TEXT_DIM)
		TLRTheme.make_abs_label(tile, opp_short.to_upper(), Rect2(14, 52, tile_w - 28, 22), 11, TLRTheme.TEXT_MUTED, true)
		TLRTheme.make_abs_label(tile, status_str, Rect2(14, 76, tile_w - 28, 22), 12, status_col, true)

	# 3-Column Grid
	var col_w := 496.0
	var col_y := 278.0
	var col_h := 508.0

	# Column 1: NEXT OPPONENT
	var c1 := TLRTheme.make_panel(parent, Rect2(40, col_y, col_w, col_h), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(c1, "NEXT OPPONENT", Rect2(24, 20, 210, 24), 16, TLRTheme.CYAN, true)
	var cur_branch: int = int(main.bout_branches[cleared]) if cleared < main.bout_branches.size() else 0
	TLRTheme.make_abs_button(c1, "CARD A", Rect2(256, 16, 104, 28), main._select_bout_branch.bind(0), "teal" if cur_branch == 0 else "default", false, 11)
	TLRTheme.make_abs_button(c1, "CARD B", Rect2(368, 16, 104, 28), main._select_bout_branch.bind(1), "teal" if cur_branch == 1 else "default", false, 11)
	TLRTheme.make_abs_label(c1, next_name.to_upper(), Rect2(24, 58, 260, 120), 32, TLRTheme.TEXT_PRIMARY, true)

	var opp_visual: Dictionary = {}
	var preview_idx: int = main._opponent_template_index(cleared)
	if preview_idx >= 0 and preview_idx < main.enemy_templates.size():
		var upcoming: Dictionary = main.enemy_templates[preview_idx]
		opp_visual = upcoming.get("visual", {})
		var v_scale := 1.0 + float(cleared) * 0.115
		var opp_hp := int(float(upcoming.get("health", 100.0)) * v_scale)
		var opp_sta := int(float(upcoming.get("stamina", 100.0)) * v_scale)
		var opp_dmg := int(float(upcoming.get("damage", 10.0)) * (1.0 + cleared * 0.07))
		var opp_def := int(float(upcoming.get("defence", 5.0)) + cleared * 0.7)
		var opp_spd := int(main._speed_chance(float(upcoming.get("speed", 10.0)) + cleared * 1.2 + float(main.event_enemy_speed_buff)))
		var b_tag := str(main._current_bout_bounty())
		var b_lbl := str(main._bounty_label(b_tag))
		TLRTheme.make_abs_label(c1, "%s  •  %s" % [str(upcoming.get("archetype", "BOXER")).to_upper(), b_lbl], Rect2(24, 184, 260, 22), 11, TLRTheme.MINT if b_tag in ["rare_item", "trait_drop"] else TLRTheme.AMBER, true)
		TLRTheme.make_abs_label(c1, "%d HP / %d STA" % [opp_hp, opp_sta], Rect2(24, 212, 260, 22), 14, TLRTheme.TEXT_MUTED, false)
		TLRTheme.make_abs_label(c1, "DMG %d   DEF %d   SPD %d%%" % [opp_dmg, opp_def, opp_spd], Rect2(24, 236, 260, 22), 14, TLRTheme.TEXT_MUTED, false)
		var mod: Dictionary = main._bout_modifier_for_fight(cleared)
		var mod_line := "RULE — %s: %s" % [str(mod.get("name", "Standard")).to_upper(), str(mod.get("desc", ""))]
		TLRTheme.make_abs_label(c1, str(upcoming.get("tell", "")) + "\n" + str(main._next_opponent_scouting_note()) + "\n" + mod_line, Rect2(24, 262, 448, 96), 13, TLRTheme.TEXT_PRIMARY, false)

	var boxer_preview := TLRBoxerPreview.new(Rect2(290, 48, 184, 210), _opponent_color_for_fight(cleared), "heavy" if cleared == 0 else "idle", true, false, opp_visual)
	c1.add_child(boxer_preview)
	var contract: Dictionary = main._contract_for_fight(cleared)
	if not contract.is_empty():
		var c_on := bool(main.contract_accepted)
		var c_bonus := int(contract.get("bonus", contract.get("reward", 0)))
		var c_box := TLRTheme.make_panel(c1, Rect2(24, 364, 448, 60), TLRTheme.SURFACE_TEAL if c_on else TLRTheme.SURFACE_AMBER, TLRTheme.BORDER_TEAL if c_on else TLRTheme.BORDER_AMBER, 2, 0, 0)
		var c_head := ("ACTIVE CONTRACT: %s  (+$%d)  ✓" % [str(contract.get("name", "")).to_upper(), c_bonus]) if c_on else ("SIDE CONTRACT: %s  (+$%d)  •  CLICK TO ACCEPT" % [str(contract.get("name", "")).to_upper(), c_bonus])
		TLRTheme.make_abs_label(c_box, c_head, Rect2(14, 6, 420, 22), 12, TLRTheme.CYAN if c_on else TLRTheme.AMBER, true)
		TLRTheme.make_abs_label(c_box, str(contract.get("desc", "")), Rect2(14, 30, 420, 22), 12, TLRTheme.TEXT_PRIMARY, false)
		var c_hit := Button.new()
		c_hit.position = Vector2.ZERO
		c_hit.size = Vector2(448, 60)
		c_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		c_hit.add_theme_stylebox_override("normal", TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))
		c_hit.add_theme_stylebox_override("hover", TLRTheme.style_box(Color(0.20, 0.45, 0.55, 0.16), TLRTheme.BORDER_HOVER, 2, 0, 0, 0))
		c_hit.add_theme_stylebox_override("focus", TLRTheme.style_box(Color(0.20, 0.45, 0.55, 0.16), TLRTheme.BORDER_TEAL, 2, 0, 0, 0))
		c_hit.pressed.connect(main._toggle_hub_contract)
		c_box.add_child(c_hit)
	TLRTheme.make_abs_button(c1, "STUDY BODY LANGUAGE  →", Rect2(24, 434, 448, 48), main._show_telegraph_practice, "default", false, 14)

	# Column 2: YOUR FIGHTER
	var c2 := TLRTheme.make_panel(parent, Rect2(40 + col_w + 16, col_y, col_w, col_h), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(c2, "YOUR FIGHTER", Rect2(24, 20, 300, 24), 16, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(c2, "%d / %d HP     %d / %d STA" % [int(main.player.health), int(main.player.max_health), int(main.player.stamina), int(main.player.max_stamina)], Rect2(24, 54, 448, 28), 20, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(c2, "DMG %d    DEF %d    SPD %d%%" % [int(main.player.damage), int(main.player.defence), int(main._speed_chance(main.player.speed))], Rect2(24, 88, 448, 22), 14, TLRTheme.TEXT_MUTED, false)

	var max_slots := 4 + int(main.passive.get("slots", 0))
	TLRTheme.make_abs_label(c2, "MOVES (%d / %d SLOTS)" % [main.owned_moves.size(), max_slots], Rect2(24, 120, 300, 20), 12, TLRTheme.TEXT_DIM, true)

	var m_w := 142.0
	var m_h := 140.0
	for slot in range(6):
		var col := slot % 3
		var row := slot / 3
		var mx := 24.0 + float(col) * (m_w + 11.0)
		var my := 148.0 + float(row) * (m_h + 10.0)
		var m_id := str(main.owned_moves[slot]) if slot < main.owned_moves.size() else ""
		var m_card := TLRTheme.make_panel(c2, Rect2(mx, my, m_w, m_h), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
		if m_id.is_empty():
			var slot_lbl := "OPEN SLOT" if slot < max_slots else "LOCKED SLOT"
			TLRTheme.make_abs_label(m_card, slot_lbl, Rect2(10, 56, m_w - 20, 24), 12, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var md: Dictionary = main._get_move(m_id)
			var m_lv: int = main._move_level(m_id)
			var m_cost: int = int(main._effective_move_cost(md))
			var icon := TLRTheme.UIIcon.new(m_id, TLRTheme.TEXT_PRIMARY, Vector2(22, 22))
			icon.position = Vector2(12, 12)
			m_card.add_child(icon)
			var cost_txt := ("%d STA" % m_cost) if m_lv <= 1 else ("LV.%d · %d STA" % [m_lv, m_cost])
			TLRTheme.make_abs_label(m_card, cost_txt, Rect2(44, 14, m_w - 56, 20), 10 if m_lv > 1 else 11, TLRTheme.AMBER if m_lv > 1 else TLRTheme.BLUE, true, HORIZONTAL_ALIGNMENT_RIGHT)
			TLRTheme.make_abs_label(m_card, str(md.get("name", m_id)).to_upper(), Rect2(12, 68, m_w - 24, 28), 17, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(m_card, _move_short_hint(m_id, md), Rect2(12, 98, m_w - 24, 34), 12, TLRTheme.TEXT_MUTED, false)
			m_card.tooltip_text = main._move_reward_details(md)

	var p_names: Array[String] = []
	for pid in main.owned_perks:
		p_names.append(str(main._get_perk_data(str(pid)).get("name", pid)).to_upper())
	var traits_line := "TRAITS (%d/%d): %s" % [main.owned_perks.size(), int(main.PERK_MAX), (" · ".join(p_names) if not p_names.is_empty() else "NONE YET")]
	TLRTheme.make_abs_label(c2, traits_line, Rect2(24, 456, 448, 38), 12, TLRTheme.AMBER if not p_names.is_empty() else TLRTheme.TEXT_DIM, true)

	# Column 3: CORNER BAG, MARKET & RESPECT
	var c3 := TLRTheme.make_panel(parent, Rect2(40 + (col_w + 16) * 2, col_y, col_w, col_h), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 2, 0, 0)
	TLRTheme.make_abs_label(c3, "CORNER BAG / %d OF 3" % main.inventory.size(), Rect2(24, 20, 260, 24), 16, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(c3, "PIT CASH: $%d" % int(main.cash), Rect2(270, 20, 202, 24), 15, TLRTheme.AMBER, true, HORIZONTAL_ALIGNMENT_RIGHT)

	var sel_item_slot: int = clampi(int(main.selected_hub_item_slot), 0, maxi(0, main.inventory.size() - 1))
	var i_w := 142.0
	var i_h := 120.0
	for slot in range(3):
		var ix := 24.0 + float(slot) * (i_w + 11.0)
		var item_id := str(main.inventory[slot]) if slot < main.inventory.size() else ""
		var is_sel_item: bool = (not item_id.is_empty() and slot == sel_item_slot)
		var it_rar: String = str(main._get_item_rarity(item_id)) if not item_id.is_empty() else "common"
		var rmeta: Dictionary = TLRTheme.rarity_meta(it_rar)
		var i_bg: Color = TLRTheme.SURFACE_TEAL if is_sel_item else (rmeta.bg if it_rar != "common" else TLRTheme.SURFACE_DARK)
		var i_border: Color = TLRTheme.BORDER_TEAL if is_sel_item else (rmeta.border if (not item_id.is_empty() and it_rar != "common") else TLRTheme.BORDER_SUBTLE)
		var i_card := TLRTheme.make_panel(c3, Rect2(ix, 54, i_w, i_h), i_bg, i_border, 2, 0, 0)
		if item_id.is_empty():
			TLRTheme.make_abs_label(i_card, "EMPTY", Rect2(10, 46, i_w - 20, 24), 12, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var icon := TLRTheme.UIIcon.new(item_id, Color(rmeta.color) if it_rar != "common" else TLRTheme.TEXT_PRIMARY, Vector2(20, 20))
			icon.position = Vector2(12, 10)
			i_card.add_child(icon)
			var tag_txt := "SELECTED" if is_sel_item else str(rmeta.label)
			TLRTheme.make_abs_label(i_card, tag_txt, Rect2(44, 12, i_w - 56, 18), 9 if not is_sel_item else 10, TLRTheme.CYAN if is_sel_item else Color(rmeta.color), true, HORIZONTAL_ALIGNMENT_RIGHT)
			TLRTheme.make_abs_label(i_card, str(main._get_item_name(item_id)).to_upper(), Rect2(12, 40, i_w - 24, 36), 13, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(i_card, _item_short_hint(item_id), Rect2(12, 84, i_w - 24, 28), 11, TLRTheme.TEXT_MUTED, false)
			var idata: Dictionary = main._get_item_data(item_id)
			i_card.tooltip_text = "[%s] " % str(rmeta.label) + str(idata.get("description", "")) + "\n" + str(main._item_timing(item_id))
			var hit := Button.new()
			hit.position = Vector2.ZERO
			hit.size = Vector2(i_w, i_h)
			hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			hit.add_theme_stylebox_override("normal", TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))
			hit.add_theme_stylebox_override("hover", TLRTheme.style_box(Color(0.14, 0.36, 0.46, 0.14), TLRTheme.BORDER_HOVER, 2, 0, 0, 0))
			hit.add_theme_stylebox_override("focus", TLRTheme.style_box(Color(0.14, 0.36, 0.46, 0.14), TLRTheme.BORDER_TEAL, 2, 0, 0, 0))
			hit.add_theme_stylebox_override("pressed", TLRTheme.style_box(Color(0.08, 0.25, 0.32, 0.22), TLRTheme.BORDER_TEAL, 2, 0, 0, 0))
			hit.pressed.connect(main._select_hub_item_slot.bind(slot))
			i_card.add_child(hit)

	var sel_id := str(main.inventory[sel_item_slot]) if not main.inventory.is_empty() and sel_item_slot < main.inventory.size() else ""
	var has_between_heal: bool = main.inventory.has("ice") or main.inventory.has("sparring_tonics")
	var btn_label := "NO BETWEEN-FIGHT HEAL"
	var btn_cb: Callable = Callable()
	var btn_disabled := true
	if sel_id == "ice":
		btn_label = "USE CORNER ICE (+22 HP)"
		btn_cb = main._use_hub_item_slot.bind(sel_item_slot)
		btn_disabled = false
	elif sel_id == "sparring_tonics":
		btn_label = "DRINK TONIC (+12 MAX HP & +18 HP)"
		btn_cb = main._use_hub_item_slot.bind(sel_item_slot)
		btn_disabled = false
	elif not sel_id.is_empty():
		var sel_name := str(main._get_item_name(sel_id)).to_upper()
		btn_label = ("%s — AUTO ON KO" if sel_id == "salts" else "%s — USE IN COMBAT") % sel_name
		if has_between_heal:
			btn_label = "USE CORNER ICE / TONIC NOW"
			btn_cb = main._use_heal_between
			btn_disabled = false
	TLRTheme.make_abs_button(c3, btn_label, Rect2(24, 184, 448, 40), btn_cb, "teal" if not btn_disabled else "default", btn_disabled, 13)

	var salts_text := "LAST STAND — SPENT" if main.revive_used else ("LAST STAND — READY (+30 HP)" if main.inventory.has("salts") else "LAST STAND — NOT IN BAG")
	var salts_col := TLRTheme.AMBER if main.revive_used else (TLRTheme.MINT if main.inventory.has("salts") else TLRTheme.TEXT_MUTED)
	TLRTheme.make_abs_label(c3, salts_text, Rect2(24, 230, 448, 20), 12, salts_col, true)

	TLRTheme.make_abs_button(c3, "BLACK MARKET  ($%d)  →" % int(main.cash), Rect2(24, 258, 218, 52), main._open_shop, "teal", false, 12)
	var ev_done: bool = bool(main.hub_event_done)
	var ev_title: String = str(main.current_hub_event.get("title", "STREET EVENT")).to_upper()
	var ev_lbl := "EVENT CLEARED ✓" if ev_done else "STREET EVENT  →"
	var ev_btn := TLRTheme.make_abs_button(c3, ev_lbl, Rect2(254, 258, 218, 52), main._open_hub_event, "default" if ev_done else "orange", ev_done, 12)
	ev_btn.clip_text = true
	if not ev_done:
		ev_btn.tooltip_text = "Street Encounter: " + ev_title

	var total_respect := int(main.lifetime_respect) + int(main.respect)
	var milestone := _next_milestone(total_respect)
	var m_target := int(milestone.target)
	TLRTheme.make_abs_label(c3, "RUN RESPECT: +%d   |   CAREER: %d / %d — %s" % [int(main.respect), total_respect, m_target, str(milestone.label)], Rect2(24, 330, 448, 22), 13, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.add_progress_bar(c3, Rect2(24, 360, 448, 6), float(total_respect), float(m_target), TLRTheme.MINT)
	TLRTheme.make_abs_label(c3, str(main._career_perk_summary()), Rect2(24, 376, 448, 44), 12, TLRTheme.TEXT_MUTED, false)
	if float(main.next_fight_speed_bonus) > 0.0 or float(main.passive.get("wind", 0.0)) > 0.0:
		var bonus_txt := ""
		if float(main.next_fight_speed_bonus) > 0.0:
			bonus_txt += "+%d%% Speed next fight  " % int(main.next_fight_speed_bonus)
		if float(main.passive.get("wind", 0.0)) > 0.0:
			bonus_txt += "+%d STA on dodge" % int(main.passive.get("wind", 0.0))
		TLRTheme.make_abs_label(c3, "ACTIVE: " + bonus_txt, Rect2(24, 434, 448, 22), 12, TLRTheme.MINT, true)

	# Bottom Nav
	TLRTheme.make_abs_button(parent, "MAIN MENU", Rect2(40, 814, 170, 46), main._show_main_menu, "default", false, 14)
	TLRTheme.make_abs_button(parent, "SAVE RUN", Rect2(226, 814, 160, 46), main._save_run, "default", false, 14)
	TLRTheme.make_abs_button(parent, "CODEX", Rect2(402, 814, 130, 46), main._show_codex, "default", false, 14)
	TLRTheme.make_abs_button(parent, "BLACK MARKET  [B]", Rect2(548, 814, 210, 46), main._open_shop, "default", false, 13)
	TLRTheme.make_abs_button(parent, "ENTER THE RING  →", Rect2(1140, 814, 420, 46), main._enter_next_bout, "teal", false, 16)

	TLRTheme.stagger_enter(main, [c1, c2, c3], Vector2(0.0, 22.0), 0.25, 0.055)


static func build_shop(main: Node, parent: Control) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / PIT BLACK MARKET",
		"STOCK UP BEFORE THE BELL",
		"Pit Cash: $%d  •  Buy rare gear, traits & technique manuals, or sell items at 50%% to make room." % int(main.cash)
	)
	if not str(main.hub_notice).is_empty():
		var notice_p := TLRTheme.make_panel(parent, Rect2(1040, 46, 520, 46), TLRTheme.SURFACE_TEAL, TLRTheme.BORDER_TEAL, 1, 0, 0)
		TLRTheme.make_abs_label(notice_p, str(main.hub_notice), Rect2(14, 8, 492, 30), 13, TLRTheme.MINT, true, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		main.hub_notice = ""

	var cw := 290.0
	var ch := 312.0
	var gap := 17.5
	var stock_cards: Array = []

	# Row 1 Slots 0..2: Consumable Items with Rarity
	var items_arr: Array = main.shop_stock.get("items", [])
	var bag_full: bool = int(main.inventory.size()) >= 3
	for si in range(3):
		var sx := 40.0 + float(si) * (cw + gap)
		var entry: Dictionary = items_arr[si] if si < items_arr.size() else {}
		var item_id := str(entry.get("id", ""))
		var rarity := str(entry.get("rarity", "common"))
		var rmeta: Dictionary = TLRTheme.rarity_meta(rarity)
		var is_sold: bool = bool(entry.get("sold", false)) or item_id.is_empty()
		var price := int(entry.get("price", 20))
		var card := TLRTheme.make_panel(parent, Rect2(sx, 168, cw, ch), rmeta.bg if not is_sold else TLRTheme.SURFACE_DARK, rmeta.border if not is_sold else TLRTheme.BORDER_CARD, 2, 0, 0)
		stock_cards.append(card)
		if is_sold:
			TLRTheme.make_abs_label(card, "SOLD OUT", Rect2(20, 132, cw - 40, 32), 20, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var idata: Dictionary = main._get_item_data(item_id)
			TLRTheme.make_abs_label(card, "%s ITEM" % str(rmeta.label), Rect2(20, 18, cw - 100, 20), 11, Color(rmeta.color), true)
			TLRTheme.make_abs_label(card, "$%d" % price, Rect2(cw - 88, 16, 68, 24), 16, TLRTheme.AMBER, true, HORIZONTAL_ALIGNMENT_RIGHT)
			var ic := TLRTheme.UIIcon.new(item_id, Color(rmeta.color), Vector2(26, 26))
			ic.position = Vector2(20, 48)
			card.add_child(ic)
			TLRTheme.make_abs_label(card, str(main._get_item_name(item_id)).to_upper(), Rect2(20, 90, cw - 40, 44), 20, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(card, str(idata.get("description", "")), Rect2(20, 144, cw - 40, 62), 13, TLRTheme.TEXT_PRIMARY, false)
			TLRTheme.make_abs_label(card, main._item_timing(item_id), Rect2(20, 208, cw - 40, 38), 11, TLRTheme.TEXT_MUTED, false)
			var can_buy: bool = not bag_full and int(main.cash) >= price
			var b_lbl := "BAG FULL (3/3)" if bag_full else ("BUY  $%d" % price)
			TLRTheme.make_abs_button(card, b_lbl, Rect2(20, 250, cw - 40, 44), main._shop_buy_item.bind(si), "teal" if can_buy else "default", not can_buy, 13)

	# Slot 3: Trait Stock
	var pk_entry: Dictionary = main.shop_stock.get("perk", {})
	var pk_id := str(pk_entry.get("id", ""))
	var pk_sold: bool = pk_entry.is_empty() or bool(pk_entry.get("sold", false)) or pk_id.is_empty()
	var pk_rar := str(pk_entry.get("rarity", "rare"))
	var pk_rm: Dictionary = TLRTheme.rarity_meta(pk_rar)
	var pk_card := TLRTheme.make_panel(parent, Rect2(40.0 + 3.0 * (cw + gap), 168, cw, ch), pk_rm.bg if not pk_sold else TLRTheme.SURFACE_DARK, pk_rm.border if not pk_sold else TLRTheme.BORDER_CARD, 2, 0, 0)
	stock_cards.append(pk_card)
	if pk_sold:
		TLRTheme.make_abs_label(pk_card, "TRAIT SOLD", Rect2(20, 132, cw - 40, 32), 20, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var pd: Dictionary = main._get_perk_data(pk_id)
		var p_cost := int(pk_entry.get("price", 44))
		var p_full: bool = int(main.owned_perks.size()) >= int(main.PERK_MAX)
		TLRTheme.make_abs_label(pk_card, "%s TRAIT" % str(pk_rm.label), Rect2(20, 18, cw - 100, 20), 11, Color(pk_rm.color), true)
		TLRTheme.make_abs_label(pk_card, "$%d" % p_cost, Rect2(cw - 88, 16, 68, 24), 16, TLRTheme.AMBER, true, HORIZONTAL_ALIGNMENT_RIGHT)
		var pic := TLRTheme.UIIcon.new("perk", Color(pk_rm.color), Vector2(26, 26))
		pic.position = Vector2(20, 48)
		pk_card.add_child(pic)
		TLRTheme.make_abs_label(pk_card, str(pd.get("name", pk_id)).to_upper(), Rect2(20, 90, cw - 40, 44), 20, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(pk_card, str(pd.get("desc", "")), Rect2(20, 144, cw - 40, 88), 13, TLRTheme.TEXT_PRIMARY, false)
		var can_perk: bool = not p_full and int(main.cash) >= p_cost
		TLRTheme.make_abs_button(pk_card, "TRAITS FULL" if p_full else ("BUY TRAIT  $%d" % p_cost), Rect2(20, 250, cw - 40, 44), main._shop_buy_perk, "teal" if can_perk else "default", not can_perk, 13)

	# Slot 4: Technique / Mastery Manual
	var mo_entry: Dictionary = main.shop_stock.get("move", {})
	var mo_id := str(mo_entry.get("id", ""))
	var mo_sold: bool = mo_entry.is_empty() or bool(mo_entry.get("sold", false)) or mo_id.is_empty()
	var mo_card := TLRTheme.make_panel(parent, Rect2(40.0 + 4.0 * (cw + gap), 168, cw, ch), TLRTheme.SURFACE_SOLID if not mo_sold else TLRTheme.SURFACE_DARK, TLRTheme.BORDER_SUBTLE if not mo_sold else TLRTheme.BORDER_CARD, 2, 0, 0)
	stock_cards.append(mo_card)
	if mo_sold:
		TLRTheme.make_abs_label(mo_card, "MANUAL SOLD", Rect2(20, 132, cw - 40, 32), 20, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var md: Dictionary = main._get_move(mo_id)
		var m_cost := int(mo_entry.get("price", 42))
		var is_upg: bool = bool(mo_entry.get("is_upgrade", false))
		var next_lv: int = int(main._move_level(mo_id)) + 1
		TLRTheme.make_abs_label(mo_card, ("MASTERY -> LV.%d" % next_lv) if is_upg else "NEW TECHNIQUE", Rect2(20, 18, cw - 100, 20), 11, TLRTheme.CYAN, true)
		TLRTheme.make_abs_label(mo_card, "$%d" % m_cost, Rect2(cw - 88, 16, 68, 24), 16, TLRTheme.AMBER, true, HORIZONTAL_ALIGNMENT_RIGHT)
		var mic := TLRTheme.UIIcon.new(mo_id, TLRTheme.CYAN, Vector2(26, 26))
		mic.position = Vector2(20, 48)
		mo_card.add_child(mic)
		TLRTheme.make_abs_label(mo_card, str(md.get("name", mo_id)).to_upper(), Rect2(20, 90, cw - 40, 44), 20, TLRTheme.TEXT_PRIMARY, true)
		var m_body := ("+22%% power, -1 STA & +1 Base DMG." if is_upg else str(md.get("description", "")))
		TLRTheme.make_abs_label(mo_card, m_body, Rect2(20, 144, cw - 40, 62), 13, TLRTheme.TEXT_PRIMARY, false)
		TLRTheme.make_abs_label(mo_card, "%d STA  •  %d%% ACC" % [int(main._effective_move_cost(md)), int(md.get("accuracy", 100))], Rect2(20, 212, cw - 40, 24), 11, TLRTheme.BLUE, true)
		var can_mo: bool = int(main.cash) >= m_cost
		TLRTheme.make_abs_button(mo_card, ("UPGRADE  $%d" if is_upg else "LEARN  $%d") % m_cost, Rect2(20, 250, cw - 40, 44), main._shop_buy_move, "teal" if can_mo else "default", not can_mo, 13)

	# Bottom Row Left: Corner Services
	var svc_panel := TLRTheme.make_panel(parent, Rect2(40, 502, 748, 276), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(svc_panel, "CORNER SERVICES (1 EACH PER BOUT)", Rect2(24, 18, 420, 22), 14, TLRTheme.AMBER, true)
	var services := [
		{"id": "heal", "title": "CUTMAN STITCH", "desc": "Restore +25 HP immediately.", "cost": 20, "dis": bool(main.shop_bought_flags.get("heal", false)) or float(main.player.health) >= float(main.player.max_health) or int(main.cash) < 20},
		{"id": "train", "title": "HEAVY BAG DRILL", "desc": "+2 Permanent Base Damage.", "cost": 35, "dis": bool(main.shop_bought_flags.get("train", false)) or int(main.cash) < 35},
		{"id": "sta", "title": "ROADWORK PREP", "desc": "+12 Max Stamina & +12 STA.", "cost": 26, "dis": bool(main.shop_bought_flags.get("sta", false)) or int(main.cash) < 26}
	]
	for si in range(services.size()):
		var sv: Dictionary = services[si]
		var scard := TLRTheme.make_panel(svc_panel, Rect2(24.0 + float(si) * 238.0, 54, 224, 198), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_CARD, 1, 0, 0)
		var bought_sv: bool = bool(main.shop_bought_flags.get(str(sv.id), false))
		TLRTheme.make_abs_label(scard, str(sv.title), Rect2(14, 16, 196, 36), 16, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(scard, str(sv.desc), Rect2(14, 62, 196, 56), 13, TLRTheme.TEXT_MUTED, false)
		TLRTheme.make_abs_button(scard, "DONE ✓" if bought_sv else ("BUY  $%d" % int(sv.cost)), Rect2(14, 138, 196, 44), main._shop_buy_service.bind(str(sv.id)), "teal" if not bool(sv.dis) else "default", bool(sv.dis), 13)

	# Bottom Row Right: Your Bag (Sell at 50% Value)
	var bag_panel := TLRTheme.make_panel(parent, Rect2(812, 502, 748, 276), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(bag_panel, "YOUR CORNER BAG (%d / 3 SLOTS — SELL AT 50%% VALUE)" % main.inventory.size(), Rect2(24, 18, 660, 22), 14, TLRTheme.CYAN, true)
	for bslot in range(3):
		var bx := 24.0 + float(bslot) * 238.0
		var b_id := str(main.inventory[bslot]) if bslot < main.inventory.size() else ""
		var brar: String = str(main._get_item_rarity(b_id)) if not b_id.is_empty() else "common"
		var brm: Dictionary = TLRTheme.rarity_meta(brar)
		var bcard := TLRTheme.make_panel(bag_panel, Rect2(bx, 54, 224, 198), brm.bg if (not b_id.is_empty() and brar != "common") else TLRTheme.SURFACE_DARK, brm.border if (not b_id.is_empty() and brar != "common") else TLRTheme.BORDER_CARD, 1, 0, 0)
		if b_id.is_empty():
			TLRTheme.make_abs_label(bcard, "EMPTY SLOT", Rect2(14, 86, 196, 24), 13, TLRTheme.TEXT_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var bdata: Dictionary = main._get_item_data(b_id)
			var refund := maxi(8, int(roundf(float(bdata.get("price", 18)) * 0.5)))
			TLRTheme.make_abs_label(bcard, str(brm.label), Rect2(14, 14, 196, 18), 10, Color(brm.color), true)
			TLRTheme.make_abs_label(bcard, str(main._get_item_name(b_id)).to_upper(), Rect2(14, 38, 196, 40), 15, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(bcard, _item_short_hint(b_id), Rect2(14, 86, 196, 36), 12, TLRTheme.TEXT_MUTED, false)
			TLRTheme.make_abs_button(bcard, "SELL  +$%d" % refund, Rect2(14, 138, 196, 44), main._shop_sell_bag_item.bind(bslot), "default", false, 13)

	TLRTheme.make_abs_label(parent, "CASH: $%d   •   HP: %d / %d   •   STA: %d / %d   •   DMG: %d" % [int(main.cash), int(main.player.health), int(main.player.max_health), int(main.player.stamina), int(main.player.max_stamina), int(main.player.damage)], Rect2(40, 822, 740, 28), 14, TLRTheme.AMBER, true)
	TLRTheme.make_abs_button(parent, "REROLL SHOP ($15)", Rect2(820, 814, 260, 48), main._reroll_shop, "default", int(main.cash) < 15, 14)
	TLRTheme.make_abs_button(parent, "BACK TO YOUR CORNER  →", Rect2(1100, 814, 460, 48), main._show_bracket, "teal", false, 15)


static func build_event(main: Node, parent: Control, event_data: Dictionary) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / STREET ENCOUNTER",
		str(event_data.get("title", "BACK-ALLEY EVENT")),
		str(event_data.get("desc", ""))
	)
	var choices: Array = event_data.get("choices", [])
	var cards: Array = []
	for i in range(mini(3, choices.size())):
		var ch: Dictionary = choices[i]
		var card := TLRTheme.make_panel(parent, Rect2(40.0 + float(i) * 512.0, 214, 496, 380), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 2, 0, 0)
		cards.append(card)
		var cost_cash: int = int(ch.get("cost_cash", 0))
		var min_hp: int = int(ch.get("min_hp", 0))
		var is_dis: bool = (cost_cash > 0 and int(main.cash) < cost_cash) or (min_hp > 0 and float(main.player.get("health", 100.0)) < float(min_hp))
		TLRTheme.make_abs_label(card, "CHOICE 0%d" % (i + 1), Rect2(28, 28, 200, 24), 13, TLRTheme.AMBER, true)
		TLRTheme.make_abs_label(card, str(ch.get("label", "")), Rect2(28, 70, 440, 68), 28, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(card, str(ch.get("detail", "")), Rect2(28, 156, 440, 120), 18, TLRTheme.MINT if not is_dis else TLRTheme.TEXT_DIM, false)
		TLRTheme.make_abs_button(card, "INSUFFICIENT FUNDS / HP" if is_dis else "TAKE DEAL  →", Rect2(28, 294, 440, 52), main._resolve_hub_event.bind(i), "teal" if not is_dis else "default", is_dis, 14)

	TLRTheme.make_abs_label(parent, "CASH: $%d   •   HP: %d / %d   •   BAG: %d / 3" % [int(main.cash), int(main.player.health), int(main.player.max_health), main.inventory.size()], Rect2(40, 628, 700, 28), 15, TLRTheme.TEXT_MUTED, true)
	TLRTheme.make_abs_button(parent, "WALK AWAY (BACK TO CORNER)", Rect2(40, 814, 340, 48), main._show_bracket, "default", false, 14)
	if bool(main.animate_cards_enter):
		main.animate_cards_enter = false
		TLRTheme.stagger_enter(main, cards, Vector2(0.0, 20.0), 0.22, 0.04)


static func build_event_result(main: Node, parent: Control, ev_title: String, headline: String, detail: String, summary: String, status: String) -> void:
	var is_fail := (status == "fail")
	var is_win := (status == "win")
	var tag := "OUTCOME: FAILED / BUST ✗" if is_fail else ("OUTCOME: SUCCESS / WON ✓" if is_win else "OUTCOME: DEAL STRUCK")
	var col: Color = TLRTheme.CORAL if is_fail else (TLRTheme.MINT if is_win else TLRTheme.AMBER)
	var bg: Color = TLRTheme.SURFACE_CRIMSON if is_fail else (TLRTheme.SURFACE_TEAL if is_win else TLRTheme.SURFACE_AMBER)
	var border: Color = TLRTheme.BORDER_CRIMSON if is_fail else (TLRTheme.BORDER_TEAL if is_win else TLRTheme.BORDER_AMBER)

	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / %s" % ev_title.to_upper(),
		headline,
		"Your decision was resolved. Review the outcome below before returning to your corner.",
		col
	)
	var card := TLRTheme.make_panel(parent, Rect2(260, 224, 1080, 390), bg, border, 2, 0, 0)
	TLRTheme.make_abs_label(card, tag, Rect2(42, 34, 600, 28), 16, col, true)
	TLRTheme.make_abs_label(card, headline, Rect2(42, 86, 996, 58), 40, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(card, detail, Rect2(42, 166, 996, 68), 20, TLRTheme.TEXT_PRIMARY, false)
	TLRTheme.make_abs_label(card, summary, Rect2(42, 260, 996, 56), 17, col, true)
	TLRTheme.make_abs_label(card, "NOW: CASH $%d   •   HP %d / %d   •   STA %d / %d   •   BAG %d / 3" % [int(main.cash), int(main.player.health), int(main.player.max_health), int(main.player.stamina), int(main.player.max_stamina), main.inventory.size()], Rect2(42, 330, 996, 28), 14, TLRTheme.TEXT_MUTED, true)

	TLRTheme.make_abs_button(parent, "BACK TO YOUR CORNER  →", Rect2(1020, 814, 540, 48), main._show_bracket, "teal" if not is_fail else "default", false, 15)


# ---------------------------------------------------------
# 4. REWARDS (UI/R06–R09, R14–R16)
# ---------------------------------------------------------

static func build_rewards(main: Node, parent: Control, options: Array) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / FIGHT %02d CLEARED" % (int(main.fight_index) + 1),
		"CHOOSE YOUR EDGE",
		"Take one reward. Review the benefit and tradeoff before confirming."
	)

	var card_w := 496.0
	var card_h := 486.0
	var gap := 16.0
	var sel_idx: int = clampi(int(main.selected_reward_index), -1, options.size() - 1)
	var reward_cards: Array = []

	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var cx := 40.0 + float(i) * (card_w + gap)
		var is_sel := (i == sel_idx)
		var o_type := str(opt.get("type", "stat"))
		var is_perk_card := (o_type == "perk")
		var rar_str := "common"
		if o_type == "item":
			rar_str = str(opt.data.get("rarity", "common"))
		elif o_type == "perk":
			rar_str = str(opt.data.get("rarity", "rare"))
		var rmeta: Dictionary = TLRTheme.rarity_meta(rar_str)
		var use_rar_style := (o_type in ["item", "perk"]) and rar_str != "common"
		var bg: Color = TLRTheme.SURFACE_TEAL if is_sel else (Color(rmeta.bg) if use_rar_style else (TLRTheme.SURFACE_AMBER if is_perk_card else TLRTheme.SURFACE_SOLID))
		var border: Color = TLRTheme.BORDER_TEAL if is_sel else (Color(rmeta.border) if use_rar_style else (TLRTheme.BORDER_AMBER if is_perk_card else TLRTheme.BORDER_SUBTLE))
		var card := TLRTheme.make_panel(parent, Rect2(cx, 174, card_w, card_h), bg, border, 2, 0, 0)
		reward_cards.append(card)
		if is_sel or use_rar_style:
			var top_bar := ColorRect.new()
			top_bar.position = Vector2(0, 0)
			top_bar.size = Vector2(card_w, 4)
			top_bar.color = TLRTheme.CYAN if is_sel else Color(rmeta.color)
			card.add_child(top_bar)

		var category := "STAT UPGRADE"
		var icon_id := ""
		var title_txt := ""
		var sub_metric := ""
		var body_txt := ""
		var benefit_txt := ""
		var tradeoff_txt := ""

		if o_type == "move":
			var md: Dictionary = opt.data
			var m_id := str(md.get("id", ""))
			var cur_lv: int = main._move_level(m_id)
			var is_upg: bool = main.owned_moves.has(m_id)
			var next_lv := cur_lv + 1 if is_upg else 1
			category = ("MOVE UPGRADE  •  LV.%d" % next_lv) if is_upg else "NEW MOVE"
			icon_id = m_id
			title_txt = str(md.get("name", "Move")).to_upper()
			sub_metric = "%d STA  •  %d%% ACCURACY" % [int(main._effective_move_cost(md)), int(md.get("accuracy", 100))]
			var dmg: Array = md.get("damage", [0, 0])
			if dmg.size() >= 2 and int(dmg[1]) > 0:
				body_txt = "%d–%d base damage • %d%% accuracy." % [int(dmg[0]), int(dmg[1]), int(md.get("accuracy", 100))]
			else:
				body_txt = str(md.get("kind", "utility")).capitalize() + " move."
			benefit_txt = ("Level %d: +22%% move power, -1 stamina cost & +1 base DMG." % next_lv) if is_upg else str(md.get("description", ""))
			tradeoff_txt = "Already in your loadout — masters this technique." if is_upg else "Uses 1 move slot.\nStamina cost applies each turn used."
		elif o_type == "item":
			var idata: Dictionary = opt.data
			var i_id := str(idata.get("id", ""))
			var timing_tag := "BETWEEN FIGHTS" if i_id == "ice" else ("LAST STAND" if i_id == "salts" else ("QUICK-USE" if i_id in ["cutman_kit", "adrenaline_shot", "nitro_salts"] else "COMBAT USE"))
			category = "%s ITEM  •  %s" % [str(rmeta.label), timing_tag]
			icon_id = i_id
			title_txt = str(idata.get("name", "Item")).to_upper()
			sub_metric = "%s  •  VALUE $%d" % [main._item_timing(i_id).split(" — ")[0].to_upper(), int(idata.get("price", 20))]
			body_txt = str(idata.get("description", ""))
			benefit_txt = "Adds 1 %s item to your corner bag." % str(rmeta.label).to_lower()
			tradeoff_txt = "Uses 1 of 3 corner bag slots.\nConsumed when activated (Sellable in Shop)."
		elif o_type == "perk":
			var pd: Dictionary = opt.data
			category = "%s TRAIT  •  %d / %d" % [str(rmeta.label), main.owned_perks.size(), int(main.PERK_MAX)]
			icon_id = "perk"
			title_txt = str(pd.get("name", "Trait")).to_upper()
			sub_metric = "PASSIVE TRAIT  •  RUN-WIDE"
			body_txt = str(pd.get("desc", pd.get("description", "")))
			benefit_txt = "Stacks permanently with your stats and moves for this run."
			tradeoff_txt = "Max %d Traits per run.\nReplaces taking a move or item." % int(main.PERK_MAX)
		else:
			var upg: Dictionary = opt.data
			title_txt = str(upg.get("name", "Upgrade")).to_upper()
			sub_metric = "PERMANENT RUN STAT"
			body_txt = str(upg.get("description", ""))
			benefit_txt = "Applies immediately for the rest of this run."
			tradeoff_txt = "Replaces taking a move or item from this fight."

		TLRTheme.make_abs_label(card, category, Rect2(26, 22, card_w - 52, 20), 12, TLRTheme.AMBER if is_perk_card else TLRTheme.TEXT_MUTED, true)
		if not icon_id.is_empty():
			var ic := TLRTheme.UIIcon.new(icon_id, TLRTheme.AMBER if is_perk_card else TLRTheme.TEXT_PRIMARY, Vector2(28, 28))
			ic.position = Vector2(26, 60)
			card.add_child(ic)

		TLRTheme.make_abs_label(card, title_txt, Rect2(26, 114, card_w - 52, 40), 30, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(card, sub_metric, Rect2(26, 158, card_w - 52, 24), 12, TLRTheme.AMBER if is_perk_card else TLRTheme.CYAN, true)
		TLRTheme.make_abs_label(card, body_txt, Rect2(26, 202, card_w - 52, 64), 17, TLRTheme.TEXT_PRIMARY, false)
		TLRTheme.make_abs_label(card, benefit_txt, Rect2(26, 280, card_w - 52, 54), 16, TLRTheme.MINT, false)
		TLRTheme.make_abs_label(card, tradeoff_txt, Rect2(26, 356, card_w - 52, 72), 14, TLRTheme.TEXT_MUTED, false)

		var btn_caption := "SELECTED ✓" if is_sel else "SELECT →"
		var btn_col := TLRTheme.CYAN if is_sel else (TLRTheme.AMBER if is_perk_card else TLRTheme.TEXT_PRIMARY)
		TLRTheme.make_abs_label(card, btn_caption, Rect2(26, 432, 200, 26), 14, btn_col, true)
		var card_hit := Button.new()
		card_hit.position = Vector2.ZERO
		card_hit.size = Vector2(card_w, card_h)
		card_hit.focus_mode = Control.FOCUS_ALL
		card_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hit_norm := TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0)
		var hit_hover := TLRTheme.style_box(Color(0.14, 0.36, 0.46, 0.14), TLRTheme.BORDER_HOVER if not is_sel else TLRTheme.BORDER_TEAL, 2, 0, 0, 0)
		var hit_press := TLRTheme.style_box(Color(0.08, 0.25, 0.32, 0.22), TLRTheme.BORDER_TEAL, 2, 0, 0, 0)
		card_hit.add_theme_stylebox_override("normal", hit_norm)
		card_hit.add_theme_stylebox_override("hover", hit_hover)
		card_hit.add_theme_stylebox_override("focus", hit_hover)
		card_hit.add_theme_stylebox_override("pressed", hit_press)
		card_hit.pressed.connect(main._select_reward_option.bind(i))
		card.add_child(card_hit)

	var max_slots := 4 + int(main.passive.get("slots", 0))
	var salts_tag := "LAST STAND: SPENT" if main.revive_used else ("LAST STAND: READY" if main.inventory.has("salts") else "LAST STAND: NOT IN BAG")
	TLRTheme.make_abs_label(parent, "LOADOUT %d/%d  •  BAG %d/3  •  TRAITS %d/%d  •  %s  •  CASH $%d  •  RESPECT %d" % [main.owned_moves.size(), max_slots, main.inventory.size(), main.owned_perks.size(), int(main.PERK_MAX), salts_tag, int(main.cash), int(main.respect)], Rect2(40, 688, 1520, 24), 13, TLRTheme.TEXT_MUTED, true)
	TLRTheme.make_abs_label(parent, "KEYS 1–3 / SELECT OPTION   •   ENTER / CONFIRM REWARD", Rect2(40, 812, 680, 24), 12, TLRTheme.TEXT_DIM, true)

	var confirm_label := "SELECT A REWARD TO CONTINUE"
	var confirm_disabled := sel_idx < 0
	if not confirm_disabled:
		var chosen: Dictionary = options[sel_idx]
		var c_name := ""
		if chosen.type == "move":
			c_name = str(chosen.data.get("name", "Move"))
		elif chosen.type == "item":
			c_name = str(chosen.data.get("name", "Item"))
		elif chosen.type == "perk":
			c_name = str(chosen.data.get("name", "Trait"))
		else:
			c_name = str(chosen.data.get("name", "Upgrade"))
		confirm_label = "CONFIRM %s   →" % c_name.to_upper()

	TLRTheme.make_abs_button(parent, "REROLL ($20)", Rect2(760, 800, 230, 48), main._reroll_rewards, "default", int(main.cash) < 20, 14)
	TLRTheme.make_abs_button(parent, confirm_label, Rect2(1010, 800, 550, 48), main._confirm_selected_reward, "teal" if not confirm_disabled else "default", confirm_disabled, 15)
	if bool(main.animate_cards_enter):
		main.animate_cards_enter = false
		TLRTheme.stagger_enter(main, reward_cards, Vector2(0.0, 22.0), 0.25, 0.05)


static func build_reward_confirmed(main: Node, parent: Control, headline: String, detail: String, summary: String) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / FIGHT %02d CLEARED" % int(main.fight_index),
		"REWARD CONFIRMED",
		"Your choice is locked in. Return to your corner to prepare for the next fight."
	)

	var card := TLRTheme.make_panel(parent, Rect2(300, 224, 1000, 390), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(card, "ADDED TO YOUR RUN ✓", Rect2(38, 34, 600, 24), 14, TLRTheme.MINT, true)
	TLRTheme.make_abs_label(card, headline.to_upper(), Rect2(38, 92, 920, 56), 44, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(card, detail, Rect2(38, 166, 920, 48), 20, TLRTheme.TEXT_PRIMARY, false)
	TLRTheme.make_abs_label(card, summary, Rect2(38, 250, 920, 60), 15, TLRTheme.CYAN, false)
	TLRTheme.make_abs_label(card, "Post-fight recovery applied: +10 HP and +20 STA.", Rect2(38, 326, 920, 24), 14, TLRTheme.TEXT_MUTED, false)

	TLRTheme.make_abs_button(parent, "BACK TO YOUR CORNER  →", Rect2(1020, 814, 540, 48), main._show_bracket, "teal", false, 15)


# ---------------------------------------------------------
# 5. RUN END — DEFEAT & VICTORY (UI/R19, R21)
# ---------------------------------------------------------

static func build_run_end(main: Node, parent: Control, won: bool, reason: String) -> void:
	var cleared := int(main.fight_index) + (1 if won else 0)
	var title := "THE CROWN IS YOURS." if won else "LIGHTS OUT. NOT THE END."
	var title_col := TLRTheme.MINT if won else TLRTheme.CORAL
	TLRTheme.add_page_header(parent, "THE LAST ROUND / RUN SUMMARY", title, reason, title_col)

	var card_w := 748.0
	var card_h := 530.0
	var left := TLRTheme.make_panel(parent, Rect2(40, 184, card_w, card_h), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(left, "%02d / 08" % cleared, Rect2(36, 30, 400, 76), 72, title_col, true)
	TLRTheme.make_abs_label(left, "FIGHTS CLEARED / RUN COMPLETE" if won else "FIGHTS CLEARED", Rect2(36, 114, 420, 24), 15, TLRTheme.TEXT_PRIMARY, true)
	var seg_bar := TLRTheme.UISegmentBar.new(8, cleared, title_col)
	seg_bar.position = Vector2(36, 148)
	seg_bar.size = Vector2(676, 6)
	left.add_child(seg_bar)

	TLRTheme.make_abs_label(left, "FIGHT RECORD", Rect2(36, 178, 300, 24), 14, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(left, reason, Rect2(36, 208, 676, 48), 18, TLRTheme.TEXT_PRIMARY, false)

	TLRTheme.make_abs_label(left, "YOUR BUILD (MOVES & CORNER BAG)", Rect2(36, 252, 400, 20), 12, TLRTheme.CYAN, true)
	for mi in range(mini(6, main.owned_moves.size())):
		var m_id := str(main.owned_moves[mi])
		var md: Dictionary = main._get_move(m_id)
		var chip := TLRTheme.make_panel(left, Rect2(36 + float(mi % 3) * 226.0, 278 + float(mi / 3) * 40.0, 214, 34), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_CARD, 1, 0, 0)
		var ic := TLRTheme.UIIcon.new(m_id, TLRTheme.CYAN, Vector2(16, 16))
		ic.position = Vector2(10, 9)
		chip.add_child(ic)
		TLRTheme.make_abs_label(chip, str(md.get("name", m_id)).to_upper(), Rect2(34, 6, 170, 22), 12, TLRTheme.TEXT_PRIMARY, true)

	for si in range(3):
		var item_id := str(main.inventory[si]) if si < main.inventory.size() else ""
		var ichip := TLRTheme.make_panel(left, Rect2(36 + float(si) * 226.0, 362, 214, 34), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_SUBTLE if not item_id.is_empty() else TLRTheme.BORDER_CARD, 1, 0, 0)
		if item_id.is_empty():
			TLRTheme.make_abs_label(ichip, "BAG SLOT %d: EMPTY" % (si + 1), Rect2(12, 7, 190, 20), 11, TLRTheme.TEXT_DIM, true)
		else:
			var iic := TLRTheme.UIIcon.new(item_id, TLRTheme.AMBER, Vector2(16, 16))
			iic.position = Vector2(10, 9)
			ichip.add_child(iic)
			TLRTheme.make_abs_label(ichip, str(main._get_item_name(item_id)).to_upper(), Rect2(34, 6, 170, 22), 12, TLRTheme.TEXT_PRIMARY, true)

	var stats_box := TLRTheme.make_panel(left, Rect2(36, 410, 676, 86), TLRTheme.SURFACE_DARK, TLRTheme.BORDER_CARD, 1, 0, 0)
	var stat_items := [
		["HP", "%d / %d" % [int(main.player.get("health", 0)), int(main.player.get("max_health", 100))]],
		["STAMINA", "%d / %d" % [int(main.player.get("stamina", 0)), int(main.player.get("max_stamina", 100))]],
		["DAMAGE", str(int(main.player.get("damage", 0)))],
		["DEFENCE", str(int(main.player.get("defence", 0)))],
		["SPEED", "%d%%" % int(main._speed_chance(float(main.player.get("speed", 0))))]
	]
	for si in range(stat_items.size()):
		var sx := 18.0 + float(si) * 130.0
		TLRTheme.make_abs_label(stats_box, stat_items[si][0], Rect2(sx, 14, 120, 18), 11, TLRTheme.TEXT_DIM, true)
		TLRTheme.make_abs_label(stats_box, stat_items[si][1], Rect2(sx, 38, 120, 30), 22, TLRTheme.TEXT_PRIMARY, true)

	var right := TLRTheme.make_panel(parent, Rect2(40 + card_w + 24, 184, card_w, card_h), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(right, "EVERY RUN LEAVES A MARK", Rect2(36, 36, 420, 26), 16, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(right, "+%d RESPECT" % int(main.respect), Rect2(36, 92, 600, 56), 46, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(right, "RANK: " + str(main._respect_rank()), Rect2(36, 154, 600, 28), 16, TLRTheme.TEXT_MUTED, false)

	var prev_career := maxi(0, int(main.lifetime_respect) - int(main.respect))
	var milestone := _next_milestone(int(main.lifetime_respect))
	var target := int(milestone.target)
	TLRTheme.make_abs_label(right, "CAREER / %d → %d" % [prev_career, int(main.lifetime_respect)], Rect2(36, 250, 500, 28), 18, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.add_progress_bar(right, Rect2(36, 290, 676, 8), float(main.lifetime_respect), float(target), TLRTheme.MINT)
	TLRTheme.make_abs_label(right, "%d / %d RESPECT — %s" % [int(main.lifetime_respect), target, str(milestone.label)], Rect2(36, 314, 500, 24), 15, TLRTheme.AMBER, true)
	TLRTheme.make_abs_label(right, "PERMANENT PERKS: " + str(main._career_perk_summary()), Rect2(36, 356, 676, 74), 14, TLRTheme.TEXT_MUTED, false)
	var trait_names: Array[String] = []
	for pid in main.owned_perks:
		trait_names.append(str(main._get_perk_data(str(pid)).get("name", pid)))
	var traits_line := "RUN TRAITS: " + (", ".join(trait_names) if not trait_names.is_empty() else "None")
	var rec_line := "PEAK HIT: %d  •  KOs: %d  •  PIT CASH: $%d\n%s" % [int(main.run_highest_hit), int(main.run_knockouts), int(main.cash), traits_line]
	TLRTheme.make_abs_label(right, rec_line, Rect2(36, 442, 676, 68), 13, TLRTheme.CYAN, false)

	TLRTheme.make_abs_button(parent, "MAIN MENU", Rect2(40, 814, 190, 48), main._show_main_menu, "default", false, 14)
	TLRTheme.make_abs_button(parent, "TRY AGAIN (CHOOSE STYLE)  →", Rect2(1040, 814, 520, 48), main._show_style_select.bind(main.selected_slot), "teal", false, 15)
	TLRTheme.stagger_enter(main, [left, right], Vector2(0.0, 22.0), 0.26, 0.06)


# ---------------------------------------------------------
# 6. COACH SPAR & TRAINING (UI/R22, C01, R23, R24, R29)
# ---------------------------------------------------------

static func build_coach_spar(main: Node, parent: Control) -> void:
	# Mask around the live 3D Coach arena cutout aligned to 1600x900 grid: Rect2(40, 168, 996, 580)
	var cutout := Rect2(40, 168, 996, 580)
	for mask_rect in [
		Rect2(0, 0, 1600, cutout.position.y),
		Rect2(0, cutout.end.y, 1600, 900 - cutout.end.y),
		Rect2(0, cutout.position.y, cutout.position.x, cutout.size.y),
		Rect2(cutout.end.x, cutout.position.y, 1600 - cutout.end.x, cutout.size.y)
	]:
		var m := ColorRect.new()
		m.position = mask_rect.position
		m.size = mask_rect.size
		m.color = TLRTheme.BG_DARK
		parent.add_child(m)

	# Frame border around the live 3D arena cutout (matches UI/R22 • Coach spar.png)
	var frame := Panel.new()
	frame.position = cutout.position
	frame.size = cutout.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", TLRTheme.style_box(Color(0, 0, 0, 0), TLRTheme.BORDER_SUBTLE, 1, 2, 0, 0))
	parent.add_child(frame)

	var ex_num := mini(int(main.training_turn) + 1, int(main.TRAINING_EXCHANGES))
	var lesson_titles := [
		"YOUR FIRST LESSON: WATCH THE BODY.",
		"GUARD THE RIBS: WATCH THE LEVEL DROP.",
		"STAY SHARP: ANSWER THE LEAD HAND.",
		"READ BEFORE YOU SWING.",
		"BREATHING WINDOW: MANAGE YOUR GAS.",
		"BREAK THE RHYTHM: WEATHER THE RUSH.",
		"CRACK HIGH GUARD & BUILD MOMENTUM.",
		"STOP SHOWBOATS & UNLEASH LIGHTS OUT."
	]
	var headline := str(lesson_titles[mini(int(main.training_turn), lesson_titles.size() - 1)])

	# Subtle top corner telemetry inside the ring viewport
	TLRTheme.make_abs_label(frame, "EXCHANGE %02d / %02d" % [ex_num, int(main.TRAINING_EXCHANGES)], Rect2(22, 16, 220, 22), 12, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(frame, "HP %d / %d   •   STA %d / %d" % [int(main.player.health), int(main.player.max_health), int(main.player.stamina), int(main.player.max_stamina)], Rect2(frame.size.x - 320, 16, 298, 22), 12, TLRTheme.TEXT_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)

	# Quiet bottom-left observation cue (non-intrusive vs orange box)
	var tell_txt := str(main.enemy_next_action.get("tell", "Coach studies your guard."))
	var cue_bar := TLRTheme.make_panel(frame, Rect2(20, frame.size.y - 48, 660, 32), Color(0.020, 0.042, 0.072, 0.82), Color(0.16, 0.34, 0.44, 0.70), 1, 0, 0)
	TLRTheme.make_abs_label(cue_bar, "OBSERVE  •  " + tell_txt, Rect2(12, 4, 636, 24), 12, TLRTheme.CYAN, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)

	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / COACH SPAR / %02d" % ex_num,
		headline,
		"Practice the existing moves before you begin your run. No items are consumed from a saved run."
	)

	# Right panel: THE COACH editorial layout matching UI/R22 • Coach spar.png
	var rp := TLRTheme.make_panel(parent, Rect2(1056, 168, 504, 580), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(rp, "THE COACH", Rect2(28, 24, 300, 22), 14, TLRTheme.CYAN, true)

	var feedback := str(main.training_feedback)
	if feedback.is_empty():
		feedback = "Eyes on the rear shoulder. See the weight load?"
	TLRTheme.make_abs_label(rp, "“%s”" % feedback, Rect2(28, 58, 448, 128), 24, TLRTheme.TEXT_PRIMARY, true)

	var rec_ids: Array = main._training_recommended_moves()
	var cost_lines: Array[String] = []
	for r_id in rec_ids:
		var rmd: Dictionary = main._get_move(str(r_id))
		cost_lines.append("%s costs %d stamina." % [str(rmd.get("name", r_id)), int(rmd.get("cost", 0))])
	var hint_body := "Choose a response for this tell.\n" + " ".join(cost_lines) + "\nOne move ends your turn."
	TLRTheme.make_abs_label(rp, hint_body, Rect2(28, 194, 448, 74), 14, TLRTheme.TEXT_MUTED, false)

	# Primary Lesson Choices (large clean R22-style buttons)
	TLRTheme.make_abs_label(rp, "SUGGESTED RESPONSE", Rect2(28, 280, 300, 18), 11, TLRTheme.CYAN, true)
	var rec_count := mini(rec_ids.size(), 4)
	var rec_gap := 12.0
	var rec_w := (448.0 - float(maxi(0, rec_count - 1)) * rec_gap) / float(maxi(1, rec_count))
	for i in range(rec_count):
		var m_id := str(rec_ids[i])
		var md: Dictionary = main._get_move(m_id)
		var slot_idx: int = main.owned_moves.find(m_id)
		var key_num: int = slot_idx + 1 if slot_idx >= 0 else i + 1
		var cost := int(md.get("cost", 0))
		var enough := float(main.player.get("stamina", 0.0)) >= float(cost)
		var btn_label := "%s  /  %d\n%d STA" % [str(md.get("name", m_id)).to_upper(), key_num, cost]
		var bx := 28.0 + float(i) * (rec_w + rec_gap)
		var rb := TLRTheme.make_abs_button(rp, btn_label, Rect2(bx, 304, rec_w, 60), main._player_move.bind(m_id), "teal", not enough, 13)
		rb.tooltip_text = main._move_reward_details(md)

	# Divider before secondary moves
	var div := ColorRect.new()
	div.position = Vector2(28, 386)
	div.size = Vector2(448, 1)
	div.color = Color(0.16, 0.27, 0.38, 0.75)
	rp.add_child(div)

	TLRTheme.make_abs_label(rp, "ALL MOVES  (KEYS 1–8)", Rect2(28, 400, 300, 18), 11, TLRTheme.TEXT_DIM, true)
	var other_moves: Array[String] = []
	for m_v in main.owned_moves:
		var m_str := str(m_v)
		if not rec_ids.has(m_str):
			other_moves.append(m_str)

	var ow := 142.0
	var oh := 48.0
	for j in range(other_moves.size()):
		var om_id := other_moves[j]
		var omd: Dictionary = main._get_move(om_id)
		var o_slot: int = main.owned_moves.find(om_id)
		var o_key: int = o_slot + 1 if o_slot >= 0 else j + 1
		var o_cost := int(omd.get("cost", 0))
		var o_enough := float(main.player.get("stamina", 0.0)) >= float(o_cost)
		var col := j % 3
		var row := j / 3
		var ox := 28.0 + float(col) * (ow + 11.0)
		var oy := 424.0 + float(row) * (oh + 10.0)
		var ob := TLRTheme.make_abs_button(rp, "%s  /  %d\n%d STA" % [str(omd.get("name", om_id)).to_upper(), o_key, o_cost], Rect2(ox, oy, ow, oh), main._player_move.bind(om_id), "default", not o_enough, 11)
		ob.tooltip_text = main._move_reward_details(omd)

	TLRTheme.make_abs_button(parent, "MAIN MENU", Rect2(40, 814, 190, 48), main._show_main_menu, "default", false, 14)
	TLRTheme.make_abs_button(parent, "CORNER BAG LESSON", Rect2(246, 814, 240, 48), main._show_training_items, "default", false, 14)
	TLRTheme.make_abs_button(parent, "WATCH ALL 8 TELLS  →", Rect2(1140, 814, 420, 48), main._show_telegraph_practice, "teal", false, 14)


static func build_training_complete(main: Node, parent: Control) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / COACH SPAR / COMPLETE",
		"GOOD READ. KEEP YOUR HANDS UP.",
		"Practice the core mechanics before picking your Fighting Style. No items are consumed from a saved run."
	)

	var left := TLRTheme.make_panel(parent, Rect2(40, 168, 996, 580), Color(0.020, 0.042, 0.072, 1.0), TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	left.add_child(TLRBoxerPreview.new(Rect2(6, 6, 984, 568), Color(0.28, 0.38, 0.40), "defense", true, true))

	var right := TLRTheme.make_panel(parent, Rect2(1056, 168, 504, 580), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(right, "THE COACH", Rect2(28, 24, 300, 24), 15, TLRTheme.CYAN, true)
	TLRTheme.make_abs_label(right, "“You're ready for the pit.\nMake every round yours.”", Rect2(28, 58, 448, 80), 28, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.make_abs_label(
		right,
		"• FEINT & GUARD BREAKS grant MOMENTUM — a free follow-up punch.\n• LANDING HITS fills ADRENALINE — 100% triggers LIGHTS OUT (×1.75).\n• EVERY RUN IS RANDOM: pick a Style, Card A/B challenger, Black Market gear, Side Contracts & Street Events.",
		Rect2(28, 154, 448, 152),
		15,
		TLRTheme.TEXT_MUTED,
		false
	)
	TLRTheme.make_abs_label(
		right,
		"Items range from Common to Contraband; Quick-Use vials keep your turn!",
		Rect2(28, 310, 448, 40),
		13,
		TLRTheme.CYAN,
		false
	)
	TLRTheme.make_abs_button(right, "NEXT: CORNER BAG & RARITY  →", Rect2(28, 366, 448, 52), main._show_training_items, "teal", false, 15)
	TLRTheme.make_abs_button(right, "SPAR AGAIN", Rect2(28, 430, 448, 46), main._start_training, "default", false, 14)
	TLRTheme.make_abs_button(right, "CHOOSE STYLE & START RUN", Rect2(28, 488, 448, 48), main._request_new_run.bind(main.selected_slot), "orange", false, 14)

	TLRTheme.make_abs_button(parent, "MAIN MENU", Rect2(40, 814, 190, 48), main._show_main_menu, "default", false, 14)
	TLRTheme.make_abs_button(parent, "WATCH ALL 8 TELLS", Rect2(1140, 814, 420, 48), main._show_telegraph_practice, "default", false, 14)
	TLRTheme.stagger_enter(main, [left, right], Vector2(0.0, 22.0), 0.25, 0.06)


static func build_training_items(main: Node, parent: Control) -> void:
	var used_demo := bool(main.item_lesson_demo_used)
	var show_all := bool(main.item_lesson_show_all)
	var title := "FUEL IN THE TANK. READY TO ANSWER." if used_demo else "KNOW YOUR GEAR & RARITY."
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / COACH SPAR / 02",
		title,
		"Items span Common to Contraband tiers. Quick-Use items keep your turn; others cost a turn or heal in the Hub."
	)

	var left := TLRTheme.make_panel(parent, Rect2(40, 174, 748, 560), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(left, "YOUR STAMINA", Rect2(36, 32, 300, 22), 15, TLRTheme.CYAN, true)
	var sta_val := 43 if used_demo else 8
	TLRTheme.make_abs_label(left, "%d / 100" % sta_val, Rect2(36, 78, 360, 74), 64, TLRTheme.TEXT_PRIMARY, true)
	TLRTheme.add_progress_bar(left, Rect2(36, 168, 676, 10), float(sta_val), 100.0, TLRTheme.BLUE)

	if used_demo:
		TLRTheme.make_abs_label(left, "+35 STAMINA RESTORED", Rect2(36, 208, 420, 30), 20, TLRTheme.MINT, true)
		TLRTheme.make_abs_label(left, "Energy Drink ×0\nLose 10 stamina next turn after your opponent responds.\nPlan around the response — combat items take your turn.", Rect2(36, 254, 676, 100), 16, TLRTheme.TEXT_MUTED, false)
		TLRTheme.make_abs_button(left, "RESET EXAMPLE", Rect2(36, 466, 676, 54), main._toggle_item_lesson_demo, "default", false, 14)
	else:
		TLRTheme.make_abs_label(left, "FATIGUED", Rect2(36, 208, 300, 30), 20, TLRTheme.AMBER, true)
		TLRTheme.make_abs_label(left, "Preview the Energy Drink to recover 35 stamina immediately.\nCorner Ice is Hub-only between fights; Smelling Salts trigger automatically.", Rect2(36, 254, 676, 100), 16, TLRTheme.TEXT_MUTED, false)
		TLRTheme.make_abs_button(left, "PREVIEW ENERGY DRINK / Q", Rect2(36, 466, 676, 54), main._toggle_item_lesson_demo, "teal", false, 14)

	var right := TLRTheme.make_panel(parent, Rect2(812, 174, 748, 560), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	TLRTheme.make_abs_label(right, "KNOW WHEN TO USE IT (3 SLOTS MAX)", Rect2(36, 32, 460, 22), 15, TLRTheme.CYAN, true)
	TLRTheme.make_abs_button(right, "CORE 3 LESSONS" if show_all else "ALL %d BAG ITEMS  →" % main.item_templates.size(), Rect2(532, 24, 180, 34), main._toggle_item_lesson_scope, "ghost", false, 11)

	if not show_all:
		var featured := [
			{"id": "adrenaline_shot", "name": "RARE / QUICK-USE VIALS", "line1": "Adrenaline Vial, Cutman Swab & Nitro Salts trigger instantly.", "line2": "Quick-Use keeps your turn so you can strike right away!"},
			{"id": "energy", "name": "ENERGY DRINK (COMMON)", "line1": "+35 stamina now; -10 stamina next turn.", "line2": "Standard combat item — spends your turn."},
			{"id": "ice", "name": "CORNER ICE PACK", "line1": "Restore 22 health between fights.", "line2": "Hub-only heal (Sell excess items in Black Market for 50% cash)."},
			{"id": "salts", "name": "SMELLING SALTS (RARE)", "line1": "Triggers once automatically on a knockout (+30 HP).", "line2": "Passive Last Stand — stays ready in your bag."}
		]
		for i in range(featured.size()):
			var f: Dictionary = featured[i]
			var fy := 84.0 + float(i) * 112.0
			var ic := TLRTheme.UIIcon.new(str(f.id), TLRTheme.CYAN if i == 0 else TLRTheme.TEXT_PRIMARY, Vector2(28, 28))
			ic.position = Vector2(36, fy + 4.0)
			right.add_child(ic)
			TLRTheme.make_abs_label(right, str(f.name), Rect2(86, fy, 590, 26), 16, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(right, str(f.line1) + "\n" + str(f.line2), Rect2(86, fy + 28.0, 620, 68), 13, TLRTheme.TEXT_MUTED, false)
	else:
		var scroll := ScrollContainer.new()
		scroll.position = Vector2(36, 78)
		scroll.size = Vector2(676, 452)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		right.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 14)
		scroll.add_child(list)

		for item_v in main.item_templates:
			var it: Dictionary = item_v
			var i_id := str(it.get("id", ""))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			list.add_child(row)
			var ic := TLRTheme.UIIcon.new(i_id, TLRTheme.TEXT_PRIMARY, Vector2(28, 28))
			row.add_child(ic)
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(col)
			col.add_child(TLRTheme.make_label(str(it.get("name", "")).to_upper(), 15, TLRTheme.TEXT_PRIMARY, true))
			col.add_child(TLRTheme.make_label(str(it.get("description", "")) + "  •  " + main._item_timing(i_id), 13, TLRTheme.TEXT_MUTED, false))

	TLRTheme.make_abs_button(parent, "MAIN MENU", Rect2(40, 814, 190, 48), main._show_main_menu, "default", false, 14)
	TLRTheme.make_abs_button(parent, "SPAR AGAIN", Rect2(246, 814, 190, 48), main._start_training, "default", false, 14)
	TLRTheme.make_abs_button(parent, "BACK TO TRAINING SUMMARY  →", Rect2(1100, 814, 460, 48), main._show_training_complete, "teal", false, 14)
	TLRTheme.stagger_enter(main, [left, right], Vector2(0.0, 22.0), 0.24, 0.05)


static func build_telegraph_practice(main: Node, parent: Control) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / COACH SPAR / TELLS",
		"READ THE FIGHTER. NOT A LABEL.",
		"Choose a sequence. Watch anticipation, action and recovery without text announcing the opponent's move."
	)

	var tells := [
		{"num": "01", "title": "HEAVY PUNCH", "desc": "Right shoulder loads; weight shifts back.", "counter": "Answer: Block, Slip, or Counter", "pose": "heavy"},
		{"num": "02", "title": "BODY SHOT", "desc": "Level drops; elbow tracks ribs.", "counter": "Answer: Block, Slip, or Clinch", "pose": "body"},
		{"num": "03", "title": "QUICK JAB", "desc": "Lead shoulder twitches; compact punch.", "counter": "Answer: Jab, Block, or Slip", "pose": "jab"},
		{"num": "04", "title": "COMBINATION", "desc": "Weight shifts smoothly between hands.", "counter": "Answer: Block, Slip, or Clinch", "pose": "combination"},
		{"num": "05", "title": "HIGH GUARD", "desc": "Gloves shield jaw tight.", "counter": "Answer: Body Shot or Feint -> Momentum", "pose": "defense"},
		{"num": "06", "title": "RECOVERY", "desc": "Hands drop low; chest heaves.", "counter": "Tip: Breathing window — Rest or attack", "pose": "recovery"},
		{"num": "07", "title": "SHOWBOAT TAUNT", "desc": "Drops gloves wide to bait crowd.", "counter": "Answer: Hit now to stop +35% buff!", "pose": "taunt"},
		{"num": "08", "title": "PHASE 2 ENRAGE", "desc": "Berserkers roar below 50% HP.", "counter": "Tip: Burst down with Lights Out!", "pose": "enrage"}
	]

	var cw := 368.0
	var ch := 286.0
	var active_pose := str(main.practice_pose)
	var tell_cards: Array = []
	for i in range(tells.size()):
		var t: Dictionary = tells[i]
		var col := i % 4
		var row := i / 4
		var cx := 40.0 + float(col) * (cw + 16.0)
		var cy := 174.0 + float(row) * (ch + 18.0)
		var is_watching := active_pose == str(t.pose)
		var card := TLRTheme.make_panel(parent, Rect2(cx, cy, cw, ch), TLRTheme.SURFACE_TEAL if is_watching else TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_TEAL if is_watching else TLRTheme.BORDER_SUBTLE, 2 if is_watching else 1, 0, 0)
		tell_cards.append(card)
		TLRTheme.make_abs_label(card, str(t.num), Rect2(18, 16, 60, 22), 14, TLRTheme.CYAN, true)
		TLRTheme.make_abs_label(card, str(t.title), Rect2(18, 44, 184, 52), 20, TLRTheme.TEXT_PRIMARY, true)
		TLRTheme.make_abs_label(card, str(t.desc), Rect2(18, 102, 184, 62), 13, TLRTheme.TEXT_MUTED, false)
		TLRTheme.make_abs_label(card, str(t.counter), Rect2(18, 172, 184, 52), 12, TLRTheme.CYAN if is_watching else TLRTheme.TEXT_DIM, true)
		card.add_child(TLRBoxerPreview.new(Rect2(204, 22, 152, 236), Color(0.55, 0.36, 0.26), str(t.pose), is_watching, false))
		TLRTheme.make_abs_label(card, "WATCHING ✓" if is_watching else "CLICK TO WATCH →", Rect2(18, 244, 184, 24), 12, TLRTheme.CYAN if is_watching else TLRTheme.TEXT_MUTED, true)
		var card_hit := Button.new()
		card_hit.position = Vector2.ZERO
		card_hit.size = Vector2(cw, ch)
		card_hit.focus_mode = Control.FOCUS_ALL
		card_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card_hit.add_theme_stylebox_override("normal", TLRTheme.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))
		card_hit.add_theme_stylebox_override("hover", TLRTheme.style_box(Color(0.14, 0.36, 0.46, 0.14), TLRTheme.BORDER_HOVER if not is_watching else TLRTheme.BORDER_TEAL, 2, 0, 0, 0))
		card_hit.add_theme_stylebox_override("focus", TLRTheme.style_box(Color(0.14, 0.36, 0.46, 0.14), TLRTheme.BORDER_TEAL, 2, 0, 0, 0))
		card_hit.add_theme_stylebox_override("pressed", TLRTheme.style_box(Color(0.08, 0.25, 0.32, 0.22), TLRTheme.BORDER_TEAL, 2, 0, 0, 0))
		card_hit.pressed.connect(main._select_practice_pose.bind(str(t.pose)))
		card.add_child(card_hit)

	var back_cb: Callable = main._show_bracket if main.game_state == "hub" else main._show_main_menu
	var back_txt := "BACK TO YOUR CORNER" if main.game_state == "hub" else "MAIN MENU"
	TLRTheme.make_abs_button(parent, back_txt, Rect2(40, 814, 260, 48), back_cb, "default", false, 14)
	TLRTheme.make_abs_button(parent, "COACH SPAR  →", Rect2(1180, 814, 380, 48), main._start_training, "teal", false, 14)
	if bool(main.animate_cards_enter):
		main.animate_cards_enter = false
		TLRTheme.stagger_enter(main, tell_cards, Vector2(0.0, 18.0), 0.22, 0.03)


# ---------------------------------------------------------
# 7. SETTINGS (UI/R25–R28)
# ---------------------------------------------------------

static func build_settings(main: Node, parent: Control) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / SETTINGS",
		"MAKE THE CORNER YOURS.",
		"Choose your preferences."
	)

	var tabs := [
		{"id": "controls", "label": "CONTROLS"},
		{"id": "audio", "label": "AUDIO"},
		{"id": "display", "label": "DISPLAY"},
		{"id": "accessibility", "label": "ACCESSIBILITY"}
	]
	var active_tab := str(main.settings_tab)
	for i in range(tabs.size()):
		var tb: Dictionary = tabs[i]
		var is_cur := active_tab == str(tb.id)
		TLRTheme.make_abs_button(parent, str(tb.label), Rect2(40, 174 + float(i) * 62.0, 290, 48), main._set_settings_tab.bind(str(tb.id)), "teal" if is_cur else "default", false, 15)

	var rx := 380.0
	var rw := 960.0
	match active_tab:
		"controls":
			var bindings := [
				["1 / 2 / 3", "Move slots 1–3 (e.g. Jab / Block / Rest)"],
				["4 / 5 / 6", "Move slots 4–6"],
				["Q / W / E", "Corner bag item slots (combat-usable items only)"],
				["TAB", "Open or close fighter drawer"],
				["ESC", "Pause or resume fight"],
				["F1", "Combat state review index"]
			]
			for i in range(bindings.size()):
				var row := TLRTheme.make_panel(parent, Rect2(rx, 174 + float(i) * 76.0, rw, 62), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
				TLRTheme.make_abs_label(row, bindings[i][0], Rect2(24, 18, 220, 26), 18, TLRTheme.CYAN, true)
				TLRTheme.make_abs_label(row, bindings[i][1], Rect2(260, 18, 670, 26), 16, TLRTheme.TEXT_PRIMARY, false)
			TLRTheme.make_abs_label(parent, "Mouse / select any control. Hover a move or item card for full details.", Rect2(rx, 646, rw, 24), 14, TLRTheme.TEXT_MUTED, false)

		"audio":
			var audio_rows := [
				{"key": "master_volume", "label": "MASTER VOLUME", "opts": [0, 50, 80, 100]},
				{"key": "music_volume", "label": "MUSIC", "opts": [0, 60, 100]},
				{"key": "sfx_volume", "label": "EFFECTS", "opts": [0, 50, 80, 100]},
				{"key": "commentary_volume", "label": "COMMENTARY", "opts": [0, 50, 80, 100]}
			]
			for i in range(audio_rows.size()):
				var ar: Dictionary = audio_rows[i]
				var val := int(main.settings.get(ar.key, 80))
				var card := TLRTheme.make_panel(parent, Rect2(rx, 174 + float(i) * 124.0, rw, 108), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
				TLRTheme.make_abs_label(card, str(ar.label), Rect2(24, 16, 400, 26), 18, TLRTheme.TEXT_PRIMARY, true)
				TLRTheme.make_abs_label(card, "%d%%" % val, Rect2(rw - 180, 16, 156, 26), 16, TLRTheme.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT)
				var opts: Array = ar.opts
				for j in range(opts.size()):
					var opt_v := int(opts[j])
					TLRTheme.make_abs_button(card, "%d%%" % opt_v, Rect2(24 + float(j) * 204.0, 52, 188, 38), main._set_setting_value.bind(str(ar.key), opt_v), "teal" if val == opt_v else "default", false, 14)

		"display":
			var win_modes := ["Windowed", "Borderless", "Fullscreen"]
			var cur_wm := str(main.settings.get("window_mode", "Windowed"))
			var wm_card := TLRTheme.make_panel(parent, Rect2(rx, 172, rw, 84), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
			TLRTheme.make_abs_label(wm_card, "WINDOW MODE", Rect2(24, 10, 400, 22), 16, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(wm_card, cur_wm, Rect2(rw - 200, 10, 176, 22), 14, TLRTheme.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT)
			for j in range(win_modes.size()):
				var o := str(win_modes[j])
				TLRTheme.make_abs_button(wm_card, o, Rect2(24 + float(j) * 194.0, 38, 180, 34), main._set_setting_value.bind("window_mode", o), "teal" if cur_wm == o else "default", false, 13)

			var asp_modes := ["Auto (Fill)", "16:9", "16:10", "21:9", "4:3"]
			var cur_am := str(main.settings.get("aspect_mode", "Auto (Fill)"))
			if cur_am == "Expand": cur_am = "Auto (Fill)"
			elif cur_am == "Keep 16:9": cur_am = "16:9"
			var am_card := TLRTheme.make_panel(parent, Rect2(rx, 266, rw, 84), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
			TLRTheme.make_abs_label(am_card, "ASPECT RATIO", Rect2(24, 10, 400, 22), 16, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(am_card, cur_am, Rect2(rw - 200, 10, 176, 22), 14, TLRTheme.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT)
			for j in range(asp_modes.size()):
				var o := str(asp_modes[j])
				TLRTheme.make_abs_button(am_card, o, Rect2(24 + float(j) * 184.0, 38, 172, 34), main._set_setting_value.bind("aspect_mode", o), "teal" if cur_am == o else "default", false, 13)

			var res_opts := [
				"Auto", "1280 × 720", "1600 × 900", "1920 × 1080",
				"2560 × 1440", "1920 × 1200", "2560 × 1080", "1280 × 960"
			]
			var cur_res := str(main.settings.get("resolution", "Auto"))
			var res_card := TLRTheme.make_panel(parent, Rect2(rx, 360, rw, 126), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
			TLRTheme.make_abs_label(res_card, "RESOLUTION", Rect2(24, 10, 400, 22), 16, TLRTheme.TEXT_PRIMARY, true)
			TLRTheme.make_abs_label(res_card, cur_res, Rect2(rw - 200, 10, 176, 22), 14, TLRTheme.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT)
			for j in range(res_opts.size()):
				var o := str(res_opts[j])
				var col_idx := j % 4
				var row_idx := j / 4
				TLRTheme.make_abs_button(res_card, o, Rect2(24 + float(col_idx) * 230.0, 38 + float(row_idx) * 42.0, 218, 34), main._set_setting_value.bind("resolution", o), "teal" if cur_res == o else "default", false, 13)

			var simple_disp := [
				{"key": "vsync", "label": "V-SYNC", "opts": [false, true], "names": ["Off", "On"]},
				{"key": "brightness", "label": "BRIGHTNESS", "opts": [25, 50, 75], "names": ["25%", "50%", "75%"]},
				{"key": "crt_enabled", "label": "CRT FILTER", "opts": [false, true], "names": ["Off", "On"]}
			]
			for i in range(simple_disp.size()):
				var dr: Dictionary = simple_disp[i]
				var cur = main.settings.get(dr.key)
				var opts: Array = dr.opts
				var names: Array = dr.names
				var cur_str := str(names[0])
				for k in range(opts.size()):
					if cur == opts[k]:
						cur_str = str(names[k])
				var card := TLRTheme.make_panel(parent, Rect2(rx, 496 + float(i) * 94.0, rw, 84), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
				TLRTheme.make_abs_label(card, str(dr.label), Rect2(24, 10, 400, 22), 16, TLRTheme.TEXT_PRIMARY, true)
				TLRTheme.make_abs_label(card, cur_str, Rect2(rw - 200, 10, 176, 22), 14, TLRTheme.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT)
				for j in range(opts.size()):
					var active: bool = (cur == opts[j])
					TLRTheme.make_abs_button(card, str(names[j]), Rect2(24 + float(j) * 194.0, 38, 180, 34), main._set_setting_value.bind(str(dr.key), opts[j]), "teal" if active else "default", false, 13)

		"accessibility":
			var acc_rows := [
				{"key": "reduced_motion", "label": "REDUCED MOTION", "opts": [false, true], "names": ["Off", "On"]},
				{"key": "screen_shake", "label": "SCREEN SHAKE", "opts": [false, true], "names": ["Off", "On"]},
				{"key": "flash_effects", "label": "FLASH EFFECTS", "opts": [false, true], "names": ["Off", "On"]},
				{"key": "text_size", "label": "TEXT SIZE", "opts": ["Standard", "Large"], "names": ["Standard", "Large"]},
				{"key": "subtitles", "label": "SUBTITLES", "opts": [false, true], "names": ["Off", "On"]},
				{"key": "contrast", "label": "CONTRAST", "opts": ["Standard", "High"], "names": ["Standard", "High"]},
				{"key": "story_cutscenes", "label": "STORY CUTSCENES", "opts": [true, false], "names": ["Auto-Play", "Skip"]}
			]
			for i in range(acc_rows.size()):
				var ar: Dictionary = acc_rows[i]
				var cur = main.settings.get(ar.key)
				var opts: Array = ar.opts
				var names: Array = ar.names
				var cur_lbl := str(names[0])
				for k in range(opts.size()):
					if cur == opts[k]:
						cur_lbl = str(names[k])
				var card := TLRTheme.make_panel(parent, Rect2(rx, 174 + float(i) * 86.0, rw, 76), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
				TLRTheme.make_abs_label(card, str(ar.label), Rect2(24, 8, 400, 22), 15, TLRTheme.TEXT_PRIMARY, true)
				TLRTheme.make_abs_label(card, cur_lbl, Rect2(rw - 180, 8, 156, 22), 14, TLRTheme.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT)
				for j in range(opts.size()):
					var active: bool = (cur == opts[j])
					TLRTheme.make_abs_button(card, str(names[j]), Rect2(24 + float(j) * 184.0, 34, 170, 32), main._set_setting_value.bind(str(ar.key), opts[j]), "teal" if active else "default", false, 13)

	TLRTheme.make_abs_button(parent, "BACK TO MAIN MENU", Rect2(40, 814, 240, 48), main._show_main_menu, "default", false, 14)
	var save_txt := "PREFERENCES SAVED ✓" if bool(main.settings_saved_notice) else "SAVE PREFERENCES"
	TLRTheme.make_abs_button(parent, save_txt, Rect2(1140, 814, 420, 48), main._save_settings, "teal", false, 14)


# ---------------------------------------------------------
# 8. CODEX
# ---------------------------------------------------------

static func build_codex(main: Node, parent: Control) -> void:
	TLRTheme.add_page_header(
		parent,
		"THE LAST ROUND / FIGHTER'S CODEX",
		"KNOWLEDGE IS WHAT YOU KEEP.",
		"Rules, archetypes, rewards, corner items, moves and tournament structure."
	)

	var tabs := [
		{"id": "core", "label": "CORE RULES"},
		{"id": "story", "label": "STORY & BIOS"},
		{"id": "enemies", "label": "ENEMY TYPES"},
		{"id": "rewards", "label": "REWARDS & STATS"},
		{"id": "items", "label": "CORNER ITEMS"},
		{"id": "moves", "label": "MOVE POOL"},
		{"id": "career", "label": "CAREER & RULES"}
	]
	var active_tab := str(main.codex_tab)
	for i in range(tabs.size()):
		var tb: Dictionary = tabs[i]
		var is_cur := active_tab == str(tb.id)
		TLRTheme.make_abs_button(parent, str(tb.label), Rect2(40, 174 + float(i) * 60.0, 290, 48), main._set_codex_tab.bind(str(tb.id)), "teal" if is_cur else "default", false, 15)

	var panel := TLRTheme.make_panel(parent, Rect2(360, 174, 1200, 608), TLRTheme.SURFACE_SOLID, TLRTheme.BORDER_SUBTLE, 1, 0, 0)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 20)
	scroll.size = Vector2(1152, 568)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)

	match active_tab:
		"story":
			col.add_child(TLRTheme.make_label("THE GLASS PIT  //  STORY CHAPTERS (WATCH IN 3D)", 18, TLRTheme.CYAN, true))
			for ch_v in TLRStory.STORY_CHAPTERS:
				var ch: Dictionary = ch_v
				var ch_id := str(ch.get("id", "prologue"))
				var ch_row := HBoxContainer.new()
				ch_row.add_theme_constant_override("separation", 16)
				col.add_child(ch_row)
				var ctext := VBoxContainer.new()
				ctext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				ch_row.add_child(ctext)
				ctext.add_child(TLRTheme.make_label("%s — %s" % [str(ch.get("act", "")), str(ch.get("title", ""))], 15, TLRTheme.AMBER, true))
				ctext.add_child(TLRTheme.make_label(str(ch.get("desc", "")), 13, TLRTheme.TEXT_MUTED, false))
				var wbtn := Button.new()
				wbtn.text = "WATCH SCENE  →"
				wbtn.custom_minimum_size = Vector2(180, 40)
				TLRTheme.style_button(wbtn, "teal", 13)
				wbtn.pressed.connect(main._replay_story_cutscene.bind(ch_id))
				ch_row.add_child(wbtn)
			col.add_child(TLRTheme.make_label("FIGHTER PROFILES  //  ALL 12 UNDERGROUND BOXERS", 18, TLRTheme.CYAN, true))
			for en_v in main.enemy_templates:
				var en: Dictionary = en_v
				var e_id := str(en.get("id", ""))
				var lore := TLRStory.get_fighter_lore(e_id)
				var e_tier := int(en.get("tier", 1))
				var t_col := TLRTheme.CORAL if e_tier >= 4 else (TLRTheme.AMBER if e_tier == 3 else TLRTheme.TEXT_PRIMARY)
				col.add_child(TLRTheme.make_label("[TIER %d • %s]  %s — %s" % [e_tier, str(en.get("archetype", "")).to_upper(), str(en.get("name", "")).to_upper(), str(lore.get("title", ""))], 15, t_col, true))
				col.add_child(TLRTheme.make_label(str(lore.get("bio", "")) + "  “" + str(lore.get("walkout", "")) + "”", 13, TLRTheme.TEXT_MUTED, false))
		"core":
			_codex_section(col, "FIGHTER STATS & COMBAT TACTICS", [
				"FIGHTING STYLES & RANDOM BRACKETS — Pick 1 of 4 Corner Styles at run start. Every run shuffles opponents, Champions, Stipulations, and Card A/B challengers.",
				"MOMENTUM CHAIN — Landing Feint, shattering High Guard, or interrupting Showboat grants 1 FREE follow-up action before the opponent swings!",
				"ADRENALINE FINISHER — Dealing & taking hits builds Adrenaline (0–100%). At 100%, your next attack becomes LIGHTS OUT (×1.75 DMG, Stagger, +$25).",
				"1-2 RHYTHM & OPENINGS — Jab/One-Two/Feint readies Rhythm (+25% DMG & +12% ACC); evading/whiffing opens Counter (+45% Counter / +25% Power).",
				"PIT BLACK MARKET & STREET EVENTS — Spend Pit Cash ($) between bouts on rotating Items (by rarity), Traits, Technique Manuals, or gamble in Street Events."
			])
		"enemies":
			_codex_section(col, "OPPONENT ARCHETYPES & SIGNATURES", [
				"BRAWLER / SLUGGER — Heavy loaded hooks. Respect the telegraphed rear-hand load.",
				"SPEEDSTER / OUT-BOXER — Fast flurries that drain stamina; low HP but tricky timing.",
				"TANK — Tight guard absorbs extra damage while healthy.",
				"COUNTER-PUNCHER — Punishes predictable aggression; mix Feints and Rhythm.",
				"DIRTY FIGHTER / BLEEDER — Inflicts stamina drain or Bleeding cuts (-4 HP/turn for 2 turns).",
				"SHOWBOAT / BERSERKER / 3 FINAL CHAMPIONS — Taunts (+35%), Enrages (≤50% HP), or Champions Undertaker, Vance & Kurosawa."
			])
		"rewards":
			_codex_section(col, "ITEM RARITY, REWARDS & PIT ECONOMY", [
				"RARITY TIERS — Items & Traits drop as COMMON (Slate), UNCOMMON (Mint), RARE (Cyan), or CONTRABAND (Amber/Gold).",
				"MOVE UPGRADE (LV.1–3) — Selecting an owned move grants +22% Move Power, -1 STA Cost, and +1 Base DMG.",
				"FIGHTING TRAIT (PERK) — Powerful passive relics (max 4 per run) earned after bouts or bought in the Black Market.",
				"QUICK-USE ITEMS — Cutman Swab, Adrenaline Vial, and Nitro Ammonia trigger WITHOUT ending your combat turn!",
				"BLACK MARKET & SELLING — Open Shop from the Hub to buy stock, reroll ($15), or sell bag items for 50% Pit Cash."
			])
			_codex_section(col, "STAT REWARDS", [
				"ROADWORK — +12 maximum stamina and recover 12 now.",
				"HEAVY HANDS — +3 damage, -2 speed.",
				"OLD LEATHER — +15 maximum health and heal 10 now.",
				"TIGHT GUARD — +4 defence.",
				"QUICK FEET — +5 speed (up to 60% cap).",
				"SECOND WIND — Recover +8 stamina after every successful dodge.",
				"CORNER'S WISDOM — Heal 12 health immediately."
			])
		"items":
			_codex_section(col, "CORNER BAG ITEMS & RARITIES", [
				"Items span COMMON, UNCOMMON, RARE, and CONTRABAND tiers. Higher-tier fights & Prize Hunter increase rare drops."
			])
			for it_v in main.item_templates:
				var it: Dictionary = it_v
				var i_id := str(it.get("id", ""))
				var rm: Dictionary = TLRTheme.rarity_meta(str(it.get("rarity", "common")))
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 14)
				col.add_child(row)
				row.add_child(TLRTheme.UIIcon.new(i_id, Color(rm.color), Vector2(24, 24)))
				var tcol := VBoxContainer.new()
				tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(tcol)
				tcol.add_child(TLRTheme.make_label("[%s • $%d]  %s — %s" % [str(rm.label), int(it.get("price", 20)), str(it.get("name", "")).to_upper(), str(it.get("description", ""))], 15, Color(rm.color) if str(it.get("rarity", "common")) != "common" else TLRTheme.TEXT_PRIMARY, true))
				tcol.add_child(TLRTheme.make_label(main._item_timing(i_id), 13, TLRTheme.TEXT_MUTED, false))
		"moves":
			_codex_section(col, "ALL MOVES", [])
			for mv_v in main.moves:
				var mv: Dictionary = mv_v
				var m_id := str(mv.get("id", ""))
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 14)
				col.add_child(row)
				row.add_child(TLRTheme.UIIcon.new(m_id, TLRTheme.TEXT_PRIMARY, Vector2(24, 24)))
				var tcol := VBoxContainer.new()
				tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(tcol)
				tcol.add_child(TLRTheme.make_label("%s (%d STA)" % [str(mv.get("name", "")).to_upper(), int(mv.get("cost", 0))], 15, TLRTheme.TEXT_PRIMARY, true))
				tcol.add_child(TLRTheme.make_label(main._move_reward_details(mv), 13, TLRTheme.TEXT_MUTED, false))
		"career":
			_codex_section(col, "CAREER RESPECT PERKS", [
				"50 Respect — Grit: +5 max health on fresh runs.",
				"200 Respect — Conditioning: +5 max stamina on fresh runs.",
				"500 Respect — Power: +1 damage on fresh runs.",
				"1000 Respect — Guard: +1 defence on fresh runs.",
				"Perks are cumulative and never stack a second time when continuing a saved run."
			])
			_codex_section(col, "TOURNAMENT RULES", [
				"8 fights per run: 4 opening bouts, 2 semi-finals, 1 title eliminator, 1 final championship.",
				"3 rounds per fight, 6 player turns per round. Stamina recovers (+14) between rounds.",
				"Win a fight to choose one reward and restore +10 HP / +20 STA before the next fight.",
				"If neither fighter is knocked out after 3 rounds, judges award the bout by remaining health."
			])

	var back_cb: Callable = main._show_bracket if main.game_state == "hub" else main._show_main_menu
	TLRTheme.make_abs_button(parent, "BACK TO YOUR CORNER" if main.game_state == "hub" else "BACK TO MAIN MENU", Rect2(40, 814, 260, 48), back_cb, "teal", false, 14)


static func _codex_section(parent: VBoxContainer, heading: String, lines: Array) -> void:
	parent.add_child(TLRTheme.make_label(heading, 18, TLRTheme.CYAN, true))
	for ln in lines:
		parent.add_child(TLRTheme.make_label("•  " + str(ln), 14, TLRTheme.TEXT_PRIMARY, false))


static func _word_num(n: int) -> String:
	match n:
		1: return "ONE"
		2: return "TWO"
		3: return "THREE"
		4: return "FOUR"
		5: return "FIVE"
		6: return "SIX"
		7: return "SEVEN"
		8: return "EIGHT"
		_: return str(n)
