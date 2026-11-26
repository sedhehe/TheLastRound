extends Node3D

const TLRBoxerMesh = preload("res://scripts/boxer_mesh.gd")

var camera: Camera3D
var arena_light: OmniLight3D
var spot_light: SpotLight3D
var opponent_body: Node3D
var opponent_material: StandardMaterial3D
var opponent_left_upper_arm: MeshInstance3D
var opponent_right_upper_arm: MeshInstance3D
var opponent_left_forearm: MeshInstance3D
var opponent_right_forearm: MeshInstance3D
var opponent_left_elbow: MeshInstance3D
var opponent_right_elbow: MeshInstance3D
var opponent_left_glove: MeshInstance3D
var opponent_right_glove: MeshInstance3D

var left_glove: MeshInstance3D
var right_glove: MeshInstance3D
var glove_home_left := Vector3(-0.30, -0.21, -0.58)
var glove_home_right := Vector3(0.30, -0.21, -0.58)

var opponent_home_position := Vector3(0.0, 0.24, -3.15)
var opponent_hit_timer := 0.0
var opponent_attack_timer := 0.0
var opponent_telegraph_pose := ""
var opponent_telegraph_active := false
var player_action_timer := 0.0
var impact_timer := 0.0
var idle_time := 0.0
var crowd_cheer_timer := 0.0
var reduced_motion := false

var active_move := ""
var glove_action_offset := Vector3.ZERO
var glove_action_rot := Vector3.ZERO

var _spectators: Array[Dictionary] = []
var _dust_particles: CPUParticles3D
var _impact_particles: CPUParticles3D
var _active_camera: Camera3D

var rng := RandomNumberGenerator.new()

const RING_HALF_SIZE := 4.35
const CROWD_DISTANCE := 6.7


func _ready() -> void:
	rng.randomize()


func build() -> Dictionary:
	_build_environment()
	_build_lighting()
	_build_ring()
	_build_crowd()
	_build_opponent()
	_build_camera()
	_build_gloves()
	_build_particles()

	return {
		"camera": camera,
		"arena_light": arena_light,
		"opponent_mesh": opponent_body,
		"opponent_mat": opponent_material
	}


func _process(delta: float) -> void:
	idle_time += delta
	_update_gloves(delta)
	_update_opponent_animation(delta)
	_update_crowd(delta)
	_update_camera_shake(delta)
	_update_lighting_flicker()


func _update_lighting_flicker() -> void:
	if not is_instance_valid(spot_light):
		return
	if reduced_motion:
		spot_light.light_energy = 7.2
		return
	var flicker := sin(idle_time * 13.7) * 0.14 + sin(idle_time * 31.3) * 0.08
	if fmod(idle_time, 5.7) > 5.56:
		flicker -= 0.95
	spot_light.light_energy = maxf(5.6, 7.2 + flicker)


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if is_instance_valid(_dust_particles):
		_dust_particles.emitting = not enabled


func trigger_crowd_surge(duration: float = 1.2) -> void:
	if not reduced_motion:
		crowd_cheer_timer = maxf(crowd_cheer_timer, duration)


func trigger_hit_sparks(over_opponent: bool = true) -> void:
	if reduced_motion or not is_instance_valid(_impact_particles):
		return
	var target_pos := opponent_home_position + Vector3(0.0, 1.72, 0.28) if over_opponent else Vector3(0.0, 1.45, 0.45)
	if over_opponent and is_instance_valid(opponent_body):
		target_pos = opponent_body.position + Vector3(0.0, 1.72, 0.25)
	_impact_particles.position = target_pos
	_impact_particles.restart()
	_impact_particles.emitting = true


