@tool
extends Node3D


func attach_part(part_index : int, port_index : int) -> void:
	var inst = AirductGizmoPlugin.get_airduct_segment(part_index)
	add_sibling(inst)
	inst.owner = get_tree().edited_scene_root
