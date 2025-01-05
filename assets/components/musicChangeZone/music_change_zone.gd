extends Area3D


@export var area_music : AudioStream
@export var fade_time : float = 3.0
@export var switch_back_on_exit : bool = false
var song_on_enter : AudioStream

func _on_body_entered(body: Node3D) -> void:
	if body is Player3D:
		var music = AudioManager.get_audioplayer("music")
		if music != null:
			song_on_enter = music.stream
		AudioManager.save_stream_time()
		AudioManager.create_audioplayer_with_stream(area_music, fade_time)
	pass # Replace with function body.


func _on_body_exited(body: Node3D) -> void:
	if switch_back_on_exit:
		if body is Player3D:
			AudioManager.create_audioplayer_with_stream(song_on_enter, fade_time)
	pass # Replace with function body.