# ---------------------------------------------------------
# INDUSTRIAL GRITTY ENVIRONMENT (BUCKSHOT ROULETTE MOOD)
# ---------------------------------------------------------

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.005, 0.009, 0.015)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.08, 0.14, 0.20)
	environment.ambient_light_energy = 0.40
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.12

	# Thick smoky underground fight-club fog & dust haze
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = Color(0.055, 0.128, 0.182)
	environment.fog_light_energy = 1.42
	environment.fog_density = 0.068

	world_environment.environment = environment
	add_child(world_environment)

	var floor_tex := TLRBoxerMesh.make_grime_texture(Color(0.028, 0.040, 0.054), 0.24, 101, 0.12)
	var wall_tex := TLRBoxerMesh.make_grime_texture(Color(0.034, 0.048, 0.064), 0.26, 202, 0.10)
	var steel_tex := TLRBoxerMesh.make_grime_texture(Color(0.050, 0.064, 0.078), 0.22, 303, 0.16)

	var floor_material := _textured_material(floor_tex, 0.94)
	var concrete_wall := _textured_material(wall_tex, 0.96)
	var steel_mat := _textured_material(steel_tex, 0.72)

	_add_box(self, "BasementFloor", Vector3(32.0, 0.3, 32.0), Vector3(0.0, -0.35, 0.0), floor_material)
	_add_box(self, "BackWall", Vector3(32.0, 9.0, 0.5), Vector3(0.0, 4.0, -10.5), concrete_wall)
	_add_box(self, "LeftWall", Vector3(0.5, 9.0, 32.0), Vector3(-10.5, 4.0, 0.0), concrete_wall)
	_add_box(self, "RightWall", Vector3(0.5, 9.0, 32.0), Vector3(10.5, 4.0, 0.0), concrete_wall)
	_add_box(self, "Ceiling", Vector3(32.0, 0.4, 32.0), Vector3(0.0, 6.2, 0.0), steel_mat)

	# Concrete basement columns & heavy overhead industrial rafters / grate
	for px in [-7.5, -2.6, 2.6, 7.5]:
		_add_box(self, "BackPillar", Vector3(0.65, 8.0, 0.65), Vector3(px, 3.6, -10.1), steel_mat)
	for pz in [-6.5, -3.5, -0.5, 2.5]:
		_add_box(self, "LeftPillar", Vector3(0.55, 8.0, 0.55), Vector3(-10.1, 3.6, pz), steel_mat)
		_add_box(self, "RightPillar", Vector3(0.55, 8.0, 0.55), Vector3(10.1, 3.6, pz), steel_mat)
		_add_box(self, "CeilingRafter", Vector3(22.0, 0.20, 0.24), Vector3(0.0, 4.65, pz), steel_mat)

	# Heavy black hanging cables draping across the rafters (Buckshot Roulette signature)
	var cable_mat := _material(Color(0.06, 0.08, 0.11), 0.72)
	_add_catenary_cable(Vector3(-3.4, 4.35, -3.4), Vector3(0.0, 3.65, -3.55), Vector3(3.4, 4.35, -3.4), cable_mat)
	_add_catenary_cable(Vector3(-2.9, 4.40, -4.1), Vector3(0.2, 3.48, -4.25), Vector3(3.1, 4.40, -4.1), cable_mat)
	_add_catenary_cable(Vector3(-3.8, 4.55, -2.5), Vector3(-1.4, 3.75, -2.85), Vector3(2.8, 4.55, -2.6), cable_mat)
	_add_catenary_cable(Vector3(-2.6, 4.60, -5.2), Vector3(0.5, 3.88, -5.4), Vector3(3.6, 4.60, -5.0), cable_mat)

	# Dim hanging bare industrial cage bulbs in background rafters
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(0.95, 0.68, 0.36)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(0.95, 0.62, 0.28)
	bulb_mat.emission_energy_multiplier = 1.8
	for bx in [-4.2, 4.2]:
		_add_limb(self, Vector3(bx, 4.65, -5.8), Vector3(bx, 3.55, -5.8), 0.015, cable_mat)
		_add_cylinder(self, "CageBulb", 0.06, 0.11, Vector3(bx, 3.50, -5.8), bulb_mat)
		var bl := OmniLight3D.new()
		bl.position = Vector3(bx, 3.40, -5.8)
		bl.light_color = Color(0.95, 0.62, 0.30)
		bl.light_energy = 0.75
		bl.omni_range = 4.5
		add_child(bl)

	# Industrial underground ringside props: barrels, crates, folding chair, & glowing CRT box
	var drum_mat := _material(Color(0.11, 0.14, 0.17), 0.68)
	var crate_mat := _material(Color(0.12, 0.10, 0.08), 0.90)
	_add_cylinder(self, "OilDrum1", 0.34, 0.92, Vector3(-5.5, 0.25, -4.8), drum_mat)
	_add_cylinder(self, "OilDrum2", 0.34, 0.92, Vector3(-5.9, 0.25, -4.0), _material(Color(0.22, 0.08, 0.07), 0.74))
	_add_box(self, "Crate1", Vector3(0.85, 0.72, 0.85), Vector3(5.6, 0.15, -4.6), crate_mat)
	_add_box(self, "Crate2", Vector3(0.62, 0.56, 0.62), Vector3(5.55, 0.79, -4.55), crate_mat).rotation_degrees.y = 18.0
	# Folding metal corner chair at ringside
	_add_box(self, "ChairSeat", Vector3(0.46, 0.05, 0.44), Vector3(-4.95, 0.42, 3.85), steel_mat)
	_add_box(self, "ChairBack", Vector3(0.46, 0.48, 0.05), Vector3(-4.95, 0.68, 4.05), steel_mat)
	# Ringside old CRT monitor box with dim teal screen
	_add_box(self, "CRTBody", Vector3(0.62, 0.52, 0.54), Vector3(5.15, 0.26, -2.1), steel_mat)
	var crt_screen_mat := StandardMaterial3D.new()
	crt_screen_mat.albedo_color = Color(0.16, 0.52, 0.58)
	crt_screen_mat.emission_enabled = true
	crt_screen_mat.emission = Color(0.18, 0.62, 0.68)
	crt_screen_mat.emission_energy_multiplier = 1.2
	_add_box(self, "CRTScreen", Vector3(0.04, 0.34, 0.40), Vector3(4.83, 0.28, -2.1), crt_screen_mat)


func _add_catenary_cable(a: Vector3, mid: Vector3, b: Vector3, mat: Material) -> void:
	var prev := a
	var steps := 10
	for s in range(1, steps + 1):
		var t := float(s) / float(steps)
		var omt := 1.0 - t
		var pt := a * (omt * omt) + mid * (2.0 * omt * t) + b * (t * t)
		_add_limb(self, prev, pt, 0.022, mat)
		prev = pt


# ---------------------------------------------------------
# BARN-DOOR SPOTLIGHTS & INDUSTRIAL LIGHTING
# ---------------------------------------------------------

