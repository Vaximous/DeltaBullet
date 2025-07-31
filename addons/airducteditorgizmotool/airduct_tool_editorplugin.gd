@tool
extends EditorPlugin


const AirductGizmoPlugin = preload("airduct_gizmo_plugin.gd")
var gizmo_plugin = AirductGizmoPlugin.new()


func _enter_tree() -> void:
	add_node_3d_gizmo_plugin(gizmo_plugin)


func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
