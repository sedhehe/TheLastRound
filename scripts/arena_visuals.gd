
extends Node3D

var camera: Camera3D
var arena_light: OmniLight3D
var opponent_body: Node3D
var opponent_material: StandardMaterial3D

var left_glove: MeshInstance3D
var right_glove: MeshInstance3D
var glove_home_left := Vector3(-0.28, -0.22, -0.58)
var glove_home_right := Vector3(0.28, -0.22, -0.58)

var opponent_home_position := Vector3(0.0, 0.0, -2.55)
var opponent_hit_timer := 0.0
var opponent_attack_timer := 0.0
var opponent_telegraph_pose := ""
var opponent_telegraph_active := false
var player_action_timer := 0.0
var impact_timer := 0.0

var active_move := ""
var glove_action_offset := Vector3.ZERO

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

	return {
		"camera": camera,
		"arena_light": arena_light,
		"opponent_mesh": opponent_body,
		"opponent_mat": opponent_material
	}


func _process(delta: float) -> void:
	_update_gloves(delta)
	_update_opponent_animation(delta)
	_update_camera_shake(delta)


# ---------------------------------------------------------
# ENVIRONMENT
# ---------------------------------------------------------

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.12, 0.16, 0.23)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.85

	world_environment.environment = environment
	add_child(world_environment)

	var floor_material := _material(
		Color(0.045, 0.05, 0.065),
		0.95
	)

	_add_box(
		self,
		"BasementFloor",
		Vector3(30.0, 0.3, 30.0),
		Vector3(0.0, -0.35, 0.0),
		floor_material
	)

	var back_wall_material := _material(
		Color(0.035, 0.045, 0.065),
		1.0
	)

	_add_box(
		self,
		"BackWall",
		Vector3(30.0, 8.0, 0.5),
		Vector3(0.0, 3.5, -10.0),
		back_wall_material
	)

	_add_box(
		self,
		"LeftWall",
		Vector3(0.5, 8.0, 30.0),
		Vector3(-10.0, 3.5, 0.0),
		back_wall_material
	)

	_add_box(
		self,
		"RightWall",
		Vector3(0.5, 8.0, 30.0),
		Vector3(10.0, 3.5, 0.0),
		back_wall_material
	)

	_add_box(
		self,
		"RearCeilingBeam",
		Vector3(30.0, 0.35, 0.5),
		Vector3(0.0, 7.0, -8.0),
		_material(Color(0.07, 0.075, 0.09))
	)


# ---------------------------------------------------------
# LIGHTING
# ---------------------------------------------------------

func _build_lighting() -> void:
	var ambient := DirectionalLight3D.new()
	ambient.name = "ColdAmbientLight"
	ambient.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	ambient.light_color = Color(0.55, 0.68, 1.0)
	ambient.light_energy = 0.35
	ambient.shadow_enabled = true
	add_child(ambient)

	arena_light = OmniLight3D.new()
	arena_light.name = "ArenaBlueLight"
	arena_light.position = Vector3(0.0, 5.0, 0.0)
	arena_light.light_color = Color(0.35, 0.55, 1.0)
	arena_light.light_energy = 2.2
	arena_light.omni_range = 13.0
	arena_light.shadow_enabled = true
	add_child(arena_light)

	var warm_light := OmniLight3D.new()
	warm_light.name = "SecondaryArenaLight"
	warm_light.position = Vector3(0.0, 3.8, 1.0)
	warm_light.light_color = Color(0.8, 0.55, 0.36)
	warm_light.light_energy = 0.65
	warm_light.omni_range = 8.0
	add_child(warm_light)

	_add_led(
		Vector3(-4.8, 4.3, -4.8),
		Color(0.15, 0.45, 1.0)
	)

	_add_led(
		Vector3(4.8, 4.3, -4.8),
		Color(0.15, 0.45, 1.0)
	)

	_add_led(
		Vector3(-4.8, 4.3, 4.8),
		Color(0.15, 0.45, 1.0)
	)

	_add_led(
		Vector3(4.8, 4.3, 4.8),
		Color(0.15, 0.45, 1.0)
	)


