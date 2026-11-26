extends SubViewportContainer

const TLRBoxerMesh = preload("res://scripts/boxer_mesh.gd")

var viewport: SubViewport
var boxer_root: Node3D
var left_upper_arm: MeshInstance3D
var right_upper_arm: MeshInstance3D
var left_forearm: MeshInstance3D
var right_forearm: MeshInstance3D
var left_elbow: MeshInstance3D
var right_elbow: MeshInstance3D
var left_glove: MeshInstance3D
var right_glove: MeshInstance3D
var torso_mat: StandardMaterial3D
var pose_mode: String = "idle"
var anim_time: float = 0.0
var animate_loop: bool = false
var show_ring_stage: bool = false


var _hair_style: String = "cropped"
var _shorts_color: Color = Color(0.05, 0.07, 0.10)
var _glove_color: Color = Color(0.48, 0.06, 0.05)
var _hair_color: Color = Color(0.07, 0.07, 0.09)


func _init(p_rect: Rect2, p_torso_color: Color = Color(0.55, 0.36, 0.26), p_pose: String = "idle", p_animate: bool = false, p_show_ring: bool = false, p_visual: Dictionary = {}) -> void:
	position = p_rect.position
	size = p_rect.size
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pose_mode = p_pose
	animate_loop = p_animate
	show_ring_stage = p_show_ring
	if not p_visual.is_empty():
		p_torso_color = Color.from_string(str(p_visual.get("skin", "#9c6b4d")), p_torso_color)
		_shorts_color = Color.from_string(str(p_visual.get("shorts", "#121a26")), Color(0.05, 0.07, 0.10))
		_glove_color = Color.from_string(str(p_visual.get("gloves", "#7a100d")), Color(0.48, 0.06, 0.05))
		_hair_color = Color.from_string(str(p_visual.get("hair", "#111216")), Color(0.07, 0.07, 0.09))
		_hair_style = str(p_visual.get("hair_style", "cropped"))
	else:
		_shorts_color = p_torso_color.darkened(0.65)

	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if p_animate else SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	viewport.size = Vector2i(maxi(64, int(p_rect.size.x)), maxi(64, int(p_rect.size.y)))
	add_child(viewport)

	_build_stage(p_torso_color)
	_apply_pose(p_pose)


func _process(delta: float) -> void:
	if not animate_loop or not is_instance_valid(boxer_root):
		return
	anim_time += delta
	_apply_pose(pose_mode, anim_time)


func _build_stage(p_accent_color: Color) -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.024, 0.042, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.28, 0.40)
	env.ambient_light_energy = 0.72
	world_env.environment = env
	viewport.add_child(world_env)

	var spot := SpotLight3D.new()
	spot.position = Vector3(-0.9, 3.2, 2.2)
	spot.look_at_from_position(Vector3(-0.9, 3.2, 2.2), Vector3(0.0, 1.3, 0.0), Vector3.UP)
	spot.light_color = Color(0.76, 0.90, 1.0)
	spot.light_energy = 4.2
	spot.spot_range = 8.0
	spot.spot_angle = 45.0
	viewport.add_child(spot)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(1.6, 2.4, -1.7)
	rim_light.light_color = Color(0.28, 0.68, 1.0)
	rim_light.light_energy = 2.4
	rim_light.omni_range = 7.0
	viewport.add_child(rim_light)

	var cam := Camera3D.new()
	cam.fov = 38.0
	viewport.add_child(cam)
	cam.look_at_from_position(Vector3(0.10, 1.24, 3.55), Vector3(0.0, 1.18, 0.0), Vector3.UP)

	var stage_root := Node3D.new()
	viewport.add_child(stage_root)
	var mat_col := Color(0.032, 0.068, 0.105) if show_ring_stage else Color(0.024, 0.048, 0.078)
	var floor_cyl := _cylinder(stage_root, 2.6 if show_ring_stage else 0.90, 0.04, Vector3(0.0, -0.02, 0.0), TLRBoxerMesh.make_flat_material(mat_col, 0.92))
	floor_cyl.scale = Vector3(1.6, 1.0, 1.0)
	var shadow_disc := _cylinder(stage_root, 0.46, 0.01, Vector3(0.0, 0.005, 0.0), TLRBoxerMesh.make_flat_material(Color(0.008, 0.015, 0.025), 1.0))
	shadow_disc.scale = Vector3(1.15, 1.0, 0.78)

	if show_ring_stage:
		var rope_mat := TLRBoxerMesh.make_flat_material(Color(0.16, 0.30, 0.44), 0.75)
		for ry in [0.58, 0.96, 1.34]:
			var rope := MeshInstance3D.new()
			var rm := CylinderMesh.new()
			rm.top_radius = 0.02
			rm.bottom_radius = 0.02
			rm.height = 7.4
			rope.mesh = rm
			rope.material_override = rope_mat
			rope.position = Vector3(0.0, ry, -1.65)
			rope.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			stage_root.add_child(rope)

		var post_mat := TLRBoxerMesh.make_flat_material(Color(0.07, 0.16, 0.26), 0.82)
		_box(stage_root, Vector3(0.16, 1.60, 0.16), Vector3(-2.15, 0.80, -1.65), post_mat)
		_box(stage_root, Vector3(0.16, 1.60, 0.16), Vector3(2.15, 0.80, -1.65), post_mat)

	boxer_root = Node3D.new()
	viewport.add_child(boxer_root)

	var skin := p_accent_color
	var rig := TLRBoxerMesh.build_boxer_rig(boxer_root, skin, _shorts_color, _glove_color, _hair_color, _hair_style)
	torso_mat = rig.torso_mat
	left_upper_arm = rig.left_upper_arm
	right_upper_arm = rig.right_upper_arm
	left_forearm = rig.left_forearm
	right_forearm = rig.right_forearm
	left_elbow = rig.left_elbow
	right_elbow = rig.right_elbow
	left_glove = rig.left_glove
	right_glove = rig.right_glove


