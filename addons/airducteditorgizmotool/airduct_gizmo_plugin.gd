extends EditorNode3DGizmoPlugin


func _init() -> void:
	create_material("main", Color.RED)
	create_handle_material("handles")


func _get_gizmo_name() -> String:
	return "AirductHandle"


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var node3d := gizmo.get_node_3d()
	var handles := PackedVector3Array()

	if node3d.mesh != null:
		for attach_pt in node3d.mesh.get_meta(&"attach_points", []):
			handles.push_back(attach_pt.origin)

	gizmo.add_handles(handles, get_material(&"handles", gizmo), [])


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is MeshInstance3D