func _build_lighting() -> void:
	var ambient := DirectionalLight3D.new()
	ambient.name = "ColdAmbientLight"
	ambient.rotation_degrees = Vector3(-58.0, -20.0, 0.0)
	ambient.light_color = Color(0.52, 0.72, 0.92)
	ambient.light_energy = 0.25
	ambient.shadow_enabled = true
	add_child(ambient)

	# Primary harsh overhead cone converging onto the ring center / boxer
	spot_light = SpotLight3D.new()
	spot_light.name = "RingOverheadSpot"
	spot_light.position = Vector3(0.0, 5.2, -2.1)
	spot_light.rotation_degrees = Vector3(-78.0, 0.0, 0.0)
	spot_light.light_color = Color(0.76, 0.91, 1.0)
	spot_light.light_energy = 7.2
	spot_light.spot_range = 12.5
	spot_light.spot_angle = 40.0
	spot_light.spot_attenuation = 1.25
	spot_light.shadow_enabled = true
	add_child(spot_light)

	# Dual flanking Barn-Door Stage Spotlights hanging in the upper frame (Buckshot style)
	_add_barn_door_spot(Vector3(-1.95, 3.68, -3.35), Vector3(0.0, 1.45, -2.95), Color(0.68, 0.86, 0.98))
	_add_barn_door_spot(Vector3(1.95, 3.68, -3.35), Vector3(0.0, 1.45, -2.95), Color(0.92, 0.56, 0.34))

	# Subtle dim industrial rig wash so rafters, cables & barn doors remain visible in shadows
	var rig_wash := OmniLight3D.new()
	rig_wash.name = "RigSilhouetteWash"
	rig_wash.position = Vector3(0.0, 4.2, -2.4)
	rig_wash.light_color = Color(0.30, 0.45, 0.62)
	rig_wash.light_energy = 1.15
	rig_wash.omni_range = 7.5
	add_child(rig_wash)

	arena_light = OmniLight3D.new()
	arena_light.name = "ArenaBlueLight"
	arena_light.position = Vector3(0.0, 4.0, -1.2)
	arena_light.light_color = Color(0.24, 0.52, 0.84)
	arena_light.light_energy = 1.45
	arena_light.omni_range = 11.0
	arena_light.shadow_enabled = false
	add_child(arena_light)


func _add_barn_door_spot(pos: Vector3, aim_at: Vector3, beam_col: Color) -> void:
	var fixture := Node3D.new()
	fixture.position = pos
	add_child(fixture)
	fixture.look_at(aim_at, Vector3.UP)

	var metal_mat := _material(Color(0.14, 0.17, 0.21), 0.65)
	var stripe_mat := _material(Color(0.46, 0.14, 0.12), 0.72)
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = beam_col
	lens_mat.emission_enabled = true
	lens_mat.emission = beam_col
	lens_mat.emission_energy_multiplier = 2.0

	# Cylindrical spotlight canister (-Z points toward aim target in Godot look_at)
	var body := _add_cylinder(fixture, "Canister", 0.24, 0.52, Vector3(0.0, 0.0, 0.12), metal_mat)
	body.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var collar := _add_cylinder(fixture, "Stripe", 0.255, 0.10, Vector3(0.0, 0.0, 0.18), stripe_mat)
	collar.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var lens := _add_cylinder(fixture, "Lens", 0.20, 0.04, Vector3(0.0, 0.0, -0.14), lens_mat)
	lens.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	# 4 angled metal barn-door flaps around aperture
	for flap in [
		{"pos": Vector3(0.0, 0.24, -0.26), "size": Vector3(0.38, 0.03, 0.28), "rot": Vector3(-36.0, 0.0, 0.0)},
		{"pos": Vector3(0.0, -0.24, -0.26), "size": Vector3(0.38, 0.03, 0.28), "rot": Vector3(36.0, 0.0, 0.0)},
		{"pos": Vector3(-0.24, 0.0, -0.26), "size": Vector3(0.03, 0.38, 0.28), "rot": Vector3(0.0, 36.0, 0.0)},
		{"pos": Vector3(0.24, 0.0, -0.26), "size": Vector3(0.03, 0.38, 0.28), "rot": Vector3(0.0, -36.0, 0.0)}
	]:
		var f := _add_box(fixture, "Flap", flap.size, flap.pos, metal_mat)
		f.rotation_degrees = flap.rot

	# Support hanger up to rafter
	_add_box(self, "SpotMount", Vector3(0.07, 0.85, 0.07), pos + Vector3(0.0, 0.42, 0.0), metal_mat)

	var spot := SpotLight3D.new()
	spot.light_color = beam_col
	spot.light_energy = 3.6
	spot.spot_range = 10.5
	spot.spot_angle = 34.0
	spot.spot_attenuation = 1.35
	fixture.add_child(spot)

	# Subtle soft misty light glow fading smoothly to zero at all edges
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.22
	cone_mesh.bottom_radius = 1.65
	cone_mesh.height = 3.8
	cone_mesh.radial_segments = 24
	cone_mesh.cap_top = false
	cone_mesh.cap_bottom = false
	var cone_shader := Shader.new()
	cone_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded;
