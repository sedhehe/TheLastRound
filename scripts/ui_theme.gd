extends RefCounted

# Exact sampled palette from UI/ reference PNGs
const BG_DARK := Color(0.027, 0.067, 0.122, 1.0)         # #07111F
const BG_DEEP := Color(0.012, 0.039, 0.082, 1.0)         # #030A15
const SURFACE := Color(0.039, 0.090, 0.157, 0.96)        # #0A1728
const SURFACE_SOLID := Color(0.039, 0.090, 0.157, 1.0)   # #0A1728
const SURFACE_DARK := Color(0.031, 0.075, 0.129, 0.96)   # #081321
const SURFACE_HOVER := Color(0.063, 0.153, 0.235, 0.98)
const SURFACE_TEAL := Color(0.051, 0.129, 0.200, 0.96)   # #0D2133
const SURFACE_AMBER := Color(0.165, 0.110, 0.047, 0.92)
const SURFACE_CRIMSON := Color(0.180, 0.050, 0.063, 0.92)

const BORDER_SUBTLE := Color(0.161, 0.263, 0.341, 0.95)  # #294357
const BORDER_CARD := Color(0.125, 0.212, 0.294, 0.95)    # #20364B
const BORDER_HOVER := Color(0.84, 0.90, 0.95, 0.95)
const BORDER_TEAL := Color(0.28, 0.68, 0.72, 1.0)
const BORDER_AMBER := Color(0.68, 0.45, 0.18, 0.95)
const BORDER_CRIMSON := Color(0.68, 0.20, 0.22, 0.95)

const ACCENT_ORANGE := Color(0.937, 0.286, 0.180, 1.0)   # #EF492E
const CORAL := Color(0.929, 0.318, 0.302, 1.0)           # #ED514D
const CORAL_GHOST := Color(0.235, 0.125, 0.169, 0.92)    # #3C202B
const CORAL_TRAIL := Color(0.75, 0.56, 0.36, 0.92)
const BLUE := Color(0.24, 0.60, 0.93, 1.0)
const BLUE_GHOST := Color(0.086, 0.169, 0.263, 0.92)
const MINT := Color(0.36, 0.83, 0.69, 1.0)
const CYAN := Color(0.35, 0.78, 0.84, 1.0)
const AMBER := Color(0.92, 0.68, 0.35, 1.0)
const TEXT_PRIMARY := Color(0.929, 0.957, 0.980, 1.0)    # #EDF4FA
const TEXT_MUTED := Color(0.56, 0.65, 0.74, 1.0)
const TEXT_DIM := Color(0.38, 0.46, 0.55, 1.0)

static var _font_hero: Font
static var _font_display: Font
static var _font_body: Font
static var text_scale: float = 1.0
static var high_contrast: bool = false


static func apply_accessibility(large_text: bool, hi_contrast: bool) -> void:
	text_scale = 1.14 if large_text else 1.0
	high_contrast = hi_contrast


static func c_border_subtle() -> Color:
	return Color(0.32, 0.52, 0.68, 1.0) if high_contrast else BORDER_SUBTLE


static func c_border_card() -> Color:
	return Color(0.28, 0.48, 0.64, 1.0) if high_contrast else BORDER_CARD


static func c_text_muted() -> Color:
	return Color(0.76, 0.84, 0.92, 1.0) if high_contrast else TEXT_MUTED


static func c_text_dim() -> Color:
	return Color(0.62, 0.72, 0.82, 1.0) if high_contrast else TEXT_DIM


static func font_hero() -> Font:
	if _font_hero == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray([
			"Barlow Condensed",
			"Impact",
			"Bahnschrift",
			"Arial Narrow"
		])
		sf.font_stretch = 75
		sf.font_weight = 800
		_font_hero = sf
	return _font_hero


static func font_display() -> Font:
	if _font_display == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray([
			"Barlow Condensed",
			"Bahnschrift",
			"Arial Narrow",
			"Impact"
		])
		sf.font_stretch = 75
		sf.font_weight = 700
		_font_display = sf
	return _font_display