func _apply_pose(pose: String, t: float = 0.0) -> void:
	if not is_instance_valid(boxer_root):
		return
	var pulse := sin(t * 2.4) * 0.5 + 0.5 if animate_loop else 0.78
	boxer_root.position = Vector3.ZERO
	boxer_root.rotation = Vector3.ZERO

	var l_shoulder := Vector3(-0.305, 1.72, 0.0)
	var r_shoulder := Vector3(0.305, 1.72, 0.0)
	var l_elbow := Vector3(-0.37, 1.39, 0.15)
	var r_elbow := Vector3(0.37, 1.39, 0.15)
	var l_hand := Vector3(-0.18, 1.88, 0.34)
	var r_hand := Vector3(0.18, 1.88, 0.34)

	match pose:
		"heavy":
			boxer_root.rotation.y = -0.26 * pulse
			boxer_root.rotation.z = -0.06 * pulse
			r_elbow = Vector3(0.56, 1.46, -0.14)
			r_hand = Vector3(0.46, 1.84, -0.04)
			l_elbow = Vector3(-0.40, 1.44, 0.20)
			l_hand = Vector3(-0.18, 1.88, 0.38)
		"body":
			boxer_root.position.y = -0.14 * pulse
			boxer_root.rotation.x = 0.14 * pulse
			r_elbow = Vector3(0.50, 1.18, 0.06)
			r_hand = Vector3(0.34, 1.42, 0.36)
			l_elbow = Vector3(-0.44, 1.24, 0.12)
			l_hand = Vector3(-0.28, 1.56, 0.34)
		"jab":
			boxer_root.rotation.y = 0.18 * pulse
			l_elbow = Vector3(-0.30, 1.54, 0.28 * pulse + 0.10)
			l_hand = Vector3(-0.16, 1.84, 0.68 * pulse + 0.22)
			r_elbow = Vector3(0.40, 1.44, 0.16)
			r_hand = Vector3(0.20, 1.88, 0.34)
		"combination":
			var sw := sin(t * 4.0) if animate_loop else 0.55
			boxer_root.rotation.y = sw * 0.22
			l_elbow = Vector3(-0.36, 1.46, 0.18 + maxf(0.0, sw) * 0.14)
			l_hand = Vector3(-0.20, 1.80, 0.44 + maxf(0.0, sw) * 0.30)
			r_elbow = Vector3(0.36, 1.46, 0.18 + maxf(0.0, -sw) * 0.14)
			r_hand = Vector3(0.20, 1.80, 0.44 + maxf(0.0, -sw) * 0.30)
		"defense":
			var bob := sin(t * 2.0) * 0.03 if animate_loop else 0.0
			boxer_root.position.y = bob
			boxer_root.rotation.y = sin(t * 1.1) * 0.07 if animate_loop else 0.0
			l_elbow = Vector3(-0.34, 1.46, 0.22)
			r_elbow = Vector3(0.34, 1.46, 0.22)
			l_hand = Vector3(-0.17, 1.96, 0.40)
			r_hand = Vector3(0.17, 1.96, 0.40)
		"recovery":
			boxer_root.position.y = -0.04
			l_elbow = Vector3(-0.46, 1.32, 0.06)
			r_elbow = Vector3(0.46, 1.32, 0.06)
			l_hand = Vector3(-0.36, 1.42, 0.24)
			r_hand = Vector3(0.36, 1.42, 0.24)
		"taunt":
			var sway := sin(t * 2.5) * 0.14 if animate_loop else 0.10
			boxer_root.rotation.x = -0.10
			boxer_root.rotation.y = sway
			l_elbow = Vector3(-0.56, 1.44, 0.08)
			r_elbow = Vector3(0.56, 1.44, 0.08)
			l_hand = Vector3(-0.52, 1.54, 0.28)
			r_hand = Vector3(0.52, 1.54, 0.28)
		"enrage":
			var roar := sin(t * 5.0) * 0.06 if animate_loop else 0.05
			boxer_root.position.y = -0.10
			boxer_root.rotation.x = 0.20 + roar
			l_elbow = Vector3(-0.48, 1.48, 0.24)
			r_elbow = Vector3(0.48, 1.48, 0.24)
			l_hand = Vector3(-0.34, 1.84, 0.44)
			r_hand = Vector3(0.34, 1.84, 0.44)
		_:
			if animate_loop:
				boxer_root.position.y = sin(t * 2.2) * 0.02
				boxer_root.rotation.y = sin(t * 0.9) * 0.08

	TLRBoxerMesh.pose_arm(left_upper_arm, left_forearm, left_elbow, left_glove, l_shoulder, l_elbow, l_hand)
	TLRBoxerMesh.pose_arm(right_upper_arm, right_forearm, right_elbow, right_glove, r_shoulder, r_elbow, r_hand)


func _box(p: Node3D, s: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var i := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	i.mesh = bm
	i.material_override = m
	i.position = pos
	p.add_child(i)
	return i


func _cylinder(p: Node3D, r: float, h: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var i := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	i.mesh = cm
	i.material_override = m
	i.position = pos
	p.add_child(i)
	return i