uniform vec3 beam_color = vec3(0.45, 0.72, 0.90);
void fragment() {
	float h = 1.0 - UV.y;
	float v_fade = smoothstep(0.0, 0.22, h) * smoothstep(0.98, 0.15, h);
	float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge = pow(ndv, 3.2);
	float a = clamp(v_fade * edge * 0.055, 0.0, 0.06);
	ALBEDO = beam_color;
	ALPHA = a;
}
"""
	var cone_mat := ShaderMaterial.new()
	cone_mat.shader = cone_shader
	cone_mat.set_shader_parameter("beam_color", Vector3(beam_col.r, beam_col.g, beam_col.b))
	var cone := MeshInstance3D.new()
	cone.name = "LightBeamCone"
	cone.mesh = cone_mesh
	cone.material_override = cone_mat
	cone.position = Vector3(0.0, 0.0, -2.05)
	cone.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	fixture.add_child(cone)


# ---------------------------------------------------------
# BOXING RING (GRITTY CANVAS & TURNBUCKLES)
# ---------------------------------------------------------

func _build_ring() -> void:
	var metal_tex := TLRBoxerMesh.make_grime_texture(Color(0.048, 0.062, 0.078), 0.18, 401, 0.14)
	var canvas_tex := TLRBoxerMesh.make_grime_texture(Color(0.095, 0.155, 0.215), 0.22, 402, 0.09)
	var rope_tex := TLRBoxerMesh.make_grime_texture(Color(0.30, 0.38, 0.46), 0.16, 403, 0.20)

	var dark_metal := _textured_material(metal_tex, 0.72)
	var canvas_material := _textured_material(canvas_tex, 0.84)
	var apron_trim := _material(Color(0.11, 0.18, 0.25), 0.78)
	var rope_material := _textured_material(rope_tex, 0.65)
	var post_material := _material(Color(0.07, 0.10, 0.14), 0.72)

	_add_box(self, "RingFoundation", Vector3(9.1, 0.45, 9.1), Vector3(0.0, -0.05, 0.0), dark_metal)
	_add_box(self, "RingApronTrim", Vector3(9.16, 0.08, 9.16), Vector3(0.0, 0.16, 0.0), apron_trim)
	_add_box(self, "RingCanvas", Vector3(8.45, 0.08, 8.45), Vector3(0.0, 0.20, 0.0), canvas_material)

	# Subtle worn canvas scuffs and dark blood stains from prior bouts
	var scuff_mat := _material(Color(0.06, 0.09, 0.12), 0.94)
	var stain_mat := _material(Color(0.16, 0.04, 0.045), 0.88)
	_add_cylinder(self, "CanvasStain1", 0.36, 0.008, Vector3(-0.65, 0.242, -2.1), stain_mat)
	_add_cylinder(self, "CanvasStain2", 0.22, 0.008, Vector3(0.92, 0.242, -1.2), stain_mat)
	_add_cylinder(self, "CanvasScuff1", 0.55, 0.007, Vector3(0.1, 0.241, -0.4), scuff_mat)

	var line_mat := _material(Color(0.15, 0.25, 0.34), 0.85)
	for lx in [-3.1, 3.1]:
		_add_box(self, "RingLineX", Vector3(0.04, 0.01, 6.24), Vector3(lx, 0.245, 0.0), line_mat)
	for lz in [-3.1, 3.1]:
		_add_box(self, "RingLineZ", Vector3(6.24, 0.01, 0.04), Vector3(0.0, 0.245, lz), line_mat)

	var corner_positions := [
		Vector3(-RING_HALF_SIZE, 0.0, -RING_HALF_SIZE),
		Vector3(RING_HALF_SIZE, 0.0, -RING_HALF_SIZE),
		Vector3(-RING_HALF_SIZE, 0.0, RING_HALF_SIZE),
		Vector3(RING_HALF_SIZE, 0.0, RING_HALF_SIZE)
	]

	for i in range(corner_positions.size()):
		var post := _add_box(self, "RingPost_%d" % i, Vector3(0.22, 2.5, 0.22), corner_positions[i] + Vector3.UP * 1.15, post_material)
		post.rotation.y = PI * 0.25

	var rope_heights := [0.56, 0.96, 1.36]
	for height in rope_heights:
		_add_rope(Vector3(0.0, height, RING_HALF_SIZE), 8.7, true, rope_material)
		_add_rope(Vector3(0.0, height, -RING_HALF_SIZE), 8.7, true, rope_material)
		_add_rope(Vector3(-RING_HALF_SIZE, height, 0.0), 8.7, false, rope_material)
		_add_rope(Vector3(RING_HALF_SIZE, height, 0.0), 8.7, false, rope_material)

	_add_corner_padding(Vector3(-RING_HALF_SIZE, 0.0, -RING_HALF_SIZE), Color(0.10, 0.24, 0.48))
	_add_corner_padding(Vector3(RING_HALF_SIZE, 0.0, -RING_HALF_SIZE), Color(0.52, 0.12, 0.10))
	_add_corner_padding(Vector3(-RING_HALF_SIZE, 0.0, RING_HALF_SIZE), Color(0.52, 0.12, 0.10))
	_add_corner_padding(Vector3(RING_HALF_SIZE, 0.0, RING_HALF_SIZE), Color(0.10, 0.24, 0.48))


func _add_rope(pos: Vector3, length: float, along_x: bool, mat: Material) -> void:
	var rope := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.032
	cm.bottom_radius = 0.032
	cm.height = length
	cm.radial_segments = 6
	rope.mesh = cm
	rope.material_override = mat
	rope.position = pos
	rope.rotation_degrees = Vector3(0.0, 0.0, 90.0) if along_x else Vector3(90.0, 0.0, 0.0)
	add_child(rope)


func _add_corner_padding(pos: Vector3, color: Color) -> void:
	_add_box(self, "CornerPadding", Vector3(0.34, 0.92, 0.34), pos + Vector3.UP * 0.98, _material(color, 0.72))


# ---------------------------------------------------------
# CROWD
# ---------------------------------------------------------

func _build_crowd() -> void:
	var crowd_materials := [
		_material(Color(0.06, 0.08, 0.12)),
		_material(Color(0.12, 0.07, 0.08)),
		_material(Color(0.09, 0.11, 0.15)),
		_material(Color(0.13, 0.11, 0.10)),
		_material(Color(0.05, 0.06, 0.09)),
		_material(Color(0.10, 0.10, 0.13))
	]

	for side in range(4):
		for row in range(3):
			for index in range(12):
				var offset := float(index) * 0.85 - 4.65
				var distance := CROWD_DISTANCE + float(row) * 0.65

				var pos := Vector3.ZERO
				match side:
					0: pos = Vector3(offset, 0.0, -distance)
					1: pos = Vector3(offset, 0.0, distance)
					2: pos = Vector3(-distance, 0.0, offset)
					3: pos = Vector3(distance, 0.0, offset)

				var spec := _create_spectator(pos, crowd_materials[rng.randi_range(0, crowd_materials.size() - 1)])
				_spectators.append({"node": spec, "base_y": pos.y, "phase": rng.randf_range(0.0, TAU)})


func _create_spectator(pos: Vector3, body_material: StandardMaterial3D) -> Node3D:
	var spectator := Node3D.new()
	spectator.name = "Spectator"
	spectator.position = pos

	var body_height := rng.randf_range(0.75, 1.05)
	var body_width := rng.randf_range(0.32, 0.48)

	_add_box(spectator, "Body", Vector3(body_width, body_height, 0.25), Vector3(0.0, body_height * 0.5, 0.0), body_material)
	_add_box(spectator, "LArm", Vector3(0.09, body_height * 0.55, 0.12), Vector3(-body_width * 0.56, body_height * 0.58, 0.04), body_material)
	_add_box(spectator, "RArm", Vector3(0.09, body_height * 0.55, 0.12), Vector3(body_width * 0.56, body_height * 0.58, 0.04), body_material)

	var skin_colors := [
		Color(0.45, 0.30, 0.21),
		Color(0.58, 0.41, 0.30),
		Color(0.32, 0.21, 0.16),
		Color(0.65, 0.50, 0.38)
	]

	var head := MeshInstance3D.new()
	head.mesh = TLRBoxerMesh.make_faceted_sphere(0.16, Vector3(0.95, 1.08, 0.90), 3, 6)
	head.material_override = _material(skin_colors[rng.randi_range(0, skin_colors.size() - 1)])
	head.position = Vector3(0.0, body_height + 0.16, 0.0)
	spectator.add_child(head)

	add_child(spectator)
	var direction := Vector3.ZERO - pos
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		spectator.rotation.y = atan2(-direction.x, -direction.z)

	return spectator


func _update_crowd(delta: float) -> void:
	if reduced_motion:
		return
	if crowd_cheer_timer > 0.0:
		crowd_cheer_timer = maxf(0.0, crowd_cheer_timer - delta)
	var amp := 0.065 if crowd_cheer_timer > 0.0 else 0.014
	var speed := 9.5 if crowd_cheer_timer > 0.0 else 1.8
	for entry in _spectators:
		var node: Node3D = entry.node
		if is_instance_valid(node):
			node.position.y = float(entry.base_y) + absf(sin(idle_time * speed + float(entry.phase))) * amp


# ---------------------------------------------------------
# OPPONENT MODEL (SCULPTED FLAT-SHADED LOW-POLY LIKE IMAGE 1)
# ---------------------------------------------------------

func _build_opponent() -> void:
	opponent_body = Node3D.new()
	opponent_body.name = "OpponentVisual"
	opponent_body.position = opponent_home_position

	var rig := TLRBoxerMesh.build_boxer_rig(
		opponent_body,
		Color(0.58, 0.39, 0.28),
		Color(0.05, 0.07, 0.10),
		Color(0.48, 0.06, 0.05),
		Color(0.07, 0.07, 0.09)
	)
	opponent_material = rig.torso_mat
	opponent_left_upper_arm = rig.left_upper_arm
	opponent_right_upper_arm = rig.right_upper_arm
	opponent_left_forearm = rig.left_forearm
	opponent_right_forearm = rig.right_forearm
	opponent_left_elbow = rig.left_elbow
	opponent_right_elbow = rig.right_elbow
	opponent_left_glove = rig.left_glove
	opponent_right_glove = rig.right_glove

	add_child(opponent_body)


func set_opponent_color(color: Color) -> void:
	if is_instance_valid(opponent_material):
		opponent_material.albedo_color = color.lerp(Color(1.0, 1.0, 1.0), 0.72)


# ---------------------------------------------------------
# FIRST-PERSON CAMERA AND FACETED GLOVES
# ---------------------------------------------------------

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "ArenaCamera"
	camera.position = Vector3(0.0, 1.82, 2.1)
	camera.fov = 74.0
	add_child(camera)
	camera.look_at(opponent_home_position + Vector3.UP * 1.28, Vector3.UP)


func _build_gloves() -> void:
	if not is_instance_valid(camera):
		return

	var glove_tex := TLRBoxerMesh.make_grime_texture(Color(0.52, 0.07, 0.055), 0.14, 901, 0.18)
	var glove_material := _textured_material(glove_tex, 0.50)
	var cuff_material := _material(Color(0.06, 0.08, 0.11), 0.80)
	var tape_material := _material(Color(0.78, 0.80, 0.84), 0.90)

	left_glove = _create_player_glove("LeftPlayerGlove", glove_home_left, glove_material, cuff_material, tape_material, true)
	right_glove = _create_player_glove("RightPlayerGlove", glove_home_right, glove_material, cuff_material, tape_material, false)

	camera.add_child(left_glove)
	camera.add_child(right_glove)


func set_gloves_visible(is_visible: bool) -> void:
	if is_instance_valid(left_glove):
		left_glove.visible = is_visible
	if is_instance_valid(right_glove):
		right_glove.visible = is_visible


func _create_player_glove(
	glove_name: String,
	pos: Vector3,
	glove_material: StandardMaterial3D,
	cuff_material: StandardMaterial3D,
	tape_material: StandardMaterial3D,
	is_left: bool
) -> MeshInstance3D:
	var root := MeshInstance3D.new()
	root.name = glove_name
	root.mesh = TLRBoxerMesh.make_faceted_sphere(0.145, Vector3(0.88, 1.12, 1.30), 5, 10)
	root.material_override = glove_material
	root.position = pos
	root.rotation_degrees = Vector3(16.0, -14.0 if is_left else 14.0, 10.0 if is_left else -10.0)

	var knuckles := MeshInstance3D.new()
	knuckles.mesh = TLRBoxerMesh.make_faceted_box(Vector3(0.17, 0.085, 0.09))
	knuckles.material_override = glove_material
	knuckles.position = Vector3(0.0, 0.04, -0.12)
	root.add_child(knuckles)

	var thumb := MeshInstance3D.new()
	thumb.mesh = TLRBoxerMesh.make_faceted_taper(Vector2(0.052, 0.052), Vector2(0.044, 0.044), 0.14, 6, 1.1)
	thumb.material_override = glove_material
	thumb.position = Vector3(0.105 if is_left else -0.105, 0.015, -0.02)
	thumb.rotation_degrees = Vector3(26.0, 0.0, -22.0 if is_left else 22.0)
	root.add_child(thumb)

	var long_cuff := MeshInstance3D.new()
	long_cuff.mesh = TLRBoxerMesh.make_faceted_taper(Vector2(0.112, 0.115), Vector2(0.104, 0.108), 0.24, 8, 1.02)
	long_cuff.material_override = glove_material
	long_cuff.position = Vector3(0.0, -0.21, 0.05)
	root.add_child(long_cuff)

	var cuff_strap := MeshInstance3D.new()
	cuff_strap.mesh = TLRBoxerMesh.make_faceted_taper(Vector2(0.110, 0.112), Vector2(0.114, 0.116), 0.08, 8, 1.0)
	cuff_strap.material_override = cuff_material
	cuff_strap.position = Vector3(0.0, -0.28, 0.065)
	root.add_child(cuff_strap)

	var tape := MeshInstance3D.new()
	tape.mesh = TLRBoxerMesh.make_faceted_taper(Vector2(0.100, 0.102), Vector2(0.100, 0.102), 0.06, 8, 1.0)
	tape.material_override = tape_material
	tape.position = Vector3(0.0, -0.35, 0.075)
	root.add_child(tape)

	return root


func attach_player_camera(player_camera: Camera3D) -> void:
	if not is_instance_valid(player_camera) or not is_instance_valid(left_glove) or not is_instance_valid(right_glove):
		return
	_active_camera = player_camera
	if left_glove.get_parent() != player_camera:
		left_glove.reparent(player_camera)
		left_glove.position = glove_home_left
	if right_glove.get_parent() != player_camera:
		right_glove.reparent(player_camera)
		right_glove.position = glove_home_right


func _build_particles() -> void:
	# Dense swirling dust motes caught in the underground spotlight beams
	_dust_particles = CPUParticles3D.new()
	_dust_particles.name = "ArenaDustMotes"
	_dust_particles.position = Vector3(0.0, 2.0, -2.2)
	_dust_particles.amount = 72
	_dust_particles.lifetime = 4.8
	_dust_particles.preprocess = 2.5
	_dust_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust_particles.emission_box_extents = Vector3(3.6, 1.5, 2.8)
	_dust_particles.direction = Vector3(0.25, 1.0, 0.0)
	_dust_particles.spread = 45.0
	_dust_particles.gravity = Vector3(0.015, 0.012, 0.0)
	_dust_particles.initial_velocity_min = 0.04
	_dust_particles.initial_velocity_max = 0.14
	_dust_particles.scale_amount_min = 0.012
	_dust_particles.scale_amount_max = 0.028

	var dust_mesh := BoxMesh.new()
	dust_mesh.size = Vector3(1.0, 1.0, 1.0)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.72, 0.90, 1.0, 0.24)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mesh.material = dust_mat
	_dust_particles.mesh = dust_mesh
	add_child(_dust_particles)

	# Drifting soft radial smoke haze wisps near the ropes (no square edges)
	var smoke := CPUParticles3D.new()
	smoke.name = "RingSmokeHaze"
	smoke.position = Vector3(0.0, 1.30, -2.65)
	smoke.amount = 14
	smoke.lifetime = 6.5
	smoke.preprocess = 3.0
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	smoke.emission_box_extents = Vector3(3.4, 0.65, 1.8)
	smoke.direction = Vector3(0.4, 0.35, 0.0)
	smoke.spread = 30.0
	smoke.gravity = Vector3(0.01, 0.02, 0.0)
	smoke.initial_velocity_min = 0.05
	smoke.initial_velocity_max = 0.14
	smoke.scale_amount_min = 0.9
	smoke.scale_amount_max = 1.6

	var smoke_grad := Gradient.new()
	smoke_grad.colors = PackedColorArray([Color(0.48, 0.72, 0.88, 0.065), Color(0.48, 0.72, 0.88, 0.022), Color(0.48, 0.72, 0.88, 0.0)])
	smoke_grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var smoke_tex := GradientTexture2D.new()
	smoke_tex.gradient = smoke_grad
	smoke_tex.fill = GradientTexture2D.FILL_RADIAL
	smoke_tex.fill_from = Vector2(0.5, 0.5)
	smoke_tex.fill_to = Vector2(1.0, 0.5)

	var smoke_mesh := QuadMesh.new()
	smoke_mesh.size = Vector2(1.0, 1.0)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.albedo_texture = smoke_tex
	smoke_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mesh.material = smoke_mat
	smoke.mesh = smoke_mesh
	add_child(smoke)

	# Second low floor-level smoke haze layer for heavy underground ring atmosphere
	var floor_smoke := smoke.duplicate() as CPUParticles3D
	floor_smoke.name = "FloorSmokeHaze"
	floor_smoke.position = Vector3(0.0, 0.42, -1.8)
	floor_smoke.amount = 16
	floor_smoke.scale_amount_min = 1.2
	floor_smoke.scale_amount_max = 2.1
	add_child(floor_smoke)

	_impact_particles = CPUParticles3D.new()
	_impact_particles.name = "ImpactSparks"
	_impact_particles.one_shot = true
	_impact_particles.explosiveness = 0.95
	_impact_particles.emitting = false
	_impact_particles.amount = 18
	_impact_particles.lifetime = 0.35
	_impact_particles.direction = Vector3(0.0, 0.4, 1.0)
	_impact_particles.spread = 75.0
	_impact_particles.gravity = Vector3(0.0, -5.5, 0.0)
	_impact_particles.initial_velocity_min = 1.6
	_impact_particles.initial_velocity_max = 3.8
	_impact_particles.scale_amount_min = 0.025
	_impact_particles.scale_amount_max = 0.055

	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(1.0, 1.0, 1.0)
	var spark_mat := StandardMaterial3D.new()
	spark_mat.albedo_color = Color(1.0, 0.82, 0.45, 0.9)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.72, 0.32)
	spark_mat.emission_energy_multiplier = 2.0
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mesh.material = spark_mat
	_impact_particles.mesh = spark_mesh
	add_child(_impact_particles)


# ---------------------------------------------------------
# PLAYER ATTACK ANIMATIONS
# ---------------------------------------------------------

func player_action(move_id: String) -> void:
	active_move = move_id
	player_action_timer = 0.24
	glove_action_rot = Vector3.ZERO

	match move_id:
		"jab", "one_two":
			glove_action_offset = Vector3(0.08, 0.04, -0.36)
			glove_action_rot = Vector3(-14.0, -8.0, 12.0)
		"cross", "counter", "haymaker", "overhand":
			glove_action_offset = Vector3(-0.15, 0.05, -0.44)
			glove_action_rot = Vector3(-18.0, 16.0, -22.0)
		"hook", "body_shot":
			glove_action_offset = Vector3(0.26, 0.02, -0.32)
			glove_action_rot = Vector3(-8.0, -34.0, 28.0)
		"uppercut":
			glove_action_offset = Vector3(-0.08, 0.28, -0.32)
			glove_action_rot = Vector3(32.0, 12.0, -14.0)
		"block":
			glove_action_offset = Vector3(0.10, 0.14, -0.06)
		"slip":
			glove_action_offset = Vector3(-0.20, -0.07, 0.04)
			glove_action_rot = Vector3(0.0, 0.0, 14.0)
		_:
			glove_action_offset = Vector3(0.0, 0.04, -0.18)


func _update_gloves(delta: float) -> void:
	if not is_instance_valid(left_glove) or not is_instance_valid(right_glove):
		return

	var sway_x := 0.0 if reduced_motion else sin(idle_time * 2.1) * 0.010
	var sway_y := 0.0 if reduced_motion else absf(sin(idle_time * 4.2)) * 0.008
	var idle_l := glove_home_left + Vector3(sway_x, sway_y, 0.0)
	var idle_r := glove_home_right + Vector3(sway_x, sway_y, 0.0)
	var base_rot_l := Vector3(12.0, -14.0, 10.0)
	var base_rot_r := Vector3(12.0, 14.0, -10.0)

	if player_action_timer > 0.0:
		player_action_timer = maxf(0.0, player_action_timer - delta)
		var progress := sin((player_action_timer / 0.24) * PI)
		var offset := glove_action_offset * progress
		var rot_off := glove_action_rot * progress

		if active_move in ["cross", "counter", "haymaker", "uppercut", "overhand"]:
			right_glove.position = idle_r + offset
			right_glove.rotation_degrees = base_rot_r + rot_off
			left_glove.position = idle_l
			left_glove.rotation_degrees = base_rot_l
		elif active_move in ["jab", "hook", "body_shot", "one_two"]:
			left_glove.position = idle_l + offset
			left_glove.rotation_degrees = base_rot_l + rot_off
			right_glove.position = idle_r
			right_glove.rotation_degrees = base_rot_r
		elif active_move == "block":
			left_glove.position = idle_l + Vector3(0.14, 0.14, -0.04) * progress
			right_glove.position = idle_r + Vector3(-0.14, 0.14, -0.04) * progress
			left_glove.rotation_degrees = base_rot_l
			right_glove.rotation_degrees = base_rot_r
		else:
			left_glove.position = idle_l + offset
			right_glove.position = idle_r + offset
			left_glove.rotation_degrees = base_rot_l + rot_off
			right_glove.rotation_degrees = base_rot_r + rot_off
	else:
		left_glove.position = left_glove.position.lerp(idle_l, delta * 12.0)
		right_glove.position = right_glove.position.lerp(idle_r, delta * 12.0)
		left_glove.rotation_degrees = left_glove.rotation_degrees.lerp(base_rot_l, delta * 12.0)
		right_glove.rotation_degrees = right_glove.rotation_degrees.lerp(base_rot_r, delta * 12.0)


# ---------------------------------------------------------
# OPPONENT HIT AND ATTACK REACTIONS
# ---------------------------------------------------------

func opponent_hit() -> void:
	opponent_hit_timer = 0.20
	trigger_hit_sparks(true)
	trigger_crowd_surge(0.95)


func show_enemy_telegraph(action_name: String) -> void:
	opponent_telegraph_pose = action_name.to_lower()
	opponent_telegraph_active = true
	opponent_attack_timer = 0.0


func enemy_attack(action_name: String = "") -> void:
	opponent_telegraph_active = false
	opponent_telegraph_pose = action_name.to_lower()
	opponent_attack_timer = 0.30


func impact_shake(strength: float = 1.0) -> void:
	impact_timer = maxf(impact_timer, 0.20 * clampf(strength, 0.7, 1.5))


func _update_opponent_animation(delta: float) -> void:
	if not is_instance_valid(opponent_body):
		return

	var bob := 0.0 if reduced_motion else sin(idle_time * 2.5) * 0.022
	var target_position := opponent_home_position + Vector3(0.0, bob, 0.0)
	var target_rotation := Vector3.ZERO

	var l_shoulder := Vector3(-0.305, 1.72, 0.0)
	var r_shoulder := Vector3(0.305, 1.72, 0.0)
	var l_elbow := Vector3(-0.37, 1.39, 0.15)
	var r_elbow := Vector3(0.37, 1.39, 0.15)
	var l_hand := Vector3(-0.18, 1.88, 0.34)
	var r_hand := Vector3(0.18, 1.88, 0.34)

	if opponent_hit_timer > 0.0:
		opponent_hit_timer = maxf(0.0, opponent_hit_timer - delta)
		target_position.x = opponent_home_position.x + 0.14
		target_position.z = opponent_home_position.z - 0.10
		target_rotation.z = 0.13
		target_rotation.x = -0.10
		l_elbow = Vector3(-0.56, 1.44, 0.04)
		r_elbow = Vector3(0.56, 1.44, 0.04)
		l_hand = Vector3(-0.40, 1.72, 0.20)
		r_hand = Vector3(0.40, 1.72, 0.20)

	elif opponent_attack_timer > 0.0:
		opponent_attack_timer = maxf(0.0, opponent_attack_timer - delta)
		target_position.z = opponent_home_position.z + 0.24
		target_rotation.x = 0.12
		target_rotation.y = -0.22
		r_elbow = Vector3(0.24, 1.62, 0.45)
		r_hand = Vector3(0.14, 1.84, 0.92)
		l_elbow = Vector3(-0.44, 1.46, 0.16)
		l_hand = Vector3(-0.24, 1.86, 0.36)

	elif opponent_telegraph_active:
		if opponent_telegraph_pose.contains("heavy") or opponent_telegraph_pose.contains("right") or opponent_telegraph_pose.contains("champion"):
			target_position.x = opponent_home_position.x - 0.12
			target_rotation.y = -0.24
			target_rotation.z = -0.07
			r_elbow = Vector3(0.60, 1.48, -0.16)
			r_hand = Vector3(0.50, 1.88, -0.06)
			l_hand = Vector3(-0.22, 1.86, 0.38)
		elif opponent_telegraph_pose.contains("body") or opponent_telegraph_pose.contains("elbow"):
			target_position.y = opponent_home_position.y - 0.14
			target_position.z = opponent_home_position.z + 0.08
			target_rotation.x = 0.18
			r_elbow = Vector3(0.52, 1.18, 0.06)
			r_hand = Vector3(0.36, 1.42, 0.34)
			l_elbow = Vector3(-0.48, 1.24, 0.10)
			l_hand = Vector3(-0.30, 1.54, 0.30)
		elif opponent_telegraph_pose.contains("jab") or opponent_telegraph_pose.contains("flurry") or opponent_telegraph_pose.contains("combination"):
			target_position.z = opponent_home_position.z + 0.08
			target_rotation.x = 0.06
			target_rotation.y = 0.14
			l_elbow = Vector3(-0.34, 1.54, 0.30)
			l_hand = Vector3(-0.18, 1.84, 0.62)
			r_elbow = Vector3(0.42, 1.44, 0.16)
			r_hand = Vector3(0.22, 1.84, 0.34)
		elif opponent_telegraph_pose.contains("counter"):
			target_position.z = opponent_home_position.z - 0.10
			target_rotation.y = 0.18
			target_rotation.z = 0.06
			r_elbow = Vector3(0.46, 1.42, 0.06)
			r_hand = Vector3(0.30, 1.86, 0.22)
		elif opponent_telegraph_pose.contains("reset") or opponent_telegraph_pose.contains("desperate"):
			target_position.y = opponent_home_position.y - 0.05
			l_elbow = Vector3(-0.48, 1.32, 0.04)
			r_elbow = Vector3(0.48, 1.32, 0.04)
			l_hand = Vector3(-0.38, 1.42, 0.22)
			r_hand = Vector3(0.38, 1.42, 0.22)
		else:
			target_position.z = opponent_home_position.z + 0.04
			target_rotation.y = 0.08

	var blend := 1.0 - exp(-delta * 10.0)
	opponent_body.position = opponent_body.position.lerp(target_position, blend)
	opponent_body.rotation = opponent_body.rotation.lerp(target_rotation, blend)
	if is_instance_valid(opponent_left_glove) and is_instance_valid(opponent_right_glove):
		var cur_l_hand := opponent_left_glove.position.lerp(l_hand, blend)
		var cur_r_hand := opponent_right_glove.position.lerp(r_hand, blend)
		var cur_l_elbow := opponent_left_elbow.position.lerp(l_elbow, blend) if is_instance_valid(opponent_left_elbow) else l_elbow
		var cur_r_elbow := opponent_right_elbow.position.lerp(r_elbow, blend) if is_instance_valid(opponent_right_elbow) else r_elbow
		TLRBoxerMesh.pose_arm(opponent_left_upper_arm, opponent_left_forearm, opponent_left_elbow, opponent_left_glove, l_shoulder, cur_l_elbow, cur_l_hand)
		TLRBoxerMesh.pose_arm(opponent_right_upper_arm, opponent_right_forearm, opponent_right_elbow, opponent_right_glove, r_shoulder, cur_r_elbow, cur_r_hand)


func _update_camera_shake(delta: float) -> void:
	var shake_cam: Camera3D = _active_camera if is_instance_valid(_active_camera) else camera
	if not is_instance_valid(shake_cam):
		return
	if impact_timer > 0.0:
		impact_timer = maxf(0.0, impact_timer - delta)
		var k := clampf(impact_timer / 0.20, 0.0, 1.0)
		shake_cam.h_offset = rng.randf_range(-0.075, 0.075) * k
		shake_cam.v_offset = rng.randf_range(-0.060, 0.060) * k
	else:
		if absf(shake_cam.v_offset) > 0.0005:
			shake_cam.v_offset = lerpf(shake_cam.v_offset, 0.0, delta * 14.0)
		if shake_cam == camera and absf(shake_cam.h_offset) > 0.0005:
			shake_cam.h_offset = lerpf(shake_cam.h_offset, 0.0, delta * 14.0)


# ---------------------------------------------------------
# MESH HELPERS
# ---------------------------------------------------------

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _textured_material(tex: Texture2D, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0)
	material.albedo_texture = tex
	material.roughness = roughness
	return material


func _add_box(parent: Node3D, mesh_name: String, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node3D, mesh_name: String, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func _add_limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var direction := end - start
	var length := maxf(0.05, direction.length())
	var limb := MeshInstance3D.new()
	limb.name = "Limb"
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 6
	limb.mesh = mesh
	limb.material_override = material
	limb.position = (start + end) * 0.5
	if direction.length() > 0.001:
		limb.quaternion = Quaternion(Vector3.UP, direction.normalized())
	parent.add_child(limb)
	return limb
