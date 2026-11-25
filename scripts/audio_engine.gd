extends Node

const SAMPLE_RATE := 22050

var _samples: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _comm_player: AudioStreamPlayer
var _menu_music: AudioStreamPlayer
var _combat_music: AudioStreamPlayer
var _room_ambience: AudioStreamPlayer
var _audience_ambience: AudioStreamPlayer
var _current_ambience: String = ""
var _initialized: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 424242
	_ensure_buses()
	if DisplayServer.get_name() == "headless":
		_initialized = true
		return
	_build_sample_bank()
	_build_players()
	if get_tree():
		get_tree().node_added.connect(_on_node_added)
	_initialized = true


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX", "Commentary"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _build_players() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.max_polyphony = 2
		add_child(p)
		_sfx_players.append(p)

	_comm_player = AudioStreamPlayer.new()
	_comm_player.bus = "Commentary"
	add_child(_comm_player)

	_menu_music = AudioStreamPlayer.new()
	_menu_music.bus = "Music"
	_menu_music.stream = _samples.get("music_menu")
	_menu_music.volume_db = -10.5
	add_child(_menu_music)

	_combat_music = AudioStreamPlayer.new()
	_combat_music.bus = "Music"
	_combat_music.stream = _samples.get("music_combat")
	_combat_music.volume_db = -10.0
	add_child(_combat_music)

	_room_ambience = AudioStreamPlayer.new()
	_room_ambience.bus = "Music"
	_room_ambience.stream = _samples.get("ambience_room")
	_room_ambience.volume_db = -20.0
	add_child(_room_ambience)

	_audience_ambience = AudioStreamPlayer.new()
	_audience_ambience.bus = "SFX"
	_audience_ambience.stream = _samples.get("ambience_audience")
	_audience_ambience.volume_db = -3.0
	add_child(_audience_ambience)


func _on_node_added(node: Node) -> void:
	if node is Button:
		var btn := node as Button
		if not btn.pressed.is_connected(_on_any_button_pressed):
			btn.pressed.connect(_on_any_button_pressed)


func _on_any_button_pressed() -> void:
	play_sfx("ui_click", -10.0)


func apply_volumes(settings: Dictionary) -> void:
	_ensure_buses()
	_set_bus_pct("Master", int(settings.get("master_volume", 80)))
	_set_bus_pct("Music", int(settings.get("music_volume", 60)))
	_set_bus_pct("SFX", int(settings.get("sfx_volume", 80)))
	_set_bus_pct("Commentary", int(settings.get("commentary_volume", 80)))


func _set_bus_pct(bus_name: String, pct: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped := clampi(pct, 0, 100)
	AudioServer.set_bus_mute(idx, clamped <= 0)
	if clamped > 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(float(clamped) / 100.0))


func set_ambience(mode: String) -> void:
	if not _initialized or DisplayServer.get_name() == "headless":
		_current_ambience = mode
		return
	if mode == _current_ambience:
		return
	_current_ambience = mode

	if is_instance_valid(_room_ambience) and not _room_ambience.playing and (mode == "menu" or mode == "combat"):
		_room_ambience.play()

	if mode == "combat":
		if is_instance_valid(_menu_music) and _menu_music.playing:
			_menu_music.stop()
		if is_instance_valid(_combat_music) and not _combat_music.playing:
			_combat_music.play()
		if is_instance_valid(_audience_ambience):
			_audience_ambience.volume_db = -2.2
			if not _audience_ambience.playing:
				_audience_ambience.play()
	elif mode == "menu":
		if is_instance_valid(_combat_music) and _combat_music.playing:
			_combat_music.stop()
		if is_instance_valid(_menu_music) and not _menu_music.playing:
			_menu_music.play()
		# Muffled underground crowd murmur audible behind walls in menu/hub
		if is_instance_valid(_audience_ambience):
			_audience_ambience.volume_db = -8.0
			if not _audience_ambience.playing:
				_audience_ambience.play()
	else:
		if is_instance_valid(_menu_music): _menu_music.stop()
		if is_instance_valid(_combat_music): _combat_music.stop()
		if is_instance_valid(_room_ambience): _room_ambience.stop()
		if is_instance_valid(_audience_ambience): _audience_ambience.stop()


func play_sfx(id: String, volume_db: float = -3.0, pitch_jitter: float = 0.05) -> void:
	if DisplayServer.get_name() == "headless" or _sfx_players.is_empty():
		return
	var stream: AudioStreamWAV = _samples.get(id)
	if stream == null:
		return
	var p := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	p.play()


