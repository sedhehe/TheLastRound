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
	hair_color: Color = Color(0.07, 0.07, 0.09),
	hair_style: String = "cropped"
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
	var traps := _add_mesh(parent, "Traps", make_faceted_taper(Vector2(0.135, 0.105), Vector2(0.31, 0.165), 0.15, 10, 1.02), Vector3(0.0, 1.83, 0.0), torso_mat)
	traps.rotation.x = 0.06
	var chest := _add_mesh(parent, "Chest", make_faceted_taper(Vector2(0.32, 0.195), Vector2(0.225, 0.155), 0.42, 10, 1.05), Vector3(0.0, 1.58, 0.015), torso_mat)
	var l_pec := _add_mesh(parent, "LPec", make_faceted_box(Vector3(0.17, 0.115, 0.07)), Vector3(-0.108, 1.65, 0.148), torso_mat)
	l_pec.rotation_degrees = Vector3(-8.0, -14.0, 5.0)
	var r_pec := _add_mesh(parent, "RPec", make_faceted_box(Vector3(0.17, 0.115, 0.07)), Vector3(0.108, 1.65, 0.148), torso_mat)
	r_pec.rotation_degrees = Vector3(-8.0, 14.0, -5.0)
	# Ribcage/Abdominal taper + 6-pack abs & obliques
	_add_mesh(parent, "Waist", make_faceted_taper(Vector2(0.225, 0.155), Vector2(0.245, 0.165), 0.30, 10, 0.98), Vector3(0.0, 1.25, 0.01), torso_mat)
	for ab_row in range(3):
		var ay := 1.43 - float(ab_row) * 0.090
		var az := 0.152 - float(ab_row) * 0.004
		_add_mesh(parent, "LAbs_%d" % ab_row, make_faceted_box(Vector3(0.078, 0.066, 0.038)), Vector3(-0.048, ay, az), torso_mat)
		_add_mesh(parent, "RAbs_%d" % ab_row, make_faceted_box(Vector3(0.078, 0.066, 0.038)), Vector3(0.048, ay, az), torso_mat)
	for side_s in [-1.0, 1.0]:
		var ob := _add_mesh(parent, "Oblique_%s" % ("L" if side_s < 0.0 else "R"), make_faceted_box(Vector3(0.048, 0.22, 0.12)), Vector3(side_s * 0.205, 1.31, 0.02), torso_mat)
		ob.rotation_degrees = Vector3(0.0, 0.0, side_s * -7.0)

	# Muscular neck + clean human-proportioned boxer head
	_add_mesh(parent, "Neck", make_faceted_taper(Vector2(0.10, 0.095), Vector2(0.128, 0.112), 0.17, 10, 1.0), Vector3(0.0, 1.93, 0.01), skin_mat)
	var head := _add_mesh(parent, "Head", make_faceted_sphere(0.138, Vector3(0.92, 1.15, 1.04), 5, 12), Vector3(0.0, 2.12, 0.035), skin_mat)
	head.rotation_degrees.x = 5.0
	_add_mesh(head, "Brow", make_faceted_box(Vector3(0.168, 0.030, 0.052)), Vector3(0.0, 0.042, 0.110), skin_mat)
	_add_mesh(head, "EyeShadow", make_faceted_box(Vector3(0.148, 0.022, 0.030)), Vector3(0.0, 0.016, 0.118), make_flat_material(Color(0.035, 0.025, 0.025), 0.96))
	_add_mesh(head, "Nose", make_faceted_box(Vector3(0.036, 0.058, 0.048)), Vector3(0.0, -0.012, 0.130), skin_mat)
	_add_mesh(head, "MouthLine", make_faceted_box(Vector3(0.060, 0.012, 0.022)), Vector3(0.0, -0.060, 0.116), make_flat_material(Color(0.05, 0.03, 0.03), 0.94))
	_add_mesh(head, "Jaw", make_faceted_taper(Vector2(0.108, 0.104), Vector2(0.072, 0.088), 0.09, 8, 1.0), Vector3(0.0, -0.102, 0.016), skin_mat)
	_add_mesh(head, "LEar", make_faceted_box(Vector3(0.020, 0.058, 0.036)), Vector3(-0.128, 0.0, 0.0), skin_mat)
	_add_mesh(head, "REar", make_faceted_box(Vector3(0.020, 0.058, 0.036)), Vector3(0.128, 0.0, 0.0), skin_mat)
	match hair_style:
		"bald":
			pass
		"mohawk":
			_add_mesh(head, "MohawkRidge", make_faceted_box(Vector3(0.052, 0.095, 0.24)), Vector3(0.0, 0.145, -0.015), hair_mat)
		"slick":
			_add_mesh(head, "HairTop", make_faceted_sphere(0.142, Vector3(0.96, 0.72, 1.12), 4, 12), Vector3(0.0, 0.082, -0.024), hair_mat)
			_add_mesh(head, "HairBack", make_faceted_taper(Vector2(0.126, 0.128), Vector2(0.104, 0.104), 0.16, 8, 1.0), Vector3(0.0, 0.01, -0.052), hair_mat)
		_:
			_add_mesh(head, "HairTop", make_faceted_sphere(0.140, Vector3(0.94, 0.68, 1.06), 4, 12), Vector3(0.0, 0.076, -0.012), hair_mat)
			_add_mesh(head, "HairBack", make_faceted_taper(Vector2(0.124, 0.124), Vector2(0.100, 0.100), 0.13, 8, 1.0), Vector3(0.0, 0.015, -0.046), hair_mat)

	# Tailored boxing trunks (waistband + fitted legs seamlessly meeting thighs)
	_add_mesh(parent, "Belt", make_faceted_taper(Vector2(0.255, 0.175), Vector2(0.275, 0.185), 0.09, 10, 1.0), Vector3(0.0, 1.10, 0.0), band_mat)
	var pelvis := _add_mesh(parent, "Shorts", make_faceted_taper(Vector2(0.275, 0.185), Vector2(0.295, 0.195), 0.22, 10, 1.02), Vector3(0.0, 0.95, 0.0), shorts_mat)
	var l_cuff := _add_limb_faceted(pelvis, Vector3(-0.15, -0.03, 0.01), Vector3(-0.175, -0.25, 0.04), 0.145, shorts_mat)
	var r_cuff := _add_limb_faceted(pelvis, Vector3(0.15, -0.03, -0.01), Vector3(0.185, -0.25, -0.04), 0.145, shorts_mat)
	l_cuff.name = "LShortLeg"
	r_cuff.name = "RShortLeg"

	# Realistic athletic human legs + aligned ankles & flat-soled boxing shoes
	var l_knee_pos := Vector3(-0.18, 0.52, 0.05)
	var r_knee_pos := Vector3(0.20, 0.52, -0.04)
	var l_ankle_pos := Vector3(-0.18, 0.12, 0.02)
	var r_ankle_pos := Vector3(0.20, 0.12, -0.08)
	var l_thigh := _add_limb_faceted(parent, Vector3(-0.16, 0.90, 0.01), l_knee_pos, 0.118, skin_mat)
	var r_thigh := _add_limb_faceted(parent, Vector3(0.16, 0.90, -0.01), r_knee_pos, 0.118, skin_mat)
	_add_mesh(parent, "LKnee", make_faceted_sphere(0.098, Vector3(0.95, 1.0, 1.02), 4, 8), l_knee_pos, skin_mat)
	_add_mesh(parent, "RKnee", make_faceted_sphere(0.098, Vector3(0.95, 1.0, 1.02), 4, 8), r_knee_pos, skin_mat)
	var l_calf := _add_limb_faceted(parent, l_knee_pos, l_ankle_pos, 0.092, skin_mat)
	var r_calf := _add_limb_faceted(parent, r_knee_pos, r_ankle_pos, 0.092, skin_mat)

	var l_boot := _add_mesh(parent, "LBoot", make_faceted_taper(Vector2(0.078, 0.082), Vector2(0.082, 0.092), 0.12, 8, 1.02), Vector3(l_ankle_pos.x, 0.06, l_ankle_pos.z), hair_mat)
	l_boot.rotation_degrees.y = 8.0
	_add_mesh(l_boot, "LFoot", make_faceted_box(Vector3(0.115, 0.065, 0.21)), Vector3(0.0, -0.027, 0.065), hair_mat)
	_add_mesh(l_boot, "LLace", make_faceted_box(Vector3(0.022, 0.085, 0.02)), Vector3(0.0, 0.015, 0.085), lace_mat)

	var r_boot := _add_mesh(parent, "RBoot", make_faceted_taper(Vector2(0.078, 0.082), Vector2(0.082, 0.092), 0.12, 8, 1.02), Vector3(r_ankle_pos.x, 0.06, r_ankle_pos.z), hair_mat)
	r_boot.rotation_degrees.y = -18.0
	_add_mesh(r_boot, "RFoot", make_faceted_box(Vector3(0.115, 0.065, 0.21)), Vector3(0.0, -0.027, 0.065), hair_mat)
	_add_mesh(r_boot, "RLace", make_faceted_box(Vector3(0.022, 0.085, 0.02)), Vector3(0.0, 0.015, 0.085), lace_mat)

	# Tucked human shoulders + continuous elbow joints
	_add_mesh(parent, "LShoulder", make_faceted_sphere(0.128, Vector3(1.02, 0.96, 0.96), 4, 10), Vector3(-0.305, 1.72, 0.0), skin_mat)
	_add_mesh(parent, "RShoulder", make_faceted_sphere(0.128, Vector3(1.02, 0.96, 0.96), 4, 10), Vector3(0.305, 1.72, 0.0), skin_mat)
	var l_elbow_pos := Vector3(-0.37, 1.39, 0.15)
	var r_elbow_pos := Vector3(0.37, 1.39, 0.15)
	var l_elbow_joint := _add_mesh(parent, "LElbow", make_faceted_sphere(0.088, Vector3.ONE, 4, 8), l_elbow_pos, skin_mat)
	var r_elbow_joint := _add_mesh(parent, "RElbow", make_faceted_sphere(0.088, Vector3.ONE, 4, 8), r_elbow_pos, skin_mat)

	# Articulated muscular biceps & forearms
	var l_upper := _add_limb_faceted(parent, Vector3(-0.305, 1.72, 0.0), l_elbow_pos, 0.102, skin_mat)
	var r_upper := _add_limb_faceted(parent, Vector3(0.305, 1.72, 0.0), r_elbow_pos, 0.102, skin_mat)
	var l_fore := _add_limb_faceted(parent, l_elbow_pos, Vector3(-0.18, 1.88, 0.34), 0.088, skin_mat)
	var r_fore := _add_limb_faceted(parent, r_elbow_pos, Vector3(0.18, 1.88, 0.34), 0.088, skin_mat)

	# Proper elongated padded Boxing Gloves aligned along the forearm (+Y = fist tip, -Y = cuff)
	var l_glove := _build_glove_mesh(parent, "LeftGlove", Vector3(-0.18, 1.88, 0.34), true, glove_mat, band_mat, tape_mat)
	var r_glove := _build_glove_mesh(parent, "RightGlove", Vector3(0.18, 1.88, 0.34), false, glove_mat, band_mat, tape_mat)
	pose_arm(l_upper, l_fore, l_elbow_joint, l_glove, Vector3(-0.305, 1.72, 0.0), l_elbow_pos, Vector3(-0.18, 1.88, 0.34))
	pose_arm(r_upper, r_fore, r_elbow_joint, r_glove, Vector3(0.305, 1.72, 0.0), r_elbow_pos, Vector3(0.18, 1.88, 0.34))

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
	# +Y = fist/knuckle direction, -Y = wrist cuff wrapping straight onto the forearm
	var glove := _add_mesh(parent, node_name, make_faceted_sphere(0.135, Vector3(0.92, 1.24, 0.98), 5, 10), pos, glove_mat)
	_add_mesh(glove, "KnucklePad", make_faceted_box(Vector3(0.155, 0.095, 0.085)), Vector3(0.0, 0.105, 0.045), glove_mat)
	_add_mesh(glove, "LongCuff", make_faceted_taper(Vector2(0.108, 0.112), Vector2(0.096, 0.100), 0.22, 8, 1.02), Vector3(0.0, -0.17, 0.0), glove_mat)
	_add_mesh(glove, "Strap", make_faceted_taper(Vector2(0.102, 0.106), Vector2(0.100, 0.104), 0.075, 8, 1.0), Vector3(0.0, -0.24, 0.0), band_mat)
	_add_mesh(glove, "Tape", make_faceted_taper(Vector2(0.090, 0.092), Vector2(0.090, 0.092), 0.055, 8, 1.0), Vector3(0.0, -0.30, 0.0), tape_mat)
	var thumb := _add_mesh(glove, "Thumb", make_faceted_taper(Vector2(0.045, 0.048), Vector2(0.040, 0.044), 0.125, 6, 1.1), Vector3(0.102 if is_left else -0.102, 0.03, 0.035), glove_mat)
	thumb.rotation_degrees = Vector3(12.0, 0.0, -14.0 if is_left else 14.0)
	return glove


static func pose_arm(
	upper: MeshInstance3D,
	forearm: MeshInstance3D,
	elbow_joint: MeshInstance3D,
	glove: MeshInstance3D,
	shoulder: Vector3,
	elbow: Vector3,
	hand: Vector3
) -> void:
	if is_instance_valid(elbow_joint):
		elbow_joint.position = elbow
	place_limb(upper, shoulder, elbow)
	var diff := hand - elbow
	var fore_dir := diff.normalized() if diff.length() > 0.001 else Vector3.UP
	var wrist := hand - fore_dir * 0.16
	place_limb(forearm, elbow, wrist)
	if is_instance_valid(glove):
		glove.position = hand
		glove.quaternion = Quaternion(Vector3.UP, fore_dir)


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
