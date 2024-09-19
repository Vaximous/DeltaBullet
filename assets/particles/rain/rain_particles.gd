extends GPUParticles3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_inside_tree():
		if Engine.get_frames_drawn() % 5 == 0:
			var cam = get_tree().root.get_camera_3d()
			if cam != null:
				global_position = cam.global_position