func play_commentary_cue(volume_db: float = -6.0) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(_comm_player):
		return
	var stream: AudioStreamWAV = _samples.get("commentary_cue")
	if stream == null:
		return
	_comm_player.stream = stream
	_comm_player.volume_db = volume_db
	_comm_player.pitch_scale = _rng.randf_range(0.97, 1.04)
	_comm_player.play()


# ---------------------------------------------------------
# PROCEDURAL 16-BIT PCM SYNTHESIS (MUSIC, AMBIENCE, CROWD, SFX)
# ---------------------------------------------------------

func _build_sample_bank() -> void:
	_samples["bell_round"] = _make_bell(1.45, false)
	_samples["bell_double"] = _make_bell(1.65, true)
	_samples["punch_jab"] = _make_punch(0.16, 130.0, 52.0, 0.72)
	_samples["punch_heavy"] = _make_punch(0.28, 105.0, 34.0, 1.0)
	_samples["punch_body"] = _make_punch(0.22, 118.0, 42.0, 0.42)
	_samples["block_thud"] = _make_punch(0.16, 86.0, 46.0, 0.28)
	_samples["player_hit"] = _make_punch(0.25, 92.0, 32.0, 0.85)
	_samples["crit_ko"] = _make_crit_impact()
	_samples["whoosh_slip"] = _make_whoosh(0.19)
	_samples["clinch_tie"] = _make_whoosh(0.22, 0.55)
	_samples["crowd_cheer"] = _make_crowd_swell(1.35)
	_samples["crowd_gasp"] = _make_crowd_gasp(0.65)
	_samples["crowd_boo"] = _make_crowd_boo(1.15)
	_samples["foot_shuffle"] = _make_foot_shuffle()
	_samples["heavy_breath"] = _make_heavy_breath()
	_samples["bell_end"] = _make_bell(1.85, true)
	_samples["win_fight"] = _make_win_sting(false)
	_samples["win_champion"] = _make_win_sting(true)
	_samples["lose_ko"] = _make_lose_ko()
	_samples["item_use"] = _make_item_use()
	_samples["rest_breath"] = _make_breath()
	_samples["ui_click"] = _make_tone_click(720.0, 0.045, 0.25)
	_samples["ui_confirm"] = _make_tone_click(960.0, 0.08, 0.35)
	_samples["ui_retry"] = _make_tone_click(260.0, 0.11, 0.42)
	_samples["commentary_cue"] = _make_tone_click(590.0, 0.085, 0.30)

	# Gritty basement electrical hum + air ventilation loop
	_samples["ambience_room"] = _make_room_noise(4.0)
	# Muffled underground crowd rhubarb + distant shouts loop
	_samples["ambience_audience"] = _make_muffled_audience_loop(8.0)
	# Musical loops: dark Buckshot-style industrial bassline & minor synth motifs
	_samples["music_menu"] = _make_menu_music(8.0)
	_samples["music_combat"] = _make_combat_music(8.0)


