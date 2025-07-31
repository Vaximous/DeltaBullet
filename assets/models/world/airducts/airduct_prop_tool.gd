@tool
extends Node3D


func attach_part(duct: MeshInstance3D, connection_index: int, part : ArrayMesh) -> void:
	var new_mi3d := MeshInstance3D.new()
	if not part.has_meta(&"_airvent_mesh"):
		return
	duct.add_child(new_mi3d)
	new_mi3d.mesh = load()
	return
