extends RefCounted


static func make_flat_material(color: Color, roughness: float = 0.72, grime_tex: Texture2D = null) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.04
	if grime_tex != null:
		mat.albedo_texture = grime_tex
	return mat


static func make_grime_texture(base_col: Color, contrast: float = 0.14, seed_val: int = 1337, freq: float = 0.08) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.seed = seed_val
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = freq
	noise.fractal_octaves = 3

	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var n := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var grain := ((x * 73856093 ^ y * 19349663) & 15) / 15.0 - 0.5
			var shade := 1.0 + (n - 0.5) * contrast * 2.0 + grain * contrast * 0.45
			var c := Color(
				clampf(base_col.r * shade, 0.0, 1.0),
				clampf(base_col.g * shade, 0.0, 1.0),
				clampf(base_col.b * shade, 0.0, 1.0),
				base_col.a
			)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func make_faceted_box(size: Vector3) -> ArrayMesh:
	var bm := BoxMesh.new()
	bm.size = size
	return _to_flat_mesh(bm)


static func make_faceted_taper(top_r: Vector2, bot_r: Vector2, height: float, sides: int = 8, mid_bulge: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings := [
		{"y": -height * 0.5, "rx": bot_r.x, "rz": bot_r.y},
		{"y": 0.0, "rx": (top_r.x + bot_r.x) * 0.5 * mid_bulge, "rz": (top_r.y + bot_r.y) * 0.5 * mid_bulge},
		{"y": height * 0.5, "rx": top_r.x, "rz": top_r.y}
	]

	var ring_pts: Array = []
	for r_info in rings:
		var pts: Array[Vector3] = []
		for i in range(sides):
			var ang := float(i) / float(sides) * TAU + PI / float(sides)
			pts.append(Vector3(cos(ang) * float(r_info.rx), float(r_info.y), sin(ang) * float(r_info.rz)))
		ring_pts.append(pts)

	for r_idx in range(rings.size() - 1):
		var a_pts: Array = ring_pts[r_idx]
		var b_pts: Array = ring_pts[r_idx + 1]
		for i in range(sides):
			var nxt := (i + 1) % sides
			var p0: Vector3 = a_pts[i]
			var p1: Vector3 = a_pts[nxt]
			var p2: Vector3 = b_pts[nxt]
			var p3: Vector3 = b_pts[i]
			_add_flat_tri(st, p0, p1, p2)
			_add_flat_tri(st, p0, p2, p3)

	var bot_c := Vector3(0.0, -height * 0.5, 0.0)
	var top_c := Vector3(0.0, height * 0.5, 0.0)
	var b0: Array = ring_pts[0]
	var t0: Array = ring_pts[rings.size() - 1]
	for i in range(sides):
		var nxt := (i + 1) % sides
		_add_flat_tri(st, bot_c, b0[nxt], b0[i])
		_add_flat_tri(st, top_c, t0[i], t0[nxt])

	return st.commit()


static func make_faceted_sphere(radius: float, scale_v: Vector3 = Vector3.ONE, rings: int = 4, segs: int = 8) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = segs
	sm.rings = rings
	return _to_flat_mesh(sm, scale_v)


static func _to_flat_mesh(src: PrimitiveMesh, scale_v: Vector3 = Vector3.ONE) -> ArrayMesh:
	var arrays := src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	if indices.size() > 0:
		for i in range(0, indices.size(), 3):
			var a := verts[indices[i]] * scale_v
			var b := verts[indices[i + 1]] * scale_v
			var c := verts[indices[i + 2]] * scale_v
			var ua := uvs[indices[i]] if uvs.size() > indices[i] else Vector2.ZERO
			var ub := uvs[indices[i + 1]] if uvs.size() > indices[i + 1] else Vector2.ZERO
			var uc := uvs[indices[i + 2]] if uvs.size() > indices[i + 2] else Vector2.ZERO
			_add_flat_tri_uv(st, a, b, c, ua, ub, uc)
	else:
		for i in range(0, verts.size(), 3):
			_add_flat_tri(st, verts[i] * scale_v, verts[i + 1] * scale_v, verts[i + 2] * scale_v)
	return st.commit()


static func _add_flat_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (c - a).cross(b - a).normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


static func _add_flat_tri_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var n := (c - a).cross(b - a).normalized()
	st.set_normal(n)
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_uv(uc)
	st.add_vertex(c)


static func build_boxer_rig(
	parent: Node3D,
	skin_color: Color = Color(0.62, 0.43, 0.31),
	shorts_color: Color = Color(0.05, 0.07, 0.10),
	glove_color: Color = Color(0.48, 0.06, 0.05),
	hair_color: Color = Color(0.07, 0.07, 0.09)
) -> Dictionary:
	var skin_tex := make_grime_texture(skin_color, 0.07, 701, 0.14)
	var shorts_tex := make_grime_texture(shorts_color, 0.14, 702, 0.12)
	var glove_tex := make_grime_texture(glove_color, 0.12, 703, 0.16)

	# Sweat-sheen roughness on skin so overhead spot highlights pecs, shoulders, abs & cheekbones
	var skin_mat := make_flat_material(Color(1, 1, 1), 0.44, skin_tex)
	var torso_mat := make_flat_material(Color(1, 1, 1), 0.42, skin_tex)
	var shorts_mat := make_flat_material(Color(1, 1, 1), 0.86, shorts_tex)
	var glove_mat := make_flat_material(Color(1, 1, 1), 0.44, glove_tex)
	var hair_mat := make_flat_material(hair_color, 0.88)
	var band_mat := make_flat_material(shorts_color.lightened(0.22), 0.82)
	var tape_mat := make_flat_material(Color(0.76, 0.78, 0.80), 0.90)
	var lace_mat := make_flat_material(Color(0.62, 0.64, 0.68), 0.85)

	# Athletic V-taper chest + sloped trapezius bridge + sculpted abs & obliques
	var traps := _add_mesh(parent, "Traps", make_faceted_taper(Vector2(0.14, 0.11), Vector2(0.34, 0.175), 0.15, 10, 1.02), Vector3(0.0, 1.84, 0.0), torso_mat)
	traps.rotation.x = 0.06
	var chest := _add_mesh(parent, "Chest", make_faceted_taper(Vector2(0.35, 0.21), Vector2(0.235, 0.165), 0.42, 10, 1.05), Vector3(0.0, 1.59, 0.015), torso_mat)
	var l_pec := _add_mesh(parent, "LPec", make_faceted_box(Vector3(0.185, 0.125, 0.075)), Vector3(-0.118, 1.66, 0.158), torso_mat)
	l_pec.rotation_degrees = Vector3(-8.0, -14.0, 5.0)
	var r_pec := _add_mesh(parent, "RPec", make_faceted_box(Vector3(0.185, 0.125, 0.075)), Vector3(0.118, 1.66, 0.158), torso_mat)
	r_pec.rotation_degrees = Vector3(-8.0, 14.0, -5.0)
	# Ribcage/Abdominal taper + 6-pack abs & obliques
	_add_mesh(parent, "Waist", make_faceted_taper(Vector2(0.235, 0.165), Vector2(0.255, 0.175), 0.30, 10, 0.98), Vector3(0.0, 1.26, 0.01), torso_mat)
	for ab_row in range(3):
		var ay := 1.44 - float(ab_row) * 0.092
		var az := 0.162 - float(ab_row) * 0.005
		_add_mesh(parent, "LAbs_%d" % ab_row, make_faceted_box(Vector3(0.082, 0.068, 0.04)), Vector3(-0.052, ay, az), torso_mat)
		_add_mesh(parent, "RAbs_%d" % ab_row, make_faceted_box(Vector3(0.082, 0.068, 0.04)), Vector3(0.052, ay, az), torso_mat)
	for side_s in [-1.0, 1.0]:
		var ob := _add_mesh(parent, "Oblique_%s" % ("L" if side_s < 0.0 else "R"), make_faceted_box(Vector3(0.05, 0.22, 0.13)), Vector3(side_s * 0.215, 1.32, 0.02), torso_mat)
		ob.rotation_degrees = Vector3(0.0, 0.0, side_s * -7.0)

	# Muscular neck + clean human-proportioned boxer head (no forehead clipping)
	_add_mesh(parent, "Neck", make_faceted_taper(Vector2(0.105, 0.10), Vector2(0.135, 0.118), 0.17, 10, 1.0), Vector3(0.0, 1.94, 0.01), skin_mat)
	var head := _add_mesh(parent, "Head", make_faceted_sphere(0.142, Vector3(0.92, 1.14, 1.04), 5, 12), Vector3(0.0, 2.13, 0.035), skin_mat)
	head.rotation_degrees.x = 5.0
	_add_mesh(head, "Brow", make_faceted_box(Vector3(0.175, 0.032, 0.055)), Vector3(0.0, 0.042, 0.112), skin_mat)
	_add_mesh(head, "EyeShadow", make_faceted_box(Vector3(0.155, 0.024, 0.032)), Vector3(0.0, 0.016, 0.122), make_flat_material(Color(0.035, 0.025, 0.025), 0.96))
	_add_mesh(head, "Nose", make_faceted_box(Vector3(0.038, 0.060, 0.052)), Vector3(0.0, -0.012, 0.134), skin_mat)
	_add_mesh(head, "MouthLine", make_faceted_box(Vector3(0.064, 0.012, 0.024)), Vector3(0.0, -0.062, 0.120), make_flat_material(Color(0.05, 0.03, 0.03), 0.94))
	_add_mesh(head, "Jaw", make_faceted_taper(Vector2(0.112, 0.108), Vector2(0.075, 0.092), 0.09, 8, 1.0), Vector3(0.0, -0.105, 0.018), skin_mat)
	_add_mesh(head, "LEar", make_faceted_box(Vector3(0.022, 0.062, 0.038)), Vector3(-0.132, 0.0, 0.0), skin_mat)
	_add_mesh(head, "REar", make_faceted_box(Vector3(0.022, 0.062, 0.038)), Vector3(0.132, 0.0, 0.0), skin_mat)
	# Clean dark cropped hair cap sitting flush on upper cranium
	_add_mesh(head, "HairTop", make_faceted_sphere(0.145, Vector3(0.94, 0.68, 1.06), 4, 12), Vector3(0.0, 0.078, -0.012), hair_mat)
	_add_mesh(head, "HairBack", make_faceted_taper(Vector2(0.128, 0.128), Vector2(0.105, 0.105), 0.13, 8, 1.0), Vector3(0.0, 0.015, -0.048), hair_mat)

	# Tailored boxing trunks (waistband + fitted legs)
	_add_mesh(parent, "Belt", make_faceted_taper(Vector2(0.265, 0.185), Vector2(0.285, 0.195), 0.09, 10, 1.0), Vector3(0.0, 1.11, 0.0), band_mat)
	var pelvis := _add_mesh(parent, "Shorts", make_faceted_taper(Vector2(0.285, 0.195), Vector2(0.305, 0.205), 0.22, 10, 1.02), Vector3(0.0, 0.96, 0.0), shorts_mat)
	var l_cuff := _add_limb_faceted(pelvis, Vector3(-0.165, -0.04, 0.02), Vector3(-0.195, -0.26, 0.07), 0.148, shorts_mat)
	var r_cuff := _add_limb_faceted(pelvis, Vector3(0.165, -0.04, -0.02), Vector3(0.205, -0.26, -0.06), 0.148, shorts_mat)
	l_cuff.name = "LShortLeg"
	r_cuff.name = "RShortLeg"

	# Realistic athletic human legs (50% of total body height) with knee joints & high-top boxing boots
	var l_knee_pos := Vector3(-0.205, 0.52, 0.10)
	var r_knee_pos := Vector3(0.225, 0.52, -0.08)
	var l_ankle_pos := Vector3(-0.205, 0.14, 0.08)
	var r_ankle_pos := Vector3(0.235, 0.14, -0.12)
	var l_thigh := _add_limb_faceted(parent, Vector3(-0.175, 0.88, 0.02), l_knee_pos, 0.122, skin_mat)
	var r_thigh := _add_limb_faceted(parent, Vector3(0.175, 0.88, -0.02), r_knee_pos, 0.122, skin_mat)
	_add_mesh(parent, "LKnee", make_faceted_sphere(0.104, Vector3(0.95, 1.0, 1.02), 4, 8), l_knee_pos, skin_mat)
	_add_mesh(parent, "RKnee", make_faceted_sphere(0.104, Vector3(0.95, 1.0, 1.02), 4, 8), r_knee_pos, skin_mat)
	var l_calf := _add_limb_faceted(parent, l_knee_pos, l_ankle_pos, 0.098, skin_mat)
	var r_calf := _add_limb_faceted(parent, r_knee_pos, r_ankle_pos, 0.098, skin_mat)
	var l_boot := _add_mesh(parent, "LBoot", make_faceted_taper(Vector2(0.082, 0.12), Vector2(0.092, 0.16), 0.14, 8, 1.05), Vector3(-0.205, 0.07, 0.115), hair_mat)
	l_boot.rotation_degrees.y = 8.0
	_add_mesh(l_boot, "LLace", make_faceted_box(Vector3(0.022, 0.10, 0.02)), Vector3(0.0, 0.015, 0.13), lace_mat)
	var r_boot := _add_mesh(parent, "RBoot", make_faceted_taper(Vector2(0.082, 0.12), Vector2(0.092, 0.16), 0.14, 8, 1.05), Vector3(0.235, 0.07, -0.09), hair_mat)
	r_boot.rotation_degrees.y = -20.0
	_add_mesh(r_boot, "RLace", make_faceted_box(Vector3(0.022, 0.10, 0.02)), Vector3(0.0, 0.015, 0.13), lace_mat)

	# Sculpted rounded low-poly delts + continuous elbow joints
	_add_mesh(parent, "LShoulder", make_faceted_sphere(0.138, Vector3(1.06, 0.96, 0.96), 4, 10), Vector3(-0.345, 1.75, 0.0), skin_mat)
	_add_mesh(parent, "RShoulder", make_faceted_sphere(0.138, Vector3(1.06, 0.96, 0.96), 4, 10), Vector3(0.345, 1.75, 0.0), skin_mat)
	var l_elbow_pos := Vector3(-0.40, 1.40, 0.16)
	var r_elbow_pos := Vector3(0.40, 1.40, 0.16)
	var l_elbow_joint := _add_mesh(parent, "LElbow", make_faceted_sphere(0.096, Vector3.ONE, 4, 8), l_elbow_pos, skin_mat)
	var r_elbow_joint := _add_mesh(parent, "RElbow", make_faceted_sphere(0.096, Vector3.ONE, 4, 8), r_elbow_pos, skin_mat)

	# Articulated muscular biceps & forearms
	var l_upper := _add_limb_faceted(parent, Vector3(-0.345, 1.75, 0.0), l_elbow_pos, 0.108, skin_mat)
	var r_upper := _add_limb_faceted(parent, Vector3(0.345, 1.75, 0.0), r_elbow_pos, 0.108, skin_mat)
	var l_fore := _add_limb_faceted(parent, l_elbow_pos, Vector3(-0.18, 1.88, 0.34), 0.094, skin_mat)
	var r_fore := _add_limb_faceted(parent, r_elbow_pos, Vector3(0.18, 1.88, 0.34), 0.094, skin_mat)

	# Proper elongated padded Boxing Gloves with longer wrist cuff, tucked thumb & knuckle pad
	var l_glove := _build_glove_mesh(parent, "LeftGlove", Vector3(-0.18, 1.88, 0.34), true, glove_mat, band_mat, tape_mat)
	var r_glove := _build_glove_mesh(parent, "RightGlove", Vector3(0.18, 1.88, 0.34), false, glove_mat, band_mat, tape_mat)

	return {
		"torso_mat": torso_mat,
		"chest": chest,
		"head": head,
		"left_upper_arm": l_upper,
		"right_upper_arm": r_upper,
		"left_forearm": l_fore,
		"right_forearm": r_fore,
		"left_elbow": l_elbow_joint,
		"right_elbow": r_elbow_joint,
		"left_glove": l_glove,
		"right_glove": r_glove,
		"l_thigh": l_thigh,
		"r_thigh": r_thigh,
		"l_calf": l_calf,
		"r_calf": r_calf
	}


static func _build_glove_mesh(
	parent: Node3D,
	node_name: String,
	pos: Vector3,
	is_left: bool,
	glove_mat: Material,
	band_mat: Material,
	tape_mat: Material
) -> MeshInstance3D:
	# Elongated padded boxing glove body (not a short round ball)
	var glove := _add_mesh(parent, node_name, make_faceted_sphere(0.145, Vector3(0.88, 1.14, 1.28), 5, 10), pos, glove_mat)
	glove.rotation_degrees = Vector3(14.0, -10.0 if is_left else 10.0, 0.0)
	_add_mesh(glove, "KnucklePad", make_faceted_box(Vector3(0.165, 0.085, 0.09)), Vector3(0.0, 0.045, 0.13), glove_mat)
	# Extended padded wrist cuff + strap wrapping down the forearm
	_add_mesh(glove, "LongCuff", make_faceted_taper(Vector2(0.112, 0.118), Vector2(0.102, 0.108), 0.22, 8, 1.02), Vector3(0.0, -0.20, -0.025), glove_mat)
	_add_mesh(glove, "Strap", make_faceted_taper(Vector2(0.108, 0.114), Vector2(0.106, 0.112), 0.075, 8, 1.0), Vector3(0.0, -0.25, -0.03), band_mat)
	_add_mesh(glove, "Tape", make_faceted_taper(Vector2(0.095, 0.098), Vector2(0.095, 0.098), 0.05, 8, 1.0), Vector3(0.0, -0.31, -0.035), tape_mat)
	# Tucked thumb along inner side
	var thumb := _add_mesh(glove, "Thumb", make_faceted_taper(Vector2(0.048, 0.052), Vector2(0.042, 0.046), 0.13, 6, 1.12), Vector3(0.105 if is_left else -0.105, 0.02, 0.035), glove_mat)
	thumb.rotation_degrees = Vector3(26.0, 0.0, -18.0 if is_left else 18.0)
	return glove


static func place_limb(limb: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	if not is_instance_valid(limb):
		return
	var direction := end - start
	var length := direction.length()
	limb.position = (start + end) * 0.5
	if length > 0.001:
		limb.scale.y = length
		limb.quaternion = Quaternion(Vector3.UP, direction.normalized())


static func _add_mesh(parent: Node3D, node_name: String, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _add_limb_faceted(parent: Node3D, start: Vector3, end: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var direction := end - start
	var length := maxf(0.05, direction.length())
	var limb := MeshInstance3D.new()
	limb.name = "Limb"
	limb.mesh = make_faceted_taper(Vector2(radius, radius), Vector2(radius * 0.84, radius * 0.84), 1.0, 8, 1.06)
	limb.material_override = mat
	limb.position = (start + end) * 0.5
	limb.scale = Vector3(1.0, length, 1.0)
	if direction.length() > 0.001:
		limb.quaternion = Quaternion(Vector3.UP, direction.normalized())
	parent.add_child(limb)
	return limb