func _pack_wav(samples_f: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var n := samples_f.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var v := clampi(int(roundf(clampf(samples_f[i], -0.98, 0.98) * 32767.0)), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	return wav


func _make_bell(duration: float, double_hit: bool) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs := [882.0, 1325.0, 1776.0, 2640.0, 3510.0]
	var weights := [0.42, 0.26, 0.18, 0.09, 0.05]
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env1 := exp(-t * 3.1) * minf(1.0, t / 0.004)
		var s := 0.0
		for k in range(freqs.size()):
			s += sin(TAU * freqs[k] * t) * weights[k] * exp(-t * (2.6 + float(k) * 1.1))
		s *= env1
		if double_hit and t >= 0.22:
			var t2 := t - 0.22
			var env2 := exp(-t2 * 3.2) * minf(1.0, t2 / 0.004)
			var s2 := 0.0
			for k in range(freqs.size()):
				s2 += sin(TAU * freqs[k] * t2) * weights[k] * exp(-t2 * (2.6 + float(k) * 1.1))
			s += s2 * env2 * 0.85
		buf[i] = clampf(s * 0.85, -0.95, 0.95)
	return _pack_wav(buf)


func _make_punch(duration: float, f_start: float, f_end: float, snap_mix: float) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var f := lerpf(f_start, f_end, minf(1.0, t / (duration * 0.55)))
		phase += TAU * f / float(SAMPLE_RATE)
		var thump := sin(phase) * exp(-t * 16.0)
		var noise := _rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, noise, 0.22 + 0.55 * snap_mix)
		var crack := lp * exp(-t * (28.0 if snap_mix > 0.5 else 20.0)) * snap_mix
		buf[i] = clampf((thump * 0.78 + crack * 0.52), -0.95, 0.95)
	return _pack_wav(buf)


func _make_crit_impact() -> AudioStreamWAV:
	var n := int(0.45 * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var f := lerpf(150.0, 28.0, minf(1.0, t / 0.24))
		phase += TAU * f / float(SAMPLE_RATE)
		var sub := sin(phase) * exp(-t * 7.5)
		var snap := _rng.randf_range(-1.0, 1.0) * exp(-t * 30.0)
		buf[i] = clampf((sub * 0.85 + snap * 0.65), -0.95, 0.95)
	return _pack_wav(buf)


func _make_whoosh(duration: float, tone_factor: float = 0.0) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	var prev := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var u := t / duration
		var env := sin(PI * u)
		var raw := _rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, raw, 0.14 + 0.24 * env)
		var bp := lp - prev * 0.72
		prev = lp
		var rumble := sin(TAU * 95.0 * t) * 0.25 * tone_factor * env
		buf[i] = clampf(bp * env * 0.68 + rumble, -0.95, 0.95)
	return _pack_wav(buf)


func _make_crowd_swell(duration: float) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp1 := 0.0
	var lp2 := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var u := t / duration
		var env := pow(sin(PI * u), 1.15)
		var raw := _rng.randf_range(-1.0, 1.0)
		# Tight low-pass < 520 Hz for muffled underground pit cheer
		lp1 = lerpf(lp1, raw, 0.11)
		lp2 = lerpf(lp2, lp1, 0.13)
		var voice_hum := sin(TAU * 145.0 * t + sin(TAU * 4.5 * t) * 1.6) * 0.08
		buf[i] = clampf((lp2 * 0.72 + voice_hum) * env, -0.95, 0.95)
	return _pack_wav(buf, false)


func _make_crowd_gasp(duration: float) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var u := t / duration
		var env := exp(-u * 3.4) * minf(1.0, u / 0.08)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.28)
		var oh := sin(TAU * lerpf(280.0, 175.0, u) * t) * 0.14
		buf[i] = clampf((lp * 0.75 + oh) * env, -0.95, 0.95)
	return _pack_wav(buf)


func _make_crowd_boo(duration: float) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var u := t / duration
		var env := sin(PI * u)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.14)
		var groan := (sin(TAU * 112.0 * t) + sin(TAU * 124.0 * t) + sin(TAU * 141.0 * t)) * 0.11
		buf[i] = clampf((lp * 0.62 + groan) * env, -0.95, 0.95)
	return _pack_wav(buf)


func _make_foot_shuffle() -> AudioStreamWAV:
	var duration := 0.16
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := sin(PI * t / duration) * exp(-t * 10.0)
		var raw := _rng.randf_range(-1.0, 1.0)
		var hp := (raw - prev) * 0.55
		prev = raw
		buf[i] = clampf(hp * env * 0.45, -0.95, 0.95)
	return _pack_wav(buf)


func _make_heavy_breath() -> AudioStreamWAV:
	var duration := 0.52
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var u := t / duration
		var env := pow(sin(PI * u), 0.85)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.16)
		var wheeze := sin(TAU * 240.0 * t + sin(TAU * 6.0 * t)) * 0.05
		buf[i] = clampf((lp * 0.50 + wheeze) * env, -0.95, 0.95)
	return _pack_wav(buf)


func _make_item_use() -> AudioStreamWAV:
	var n := int(0.24 * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var pop := sin(TAU * lerpf(420.0, 760.0, minf(1.0, t / 0.04)) * t) * exp(-t * 36.0) * 0.55
		var raw := _rng.randf_range(-1.0, 1.0)
		var hp := (raw - prev) * 0.5
		prev = raw
		var fizz := hp * exp(-maxf(0.0, t - 0.03) * 14.0) * 0.45
		buf[i] = clampf(pop + fizz, -0.95, 0.95)
	return _pack_wav(buf)


func _make_breath() -> AudioStreamWAV:
	var n := int(0.36 * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := sin(PI * t / 0.36)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.10)
		buf[i] = lp * env * 0.38
	return _pack_wav(buf)


func _make_tone_click(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / (duration * 0.32)) * minf(1.0, t / 0.002)
		var s := sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 1.5 * t)
		buf[i] = clampf(s * env * amp, -0.95, 0.95)
	return _pack_wav(buf)


