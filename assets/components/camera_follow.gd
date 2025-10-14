extends Node3D


##set to 0 to disable an axis, set to 1 to follow an axis
@export var scale_factor : Vector3 = Vector3.ONE


func _process(delta: float) -> void:
	var cam : Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		global_position = cam.global_position * scale_factor
