extends Node


var saved_times : Dictionary


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func fade_all_audioplayers_out(fade_time : float = 2.0) -> void:
	for t in get_all_audioplayers():
		fade_audioplayer_out_and_free(t.name, fade_time)


func instance_new_audioplayer(channel : StringName = &"Music", stream : AudioStream = null) -> AudioStreamPlayer:
	var new_audio_stream_player = AudioStreamPlayer.new()
	new_audio_stream_player.name = channel
	add_child(new_audio_stream_player)
	new_audio_stream_player.set_meta(&"channel_track", true)
	new_audio_stream_player.volume_db = -80
	if stream != null:
		new_audio_stream_player.stream = stream
		new_audio_stream_player.bus = channel
	return new_audio_stream_player


func set_channel_pause(channel : String = "Music", paused : bool = false) -> void:
	var existing = get_node_or_null(channel)
	if existing != null:
		existing.stream_paused = paused


func save_stream_time(channel : String = "Music") -> void:
	var ch = get_audioplayer(channel)
	if ch != null:
		if ch.stream != null:
			saved_times[ch.stream] = [ch.get_playback_position(), Time.get_ticks_msec()]


func create_audioplayer_with_stream(stream : AudioStream, fade_time : float = 2.0, channel : StringName = &"Music", volume_db : float = 0.0, continue_from_stored : bool = true):
	fade_time = max(fade_time, 0.05)
	var existing = get_node_or_null(String(channel))
	if existing != null:
		if existing.stream == stream:
			#Don't do it if the stream is already the same stream
			return
		save_stream_time(existing.name)
		fade_audioplayer_out_and_free(existing.name, fade_time)
	var new_pl = instance_new_audioplayer(channel, stream)
	fade_audioplayer_in(new_pl.name, fade_time, volume_db)
	if stream == null:
		return
	if saved_times.has(stream) and continue_from_stored:
		new_pl.seek(saved_times[stream][0] + ((Time.get_ticks_msec() - saved_times[stream][1]) / 1000.0))
		saved_times.erase(stream)


func fade_audioplayer_in(channel_name : String, fade_time : float, volume_db : float = 0.0) -> void:
	var channel = get_node_or_null(channel_name)
	if channel == null:
		return
	print("Fading %s in" % channel_name	)
	channel.volume_db = -80
	if !channel.playing:
		channel.playing = true
	if fade_time > 0:
		var fade_fraction = 0.0
		while fade_fraction < 1.0 or channel.volume_db < volume_db:
			if is_instance_valid(channel):
				if channel.has_meta(&"fading_out"):
					return
				channel.volume_db = linear_to_db(lerp(0.0, db_to_linear(volume_db), fade_fraction))
				fade_fraction += get_process_delta_time() / fade_time
				await get_tree().process_frame
			else:
				return
	channel.volume_db = volume_db


func fade_audioplayer_out_and_free(channel_name : String, fade_time : float) -> void:
	var channel = get_node_or_null(channel_name)
	if channel == null:
		return
	if channel.has_meta(&"fading_out"):
		channel.set_meta(&"fade_time", fade_time)
		return
	channel.name += "_fading%s"%randi()
	channel.set_meta(&"fading_out", true)
	channel.set_meta(&"fade_time", fade_time)
	if fade_time > 0:
		while channel.volume_db > -80.0:
			var new_volume = linear_to_db(db_to_linear(channel.volume_db)-(get_process_delta_time()/channel.get_meta(&"fade_time", 1.0)))
			if is_nan(new_volume):
				break
			channel.volume_db = new_volume
			await get_tree().process_frame
	channel.queue_free()


func get_audioplayer(channel : String) -> AudioStreamPlayer:
	return get_node_or_null(channel)


func has_audioplayer(channel : String) -> bool:
	return has_node(channel)


func get_all_audioplayers() -> Array[AudioStreamPlayer]:
	var valid : Array[AudioStreamPlayer] = []
	for c in get_children():
		if c.has_meta(&"channel_track"):
			valid.append(c)
	return valid


func get_all_channels() -> PackedStringArray:
	var names : PackedStringArray = []
	for n in get_children():
		if n is AudioStreamPlayer:
			names.append(n.name)
	return names


func play_sound(soundfile : String, volume_db : float = 0.0, pitch_scale : float = 1.0,bus:StringName = &"Sounds") -> void:
	var audioplayer := AudioStreamPlayer.new()
	audioplayer.bus = bus
	var stream = load(soundfile)
	audioplayer.stream = stream
	audioplayer.process_mode = Node.PROCESS_MODE_ALWAYS
	audioplayer.finished.connect(audioplayer.queue_free)
	audioplayer.volume_db = volume_db
	audioplayer.pitch_scale = pitch_scale
	get_tree().current_scene.add_child(audioplayer)
	audioplayer.play()


func play_sound_positioned(soundfile : String, position : Vector3, volume_db : float = 0.0, pitch_scale : float = 1.0, bus:StringName = &"Sounds", parent : Node = null) -> void:
	var audioplayer := AudioStreamPlayer3D.new()
	audioplayer.bus = bus
	var stream = load(soundfile)
	audioplayer.stream = stream
	audioplayer.finished.connect(audioplayer.queue_free)
	audioplayer.volume_db = volume_db
	audioplayer.pitch_scale = pitch_scale
	if parent != null:
		parent.add_child(audioplayer)
	else:
		get_tree().current_scene.add_child(audioplayer)
	audioplayer.play()
	audioplayer.position = position


#Function exists so we don't have to replace all instances of change_song_to
func change_song_to(stream : AudioStream, fade_time : float = 1.0) -> void:
	create_audioplayer_with_stream(stream, fade_time)