func _make_room_noise(duration: float) -> AudioStreamWAV:
	# Soft sub-bass underground room air (no 60Hz/120Hz electrical buzz)
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp1 := 0.0
	var lp2 := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var raw := _rng.randf_range(-1.0, 1.0)
		lp1 = lerpf(lp1, raw, 0.025)
		lp2 = lerpf(lp2, lp1, 0.03)
		var edge := minf(1.0, minf(t / 0.08, (duration - t) / 0.08))
		buf[i] = clampf(lp2 * 0.28 * edge, -0.95, 0.95)
	return _pack_wav(buf, true)


func _make_muffled_audience_loop(duration: float) -> AudioStreamWAV:
	# Natural muffled underground crowd cheering & arena murmur (filtered noise swells, zero sine buzz)
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp1 := 0.0
	var lp2 := 0.0
	var lp3 := 0.0
	var clap_lp := 0.0
	var cheer_peaks := [1.4, 4.1, 6.6]
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var raw := _rng.randf_range(-1.0, 1.0)
		# Multi-stage warm low-pass (< 420 Hz) for muffled behind-the-glass/focused boxer feel
		lp1 = lerpf(lp1, raw, 0.11)
		lp2 = lerpf(lp2, lp1, 0.13)
		lp3 = lerpf(lp3, lp2, 0.16)

		var swell := 0.42 + 0.14 * sin(TAU * t / duration) + 0.10 * cos(TAU * 2.0 * t / duration)
		var clap_boost := 0.0
		for pk in cheer_peaks:
			var dt := absf(t - float(pk))
			if dt < 1.15:
				var c := pow(cos((dt / 1.15) * PI * 0.5), 1.6)
				swell += c * 0.58
				clap_boost += c
		# Distant muffled claps inside cheer swells
		clap_lp = lerpf(clap_lp, _rng.randf_range(-1.0, 1.0), 0.18)
		var clap_pulse := maxf(0.0, sin(TAU * 7.5 * t + lp1 * 2.0)) * clap_boost * clap_lp * 0.26
		var edge := minf(1.0, minf(t / 0.12, (duration - t) / 0.12))
		buf[i] = clampf((lp3 * 1.45 * swell + clap_pulse) * edge, -0.95, 0.95)
	return _pack_wav(buf, true)


func _make_win_sting(champion: bool) -> AudioStreamWAV:
	var duration := 2.6 if champion else 2.0
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	# Triple bell + rising A-minor -> C-major -> E5 brassy synth fanfare
	var bell_hits := [0.0, 0.18, 0.36]
	var bell_freqs := [882.0, 1325.0, 1776.0, 2640.0]
	var chord := [220.0, 277.18, 329.63, 440.0, 554.37] if champion else [220.0, 261.63, 329.63, 440.0]
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var sig := 0.0
		for bh in bell_hits:
			if t >= float(bh):
				var tb := t - float(bh)
				var eb := exp(-tb * 3.8) * minf(1.0, tb / 0.004)
				for bf in bell_freqs:
					sig += sin(TAU * float(bf) * tb) * 0.14 * eb
		# Rising victorious chord swell after 0.12s
		if t >= 0.12:
			var tc := t - 0.12
			var ec := exp(-tc * 1.15) * minf(1.0, tc / 0.06)
			for cf in chord:
				sig += (sin(TAU * float(cf) * tc) + 0.35 * sin(TAU * float(cf) * 2.0 * tc)) * 0.15 * ec
		buf[i] = clampf(sig * 0.92, -0.95, 0.95)
	return _pack_wav(buf)


func _make_lose_ko() -> AudioStreamWAV:
	var duration := 2.25
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		# Heavy body fall thump -> falling pitch dissonant groan -> dull bell toll
		var fall_f := lerpf(115.0, 28.0, minf(1.0, t / 0.72))
		phase += TAU * fall_f / float(SAMPLE_RATE)
		var sub := sin(phase) * exp(-t * 2.0) * 0.62
		var gloom_f := lerpf(164.81, 98.0, minf(1.0, t / 1.6))
		var gloom := (sin(TAU * gloom_f * t) + 0.48 * sin(TAU * gloom_f * 1.06 * t)) * exp(-t * 1.25) * 0.34
		var dull_bell := (sin(TAU * 440.0 * t) * 0.22 + sin(TAU * 659.0 * t) * 0.12) * exp(-t * 2.5)
		var thud := _rng.randf_range(-1.0, 1.0) * exp(-t * 22.0) * 0.38
		buf[i] = clampf(sub + gloom + dull_bell + thud, -0.95, 0.95)
	return _pack_wav(buf)