func _add_led(position: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = 1.0
	light.omni_range = 5.0
	add_child(light)


# ---------------------------------------------------------
# BOXING RING
# ---------------------------------------------------------

func _build_ring() -> void:
	var dark_metal := _material(Color(0.055, 0.06, 0.075))
	var canvas_material := _material(Color(0.20, 0.19, 0.18))
	var rope_material := _material(Color(0.35, 0.38, 0.44))
	var post_material := _material(Color(0.10, 0.12, 0.16))

	_add_box(
		self,
		"RingFoundation",
		Vector3(9.0, 0.45, 9.0),
		Vector3(0.0, -0.05, 0.0),
		dark_metal
	)

	_add_box(
		self,
		"RingCanvas",
		Vector3(8.25, 0.08, 8.25),
		Vector3(0.0, 0.20, 0.0),
		canvas_material
	)

	var corner_positions := [
		Vector3(-RING_HALF_SIZE, 0.0, -RING_HALF_SIZE),
		Vector3(RING_HALF_SIZE, 0.0, -RING_HALF_SIZE),
		Vector3(-RING_HALF_SIZE, 0.0, RING_HALF_SIZE),
		Vector3(RING_HALF_SIZE, 0.0, RING_HALF_SIZE)
	]

	for i in range(corner_positions.size()):
		var post := _add_box(
			self,
			"RingPost_%d" % i,
			Vector3(0.22, 2.5, 0.22),
			corner_positions[i] + Vector3.UP * 1.15,
			post_material
		)

		post.rotation.y = PI * 0.25

	var rope_heights := [0.55, 0.95, 1.35]

	for height in rope_heights:
		_add_box(
			self,
			"FrontRope",
			Vector3(8.7, 0.075, 0.075),
			Vector3(0.0, height, RING_HALF_SIZE),
			rope_material
		)

		_add_box(
			self,
			"BackRope",
			Vector3(8.7, 0.075, 0.075),
			Vector3(0.0, height, -RING_HALF_SIZE),
			rope_material
		)

		_add_box(
			self,
			"LeftRope",
			Vector3(0.075, 0.075, 8.7),
			Vector3(-RING_HALF_SIZE, height, 0.0),
			rope_material
		)

		_add_box(
			self,
			"RightRope",
			Vector3(0.075, 0.075, 8.7),
			Vector3(RING_HALF_SIZE, height, 0.0),
			rope_material
		)

	_add_corner_padding(
		Vector3(-RING_HALF_SIZE, 0.0, -RING_HALF_SIZE),
		Color(0.12, 0.25, 0.55)
	)

	_add_corner_padding(
		Vector3(RING_HALF_SIZE, 0.0, -RING_HALF_SIZE),
		Color(0.55, 0.12, 0.10)
	)

	_add_corner_padding(
		Vector3(-RING_HALF_SIZE, 0.0, RING_HALF_SIZE),
		Color(0.55, 0.12, 0.10)
	)

	_add_corner_padding(
		Vector3(RING_HALF_SIZE, 0.0, RING_HALF_SIZE),
		Color(0.12, 0.25, 0.55)
	)


func _add_corner_padding(position: Vector3, color: Color) -> void:
	_add_box(
		self,
		"CornerPadding",
		Vector3(0.34, 0.42, 0.34),
		position + Vector3.UP * 1.25,
		_material(color)
	)


# ---------------------------------------------------------
# CROWD
# ---------------------------------------------------------

func _build_crowd() -> void:
	var crowd_materials := [
		_material(Color(0.10, 0.12, 0.17)),
		_material(Color(0.22, 0.12, 0.12)),
		_material(Color(0.16, 0.18, 0.22)),
		_material(Color(0.25, 0.22, 0.18)),
		_material(Color(0.08, 0.09, 0.12)),
		_material(Color(0.18, 0.16, 0.19))
	]

	for side in range(4):
		for row in range(3):
			for index in range(12):
				var offset := float(index) * 0.85 - 4.65
				var distance := CROWD_DISTANCE + float(row) * 0.65

				var position := Vector3.ZERO

				match side:
					0:
						position = Vector3(offset, 0.0, -distance)
					1:
						position = Vector3(offset, 0.0, distance)
					2:
						position = Vector3(-distance, 0.0, offset)
					3:
						position = Vector3(distance, 0.0, offset)

				_create_spectator(
					position,
					crowd_materials[rng.randi_range(
						0,
						crowd_materials.size() - 1
					)],
					side
				)


func _create_spectator(
	position: Vector3,
	body_material: StandardMaterial3D,
	side: int
) -> void:
	var spectator := Node3D.new()
	spectator.name = "Spectator"
	spectator.position = position

	var body_height := rng.randf_range(0.75, 1.05)
	var body_width := rng.randf_range(0.32, 0.48)

	_add_box(
		spectator,
		"Body",
		Vector3(body_width, body_height, 0.25),
		Vector3(0.0, body_height * 0.5, 0.0),
		body_material
	)

	var skin_colors := [
		Color(0.55, 0.36, 0.25),
		Color(0.72, 0.51, 0.38),
		Color(0.38, 0.25, 0.19),
		Color(0.82, 0.65, 0.50)
	]

	var head := _add_sphere(
		spectator,
		"Head",
		0.17,
		Vector3(0.0, body_height + 0.17, 0.0),
		_material(skin_colors[rng.randi_range(0, skin_colors.size() - 1)])
	)

	head.scale = Vector3(1.0, 1.1, 0.9)

	var arm_material := body_material

	_add_limb(
		spectator,
		Vector3(-body_width * 0.5, body_height * 0.8, 0.0),
		Vector3(-body_width * 0.65, body_height * 0.25, 0.02),
		0.075,
		arm_material
	)

	_add_limb(
		spectator,
		Vector3(body_width * 0.5, body_height * 0.8, 0.0),
		Vector3(body_width * 0.65, body_height * 0.25, 0.02),
		0.075,
		arm_material
	)

	var leg_material := _material(Color(0.045, 0.05, 0.065))

	_add_limb(
		spectator,
		Vector3(-0.10, 0.0, 0.0),
		Vector3(-0.10, -0.55, 0.0),
		0.085,
		leg_material
	)

	_add_limb(
		spectator,
		Vector3(0.10, 0.0, 0.0),
		Vector3(0.10, -0.55, 0.0),
		0.085,
		leg_material
	)

	add_child(spectator)

	var facing_point := Vector3.ZERO
	facing_point.y = 0.0

	var direction := facing_point - position
	direction.y = 0.0

	if direction.length_squared() > 0.001:
		spectator.rotation.y = atan2(
			-direction.x,
			-direction.z
		)


# ---------------------------------------------------------
# OPPONENT MODEL
# ---------------------------------------------------------

func _build_opponent() -> void:
	opponent_body = Node3D.new()
	opponent_body.name = "OpponentVisual"
	opponent_body.position = opponent_home_position

	opponent_material = _material(
		Color(0.34, 0.19, 0.16),
		0.9
	)

	var skin_material := _material(Color(0.55, 0.36, 0.26))
	var shorts_material := _material(Color(0.055, 0.06, 0.075))
	var glove_material := _material(Color(0.40, 0.045, 0.035))

	# Torso
	var torso := _add_capsule(
		opponent_body,
		"Torso",
		0.38,
		1.05,
		Vector3(0.0, 1.45, 0.0),
		opponent_material
	)

	torso.scale = Vector3(1.0, 1.0, 0.8)

	# Neck and head
	_add_cylinder(
		opponent_body,
		"Neck",
		0.12,
		0.22,
		Vector3(0.0, 2.05, 0.0),
		skin_material
	)

	_add_sphere(
		opponent_body,
		"Head",
		0.25,
		Vector3(0.0, 2.36, 0.0),
		skin_material
	)

	# Shorts
	_add_box(
		opponent_body,
		"Shorts",
		Vector3(0.72, 0.42, 0.48),
		Vector3(0.0, 0.78, 0.0),
		shorts_material
	)

	# Legs
	_add_limb(
		opponent_body,
		Vector3(-0.19, 0.68, 0.0),
		Vector3(-0.23, 0.12, 0.0),
		0.15,
		shorts_material
	)

	_add_limb(
		opponent_body,
		Vector3(0.19, 0.68, 0.0),
		Vector3(0.23, 0.12, 0.0),
		0.15,
		shorts_material
	)

	# Feet
	_add_box(
		opponent_body,
		"LeftFoot",
		Vector3(0.22, 0.12, 0.38),
		Vector3(-0.23, 0.06, -0.08),
		shorts_material
	)

	_add_box(
		opponent_body,
		"RightFoot",
		Vector3(0.22, 0.12, 0.38),
		Vector3(0.23, 0.06, -0.08),
		shorts_material
	)

	# Arms
	_add_limb(
		opponent_body,
		Vector3(-0.34, 1.82, 0.0),
		Vector3(-0.62, 1.35, -0.08),
		0.15,
		skin_material
	)

	_add_limb(
		opponent_body,
		Vector3(0.34, 1.82, 0.0),
		Vector3(0.62, 1.35, -0.08),
		0.15,
		skin_material
	)

	# Forearms
	_add_limb(
		opponent_body,
		Vector3(-0.62, 1.35, -0.08),
		Vector3(-0.40, 1.12, -0.32),
		0.13,
		skin_material
	)

	_add_limb(
		opponent_body,
		Vector3(0.62, 1.35, -0.08),
		Vector3(0.40, 1.12, -0.32),
		0.13,
		skin_material
	)

	# Gloves
	_add_sphere(
		opponent_body,
		"LeftGlove",
		0.19,
		Vector3(-0.40, 1.10, -0.38),
		glove_material
	)

	_add_sphere(
		opponent_body,
		"RightGlove",
		0.19,
		Vector3(0.40, 1.10, -0.38),
		glove_material
	)

	add_child(opponent_body)


func set_opponent_color(color: Color) -> void:
	if is_instance_valid(opponent_material):
		opponent_material.albedo_color = color


# ---------------------------------------------------------
# FIRST-PERSON CAMERA AND GLOVES
# ---------------------------------------------------------

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "ArenaCamera"
	camera.position = Vector3(0.0, 1.62, 2.1)
	camera.fov = 78.0
	add_child(camera)

	camera.look_at(
		opponent_home_position + Vector3.UP * 1.25,
		Vector3.UP
	)


func _build_gloves() -> void:
	if not is_instance_valid(camera):
		return

	var glove_material := _material(
		Color(0.48, 0.055, 0.045),
		0.65
	)

	var cuff_material := _material(
		Color(0.09, 0.10, 0.13),
		0.8
	)

	left_glove = _create_player_glove(
		"LeftPlayerGlove",
		glove_home_left,
		glove_material,
		cuff_material
	)

	right_glove = _create_player_glove(
		"RightPlayerGlove",
		glove_home_right,
		glove_material,
		cuff_material
	)

	camera.add_child(left_glove)
	camera.add_child(right_glove)


func _create_player_glove(
	glove_name: String,
	position: Vector3,
	glove_material: StandardMaterial3D,
	cuff_material: StandardMaterial3D
) -> MeshInstance3D:
	var root := MeshInstance3D.new()
	root.name = glove_name

	var glove_mesh := SphereMesh.new()
	glove_mesh.radius = 0.17
	glove_mesh.height = 0.34
	root.mesh = glove_mesh
	root.material_override = glove_material
	root.position = position
	root.scale = Vector3(1.0, 0.9, 1.25)

	var cuff := MeshInstance3D.new()
	cuff.name = "Cuff"

	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.11
	cuff_mesh.bottom_radius = 0.14
	cuff_mesh.height = 0.20

	cuff.mesh = cuff_mesh
	cuff.material_override = cuff_material
	cuff.position = Vector3(0.0, -0.17, 0.06)

	root.add_child(cuff)

	return root


# Call this after the PlayerController has created its camera.
# It moves the gloves from the unused arena camera to the active player camera.
func attach_player_camera(player_camera: Camera3D) -> void:
	if not is_instance_valid(player_camera):
		return

	if not is_instance_valid(left_glove):
		return

	if not is_instance_valid(right_glove):
		return

	if left_glove.get_parent() != player_camera:
		left_glove.reparent(player_camera)
		left_glove.position = glove_home_left

	if right_glove.get_parent() != player_camera:
		right_glove.reparent(player_camera)
		right_glove.position = glove_home_right


# ---------------------------------------------------------
# PLAYER ATTACK ANIMATIONS
# ---------------------------------------------------------

func player_action(move_id: String) -> void:
	active_move = move_id
	player_action_timer = 0.20

	match move_id:
		"jab":
			glove_action_offset = Vector3(0.0, 0.0, -0.30)

		"cross":
			glove_action_offset = Vector3(0.16, 0.0, -0.38)

		"hook":
			glove_action_offset = Vector3(-0.22, 0.04, -0.30)

		"uppercut":
			glove_action_offset = Vector3(0.0, 0.25, -0.30)

		_:
			glove_action_offset = Vector3(0.0, 0.0, -0.15)


func _update_gloves(delta: float) -> void:
	if not is_instance_valid(left_glove):
		return

	if not is_instance_valid(right_glove):
		return

	if player_action_timer > 0.0:
		player_action_timer = maxf(
			0.0,
			player_action_timer - delta
		)

		var progress := player_action_timer / 0.20
		var offset := glove_action_offset * progress

		if active_move == "cross" or active_move == "jab":
			right_glove.position = glove_home_right + offset
			left_glove.position = glove_home_left

		elif active_move == "hook":
			left_glove.position = glove_home_left + offset
			right_glove.position = glove_home_right

		elif active_move == "uppercut":
			right_glove.position = glove_home_right + offset
			left_glove.position = glove_home_left + offset * 0.35

	else:
		left_glove.position = left_glove.position.lerp(
			glove_home_left,
			delta * 12.0
		)

		right_glove.position = right_glove.position.lerp(
			glove_home_right,
			delta * 12.0
		)


# ---------------------------------------------------------
# OPPONENT HIT AND ATTACK REACTIONS
# ---------------------------------------------------------

func opponent_hit() -> void:
	opponent_hit_timer = 0.18


func show_enemy_telegraph(action_name: String) -> void:
	opponent_telegraph_pose = action_name.to_lower()
	opponent_telegraph_active = true
	opponent_attack_timer = 0.0


func enemy_attack(action_name: String = "") -> void:
	opponent_telegraph_active = false
	opponent_telegraph_pose = action_name.to_lower()
	opponent_attack_timer = 0.30


func impact_shake() -> void:
	impact_timer = 0.12


func _update_opponent_animation(delta: float) -> void:
	if not is_instance_valid(opponent_body):
		return

	var target_position := opponent_home_position
	var target_rotation := Vector3.ZERO

	if opponent_hit_timer > 0.0:
		opponent_hit_timer = maxf(0.0, opponent_hit_timer - delta)
		target_position.x = 0.16
		target_position.z = opponent_home_position.z - 0.08
		target_rotation.z = 0.13
		target_rotation.x = -0.08

	elif opponent_attack_timer > 0.0:
		opponent_attack_timer = maxf(0.0, opponent_attack_timer - delta)
		target_position.z = opponent_home_position.z + 0.30
		target_rotation.x = 0.12
		target_rotation.z = -0.04

	elif opponent_telegraph_active:
		# Hold a readable anticipation pose for the player's entire decision.
		if opponent_telegraph_pose.contains("heavy") or opponent_telegraph_pose.contains("right") or opponent_telegraph_pose.contains("champion"):
			target_position.x = -0.12
			target_rotation.y = -0.20
			target_rotation.z = -0.08
		elif opponent_telegraph_pose.contains("body") or opponent_telegraph_pose.contains("elbow"):
			target_position.y = -0.10
			target_position.z = 0.08
			target_rotation.x = 0.20
		elif opponent_telegraph_pose.contains("jab") or opponent_telegraph_pose.contains("flurry") or opponent_telegraph_pose.contains("combination"):
			target_position.z = 0.10
			target_rotation.x = 0.07
			target_rotation.y = 0.10
		elif opponent_telegraph_pose.contains("counter"):
			target_position.z = -0.10
			target_rotation.y = 0.18
			target_rotation.z = 0.06
		elif opponent_telegraph_pose.contains("reset") or opponent_telegraph_pose.contains("desperate"):
			target_position.y = -0.05
			target_rotation.z = 0.05
		else:
			target_position.z = 0.04
			target_rotation.y = 0.08

	opponent_body.position = opponent_body.position.lerp(target_position, 1.0 - exp(-delta * 9.0))
	opponent_body.rotation = opponent_body.rotation.lerp(target_rotation, 1.0 - exp(-delta * 9.0))

func _update_camera_shake(delta: float) -> void:
	if not is_instance_valid(camera):
		return

	if impact_timer > 0.0:
		impact_timer = maxf(0.0, impact_timer - delta)

		camera.position.x = rng.randf_range(-0.025, 0.025)
		camera.position.y = 1.62 + rng.randf_range(-0.02, 0.02)
	else:
		camera.position = camera.position.lerp(
			Vector3(0.0, 1.62, 0.0),
			delta * 12.0
		)


# ---------------------------------------------------------
# MESH HELPERS
# ---------------------------------------------------------

func _material(
	color: Color,
	roughness: float = 0.9
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _add_box(
	parent: Node3D,
	mesh_name: String,
	size: Vector3,
	position: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name

	var mesh := BoxMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.material_override = material
	instance.position = position

	parent.add_child(instance)
	return instance


func _add_sphere(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	position: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8

	instance.mesh = mesh
	instance.material_override = material
	instance.position = position

	parent.add_child(instance)
	return instance


func _add_cylinder(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	height: float,
	position: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10

	instance.mesh = mesh
	instance.material_override = material
	instance.position = position

	parent.add_child(instance)
	return instance


func _add_capsule(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	height: float,
	position: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 6

	instance.mesh = mesh
	instance.material_override = material
	instance.position = position

	parent.add_child(instance)
	return instance


func _add_limb(
	parent: Node3D,
	start: Vector3,
	end: Vector3,
	radius: float,
	material: Material
) -> MeshInstance3D:
	var direction := end - start
	var length := direction.length()

	var limb := MeshInstance3D.new()
	limb.name = "Limb"

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 10

	limb.mesh = mesh
	limb.material_override = material
	limb.position = (start + end) * 0.5

	if length > 0.001:
		limb.quaternion = Quaternion(
			Vector3.UP,
			direction.normalized()
		)

	parent.add_child(limb)
	return limb