static func font_body() -> Font:
	if _font_body == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray([
			"Barlow",
			"Bahnschrift",
			"Segoe UI",
			"Arial"
		])
		sf.font_weight = 400
		_font_body = sf
	return _font_body


static func style_box(
	bg: Color,
	border: Color = BORDER_SUBTLE,
	border_w: int = 2,
	radius: int = 0,
	pad_h: int = 16,
	pad_v: int = 12
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if high_contrast and border == BORDER_SUBTLE:
		s.border_color = c_border_subtle()
	elif high_contrast and border == BORDER_CARD:
		s.border_color = c_border_card()
	else:
		s.border_color = border
	var bw := maxi(2, border_w) if border_w > 0 else 0
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	return s


static func make_label(
	text: String,
	size: int = 16,
	color: Color = TEXT_PRIMARY,
	display: bool = false,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", font_display() if display else font_body())
	var scaled_sz := mini(26, roundi(float(size) * text_scale)) if size <= 24 else size
	lbl.add_theme_font_size_override("font_size", scaled_sz)
	var final_col := color
	if high_contrast:
		if color == TEXT_MUTED:
			final_col = c_text_muted()
		elif color == TEXT_DIM:
			final_col = c_text_dim()
	lbl.add_theme_color_override("font_color", final_col)
	lbl.horizontal_alignment = align
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


static func make_abs_label(
	parent: Control,
	text: String,
	rect: Rect2,
	size: int = 16,
	color: Color = TEXT_PRIMARY,
	display: bool = false,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP,
	hero_font: bool = false
) -> Label:
	var lbl := make_label(text, size, color, display, align)
	if hero_font:
		lbl.add_theme_font_override("font", font_hero())
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.vertical_alignment = valign
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl


static func make_panel(
	parent: Control,
	rect: Rect2,
	bg: Color = SURFACE,
	border: Color = BORDER_SUBTLE,
	border_w: int = 2,
	pad_h: int = 0,
	pad_v: int = 0
) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", style_box(bg, border, border_w, 0, pad_h, pad_v))
	parent.add_child(p)
	return p


static func style_button(
	btn: Button,
	variant: String = "default",
	font_sz: int = 14
) -> void:
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", font_display())
	btn.add_theme_font_size_override("font_size", mini(22, roundi(float(font_sz) * text_scale)) if font_sz <= 18 else font_sz)

	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var disabled := style_box(Color(0.025, 0.052, 0.090, 0.72), Color(0.11, 0.18, 0.26, 0.75), 2, 0, 16, 10)

	match variant:
		"orange":
			normal = style_box(ACCENT_ORANGE, ACCENT_ORANGE, 2, 0, 22, 12)
			hover = style_box(Color(1.0, 0.35, 0.22, 1.0), Color(1.0, 0.55, 0.42, 1.0), 2, 0, 22, 12)
			pressed = style_box(Color(0.82, 0.22, 0.12, 1.0), ACCENT_ORANGE, 2, 0, 22, 12)
			btn.add_theme_color_override("font_color", Color(0.04, 0.06, 0.09, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.04, 0.06, 0.09, 1.0))
			btn.add_theme_color_override("font_focus_color", Color(0.04, 0.06, 0.09, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.04, 0.06, 0.09, 1.0))
		"teal":
			normal = style_box(SURFACE_TEAL, BORDER_TEAL, 2, 0, 18, 10)
			hover = style_box(Color(0.075, 0.195, 0.285, 0.98), BORDER_HOVER, 2, 0, 18, 10)
			pressed = style_box(Color(0.045, 0.125, 0.160, 0.98), BORDER_TEAL, 2, 0, 18, 10)
			btn.add_theme_color_override("font_color", CYAN)
			btn.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
			btn.add_theme_color_override("font_focus_color", TEXT_PRIMARY)
		"ghost":
			normal = style_box(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0, 0, 10, 6)
			hover = style_box(Color(0.07, 0.14, 0.22, 0.65), BORDER_SUBTLE, 2, 0, 10, 6)
			pressed = style_box(SURFACE, BORDER_TEAL, 2, 0, 10, 6)
			btn.add_theme_color_override("font_color", TEXT_MUTED)
			btn.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
			btn.add_theme_color_override("font_focus_color", TEXT_PRIMARY)
		_:
			normal = style_box(SURFACE, BORDER_SUBTLE, 2, 0, 18, 10)
			hover = style_box(SURFACE_HOVER, BORDER_HOVER, 2, 0, 18, 10)
			pressed = style_box(SURFACE_TEAL, BORDER_TEAL, 2, 0, 18, 10)
			btn.add_theme_color_override("font_color", TEXT_PRIMARY)
			btn.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
			btn.add_theme_color_override("font_focus_color", TEXT_PRIMARY)

	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)


static func make_abs_button(
	parent: Control,
	text: String,
	rect: Rect2,
	callback: Callable,
	variant: String = "default",
	disabled: bool = false,
	font_sz: int = 14
) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.disabled = disabled
	style_button(btn, variant, font_sz)
	if callback.is_valid():
		btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


static func add_page_header(
	parent: Control,
	breadcrumb: String,
	title: String,
	subtitle: String,
	title_color: Color = TEXT_PRIMARY
) -> void:
	make_abs_label(parent, breadcrumb.to_upper(), Rect2(40, 30, 1400, 20), 12, CYAN, false)
	make_abs_label(parent, title.to_upper(), Rect2(40, 56, 1520, 52), 44, title_color, true)
	if not subtitle.is_empty():
		make_abs_label(parent, subtitle, Rect2(40, 112, 1520, 24), 15, TEXT_MUTED, false)


static func add_progress_bar(
	parent: Control,
	rect: Rect2,
	value: float,
	maximum: float,
	fill_color: Color,
	bg_color: Color = Color(0.11, 0.17, 0.24, 0.9)
) -> Control:
	var track := ColorRect.new()
	track.position = rect.position
	track.size = rect.size
	track.color = bg_color
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)

	var ratio := clampf(value / maxf(1.0, maximum), 0.0, 1.0)
	var fill := ColorRect.new()
	fill.position = Vector2.ZERO
	fill.size = Vector2(rect.size.x * ratio, rect.size.y)
	fill.color = fill_color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	return track