func _make_menu_music(duration: float) -> AudioStreamWAV:
	# Moody dark underground boxing theme: warm sub-bass + minor electric-piano chords + soft pulse
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var bass_notes := [55.0, 55.0, 65.41, 55.0, 49.0, 49.0, 61.74, 55.0, 55.0, 55.0, 65.41, 73.42, 65.41, 55.0, 49.0, 51.91]
	var chords := [
		[220.0, 261.63, 329.63],
		[196.0, 246.94, 293.66],
		[174.61, 220.0, 261.63],
		[164.81, 207.65, 246.94]
	]
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var step_f := t / 0.5
		var step := int(step_f) % bass_notes.size()
		var lt := t - float(int(step_f)) * 0.5

		# Warm sub + octave sine bass (no harsh sawtooth buzz)
		var f_b := float(bass_notes[step])
		var env_b := exp(-lt * 3.2) * minf(1.0, lt / 0.015)
		var sig := (sin(TAU * f_b * lt) * 0.75 + sin(TAU * f_b * 2.0 * lt) * 0.25) * env_b * 0.36

		# Moody sustained minor chord pad (changes every 2.0s)
		var bar := (step / 4) % chords.size()
		var bar_t := fmod(t, 2.0)
		var pad_env := minf(1.0, bar_t / 0.12) * exp(-bar_t * 0.55)
		for cf in chords[bar]:
			sig += sin(TAU * float(cf) * t) * pad_env * 0.075

		# Soft muted heartbeat kick on even steps
		if step % 2 == 0 and lt < 0.14:
			var kf := lerpf(88.0, 36.0, lt / 0.14)
			sig += sin(TAU * kf * lt) * exp(-lt * 18.0) * 0.22

		lp = lerpf(lp, sig, 0.24)
		var edge := minf(1.0, minf(t / 0.06, (duration - t) / 0.06))
		buf[i] = clampf(lp * edge, -0.95, 0.95)
	return _pack_wav(buf, true)


func _make_combat_music(duration: float) -> AudioStreamWAV:
	# Driving moody underground fight beat (120 BPM, warm punchy sub-bass, minor riff & tight drums)
	var n := int(duration * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var bass_seq := [
		55.0, 55.0, 0.0, 55.0, 65.41, 0.0, 55.0, 49.0,
		55.0, 55.0, 0.0, 61.74, 65.41, 0.0, 73.42, 65.41,
		55.0, 55.0, 0.0, 55.0, 49.0, 0.0, 55.0, 51.91,
		55.0, 65.41, 73.42, 0.0, 65.41, 55.0, 49.0, 55.0
	]
	var lead_seq := [
		220.0, 0.0, 261.63, 0.0, 220.0, 0.0, 196.0, 0.0,
		220.0, 0.0, 293.66, 0.0, 261.63, 246.94, 220.0, 0.0,
		220.0, 0.0, 261.63, 0.0, 196.0, 0.0, 207.65, 0.0,
		220.0, 261.63, 329.63, 0.0, 293.66, 246.94, 220.0, 0.0
	]
	var lp := 0.0
	var hat_lp := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var step_f := t / 0.25
		var step := int(step_f) % bass_seq.size()
		var lt := t - float(int(step_f)) * 0.25
		var sig := 0.0

		var bf := float(bass_seq[step])
		if bf > 0.0:
			var env_b := exp(-lt * 5.2) * minf(1.0, lt / 0.008)
			sig += (sin(TAU * bf * lt) * 0.78 + sin(TAU * bf * 2.0 * lt) * 0.28) * env_b * 0.34

		var lf := float(lead_seq[step])
		if lf > 0.0:
			sig += (sin(TAU * lf * lt) + 0.25 * sin(TAU * lf * 2.0 * lt)) * exp(-lt * 6.5) * 0.09

		var bar_step := step % 4
		if bar_step == 0 and lt < 0.14:
			var kf := lerpf(110.0, 36.0, lt / 0.14)
			sig += sin(TAU * kf * lt) * exp(-lt * 19.0) * 0.36
		elif bar_step == 2 and lt < 0.10:
			var nse := _rng.randf_range(-1.0, 1.0)
			hat_lp = lerpf(hat_lp, nse, 0.35)
			sig += (hat_lp * 0.32 + sin(TAU * 175.0 * lt) * 0.40) * exp(-lt * 25.0) * 0.22
		elif bar_step % 2 == 1 and lt < 0.04:
			hat_lp = lerpf(hat_lp, _rng.randf_range(-1.0, 1.0), 0.3)
			sig += hat_lp * exp(-lt * 60.0) * 0.05

		lp = lerpf(lp, sig, 0.32)
		var edge := minf(1.0, minf(t / 0.05, (duration - t) / 0.05))
		buf[i] = clampf(lp * edge, -0.95, 0.95)
	return _pack_wav(buf, true)