static func stagger_enter(main: Node, nodes: Array, offset: Vector2 = Vector2(0.0, 10.0), duration: float = 0.16, step_delay: float = 0.025) -> void:
	if DisplayServer.get_name() == "headless" or bool(main.settings.get("reduced_motion", false)):
		return
	for i in range(nodes.size()):
		var ctrl := nodes[i] as Control
		if not is_instance_valid(ctrl):
			continue
		var target_pos := ctrl.position
		ctrl.position = target_pos + offset
		var tw := main.create_tween()
		var d := float(i) * step_delay
		tw.tween_property(ctrl, "position", target_pos, duration).set_delay(d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


class UISlantedBar extends Control:
	var ratio: float = 1.0
	var trail_ratio: float = 1.0
	var fill_color: Color = CORAL
	var track_color: Color = CORAL_GHOST
	var trail_color: Color = CORAL_TRAIL
	var rtl: bool = false

	func _init(
		p_rect: Rect2,
		p_ratio: float,
		p_trail_ratio: float,
		p_fill: Color,
		p_track: Color,
		p_trail: Color = CORAL_TRAIL,
		p_rtl: bool = false
	) -> void:
		position = p_rect.position
		size = p_rect.size
		ratio = clampf(p_ratio, 0.0, 1.0)
		trail_ratio = clampf(maxf(p_ratio, p_trail_ratio), 0.0, 1.0)
		fill_color = p_fill
		track_color = p_track
		trail_color = p_trail
		rtl = p_rtl
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_ratio(v: float) -> void:
		ratio = clampf(v, 0.0, 1.0)
		queue_redraw()

	func _poly(r: float) -> PackedVector2Array:
		var w := size.x
		var h := size.y
		var skew := h * 0.95
		var len_top := maxf(0.0, w * r)
		var len_bot := maxf(0.0, len_top - skew)
		if r <= 0.001:
			return PackedVector2Array()
		if not rtl:
			return PackedVector2Array([
				Vector2(0.0, 0.0),
				Vector2(len_top, 0.0),
				Vector2(len_bot, h),
				Vector2(0.0, h)
			])
		else:
			return PackedVector2Array([
				Vector2(w - len_top, 0.0),
				Vector2(w, 0.0),
				Vector2(w, h),
				Vector2(w - len_bot, h)
			])

	func _draw() -> void:
		var track := _poly(1.0)
		if track.size() == 4:
			draw_colored_polygon(track, track_color)
		if trail_ratio > ratio + 0.004:
			var trail := _poly(trail_ratio)
			if trail.size() == 4:
				draw_colored_polygon(trail, trail_color)
		var fill := _poly(ratio)
		if fill.size() == 4:
			draw_colored_polygon(fill, fill_color)


class UIIcon extends Control:
	var icon_id: String = ""
	var tint: Color = Color(0.88, 0.93, 0.98, 1.0)
	var stroke: float = 1.8

	func _init(p_id: String = "", p_tint: Color = Color(0.88, 0.93, 0.98, 1.0), p_size: Vector2 = Vector2(24, 24)) -> void:
		icon_id = p_id
		tint = p_tint
		custom_minimum_size = p_size
		size = p_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var cy := h * 0.5
		var r := minf(w, h) * 0.38
		var c := tint

		match icon_id:
			"jab", "one_two":
				draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), c, stroke, true)
				draw_line(Vector2(cx + r * 0.25, cy - r * 0.55), Vector2(cx + r, cy), c, stroke, true)
				draw_line(Vector2(cx + r * 0.25, cy + r * 0.55), Vector2(cx + r, cy), c, stroke, true)
				if icon_id == "one_two":
					draw_line(Vector2(cx - r, cy - r * 0.45), Vector2(cx + r * 0.45, cy - r * 0.45), c, stroke * 0.85, true)
			"uppercut":
				draw_line(Vector2(cx, cy + r), Vector2(cx, cy - r), c, stroke, true)
				draw_line(Vector2(cx - r * 0.55, cy - r * 0.25), Vector2(cx, cy - r), c, stroke, true)
				draw_line(Vector2(cx + r * 0.55, cy - r * 0.25), Vector2(cx, cy - r), c, stroke, true)
			"hook", "haymaker", "overhand":
				draw_arc(Vector2(cx - r * 0.1, cy + r * 0.1), r * 0.72, -PI * 0.85, PI * 0.25, 16, c, stroke, true)
				draw_line(Vector2(cx + r * 0.62, cy + r * 0.1), Vector2(cx + r * 0.25, cy - r * 0.3), c, stroke, true)
				draw_line(Vector2(cx + r * 0.62, cy + r * 0.1), Vector2(cx + r * 0.9, cy - r * 0.25), c, stroke, true)
			"body_shot":
				draw_line(Vector2(cx - r * 0.75, cy - r * 0.75), Vector2(cx + r * 0.75, cy + r * 0.75), c, stroke, true)
				draw_line(Vector2(cx + r * 0.75, cy + r * 0.1), Vector2(cx + r * 0.75, cy + r * 0.75), c, stroke, true)
				draw_line(Vector2(cx + r * 0.1, cy + r * 0.75), Vector2(cx + r * 0.75, cy + r * 0.75), c, stroke, true)
			"block":
				var pts := PackedVector2Array([
					Vector2(cx, cy - r),
					Vector2(cx + r * 0.82, cy - r * 0.55),
					Vector2(cx + r * 0.72, cy + r * 0.28),
					Vector2(cx, cy + r),
					Vector2(cx - r * 0.72, cy + r * 0.28),
					Vector2(cx - r * 0.82, cy - r * 0.55),
					Vector2(cx, cy - r)
				])
				draw_polyline(pts, c, stroke, true)
			"slip", "dodge":
				draw_arc(Vector2(cx + r * 0.25, cy + r * 0.15), r * 0.55, -PI * 0.5, PI * 0.5, 14, c, stroke, true)
				draw_line(Vector2(cx - r * 0.7, cy - r * 0.4), Vector2(cx + r * 0.25, cy - r * 0.4), c, stroke, true)
				draw_line(Vector2(cx - r * 0.7, cy + r * 0.7), Vector2(cx + r * 0.25, cy + r * 0.7), c, stroke, true)
				draw_line(Vector2(cx - r * 0.25, cy - r * 0.82), Vector2(cx - r * 0.7, cy - r * 0.4), c, stroke, true)
				draw_line(Vector2(cx - r * 0.25, cy + r * 0.02), Vector2(cx - r * 0.7, cy - r * 0.4), c, stroke, true)
			"counter":
				draw_line(Vector2(cx - r * 0.7, cy - r * 0.3), Vector2(cx + r * 0.2, cy - r * 0.3), c, stroke, true)
				draw_line(Vector2(cx + r * 0.2, cy - r * 0.3), Vector2(cx + r * 0.2, cy + r * 0.65), c, stroke, true)
				draw_line(Vector2(cx - r * 0.25, cy - r * 0.72), Vector2(cx - r * 0.7, cy - r * 0.3), c, stroke, true)
				draw_line(Vector2(cx - r * 0.25, cy + r * 0.12), Vector2(cx - r * 0.7, cy - r * 0.3), c, stroke, true)
				draw_line(Vector2(cx - r * 0.15, cy + r * 0.3), Vector2(cx + r * 0.2, cy + r * 0.65), c, stroke, true)
				draw_line(Vector2(cx + r * 0.55, cy + r * 0.3), Vector2(cx + r * 0.2, cy + r * 0.65), c, stroke, true)
			"clinch":
				draw_arc(Vector2(cx - r * 0.28, cy + r * 0.28), r * 0.42, 0.0, TAU, 16, c, stroke, true)
				draw_arc(Vector2(cx + r * 0.28, cy - r * 0.28), r * 0.42, 0.0, TAU, 16, c, stroke, true)
			"rest":
				var box := Rect2(cx - r * 0.9, cy - r * 0.52, r * 1.65, r * 1.04)
				draw_rect(box, c, false, stroke)
				draw_rect(Rect2(cx + r * 0.76, cy - r * 0.22, r * 0.22, r * 0.44), c, true)
				for i in range(3):
					var bx := cx - r * 0.62 + i * r * 0.44
					draw_line(Vector2(bx, cy - r * 0.26), Vector2(bx, cy + r * 0.26), c, stroke, true)
			"feint":
				draw_line(Vector2(cx - r * 0.75, cy + r * 0.4), Vector2(cx, cy - r * 0.15), c, stroke, true)
				draw_line(Vector2(cx, cy - r * 0.15), Vector2(cx + r * 0.75, cy - r * 0.65), c, stroke, true)
				draw_line(Vector2(cx, cy - r * 0.15), Vector2(cx + r * 0.75, cy + r * 0.45), c, stroke, true)
			"headbutt", "low_blow":
				var pts := PackedVector2Array([
					Vector2(cx, cy - r), Vector2(cx + r, cy), Vector2(cx, cy + r), Vector2(cx - r, cy), Vector2(cx, cy - r)
				])
				draw_polyline(pts, c, stroke, true)
				draw_line(Vector2(cx, cy - r * 0.45), Vector2(cx, cy + r * 0.1), c, stroke, true)
				draw_circle(Vector2(cx, cy + r * 0.42), 1.5, c)
			"energy":
				draw_rect(Rect2(cx - r * 0.28, cy - r * 0.95, r * 0.56, r * 0.30), c, false, stroke)
				var pts := PackedVector2Array([
					Vector2(cx - r * 0.28, cy - r * 0.65),
					Vector2(cx - r * 0.55, cy - r * 0.25),
					Vector2(cx - r * 0.55, cy + r * 0.88),
					Vector2(cx + r * 0.55, cy + r * 0.88),
					Vector2(cx + r * 0.55, cy - r * 0.25),
					Vector2(cx + r * 0.28, cy - r * 0.65)
				])
				draw_polyline(pts, c, stroke, true)
				draw_line(Vector2(cx - r * 0.50, cy + r * 0.15), Vector2(cx + r * 0.50, cy + r * 0.15), c, stroke * 0.8, true)
			"ice":
				for k in range(3):
					var ang := k * PI / 3.0
					var d := Vector2(cos(ang), sin(ang)) * r * 0.95
					draw_line(Vector2(cx, cy) - d, Vector2(cx, cy) + d, c, stroke, true)
			"salts":
				draw_rect(Rect2(cx - r * 0.30, cy - r * 0.92, r * 0.60, r * 0.24), c, false, stroke)
				draw_rect(Rect2(cx - r * 0.54, cy - r * 0.68, r * 1.08, r * 1.56), c, false, stroke)
				draw_line(Vector2(cx - r * 0.26, cy + r * 0.10), Vector2(cx + r * 0.26, cy + r * 0.10), c, stroke, true)
				draw_line(Vector2(cx, cy - r * 0.16), Vector2(cx, cy + r * 0.36), c, stroke, true)
			"vaseline":
				draw_arc(Vector2(cx, cy), r * 0.72, 0.0, TAU, 18, c, stroke, true)
				draw_circle(Vector2(cx, cy), r * 0.22, c)
			"rosin":
				draw_circle(Vector2(cx, cy), r * 0.32, c)
				for k in range(6):
					var a := k * TAU / 6.0
					draw_line(Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r * 0.5, Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r * 0.92, c, stroke * 0.85, true)
			"loaded_tape":
				draw_arc(Vector2(cx, cy), r * 0.78, 0.0, TAU, 18, c, stroke, true)
				draw_arc(Vector2(cx, cy), r * 0.32, 0.0, TAU, 14, c, stroke, true)
			"bribe":
				draw_rect(Rect2(cx - r * 0.85, cy - r * 0.55, r * 1.7, r * 1.1), c, false, stroke)
				draw_line(Vector2(cx - r * 0.85, cy - r * 0.55), Vector2(cx, cy + r * 0.15), c, stroke, true)
				draw_line(Vector2(cx + r * 0.85, cy - r * 0.55), Vector2(cx, cy + r * 0.15), c, stroke, true)
			"crowd":
				var pts := PackedVector2Array()
				for k in range(10):
					var ang := -PI * 0.5 + k * PI / 5.0
					var rad := r * 0.95 if k % 2 == 0 else r * 0.42
					pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
				pts.append(pts[0])
				draw_polyline(pts, c, stroke, true)
			_:
				draw_arc(Vector2(cx, cy), r * 0.65, 0.0, TAU, 16, c, stroke, true)


class UISegmentBar extends Control:
	var total_segments: int = 8
	var filled_segments: int = 0
	var fill_color: Color = ACCENT_ORANGE
	var empty_color: Color = Color(0.14, 0.21, 0.29, 0.9)

	func _init(p_total: int = 8, p_filled: int = 0, p_fill: Color = ACCENT_ORANGE) -> void:
		total_segments = maxi(1, p_total)
		filled_segments = clampi(p_filled, 0, total_segments)
		fill_color = p_fill
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var gap := 8.0
		var seg_w := maxf(4.0, (size.x - gap * float(total_segments - 1)) / float(total_segments))
		for i in range(total_segments):
			var rx := i * (seg_w + gap)
			var col := fill_color if i < filled_segments else empty_color
			draw_rect(Rect2(rx, 0.0, seg_w, size.y), col, true)
