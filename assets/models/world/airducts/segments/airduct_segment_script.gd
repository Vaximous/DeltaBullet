@tool
extends MeshInstance3D


@export var segment_name : String
@export var segment_index : int

##When instanced, this port is assigned to the parent automatically. Only really used on 4-way and tri-split.
@export var parent_connection_port : int = -1

@export_storage var connections : Array = []


func _ready() -> void:
	connections.resize(get_airduct_attachment_points().size())


func get_airduct_attachment_points() -> Array[Transform3D]:
	var tf : Array[Transform3D] = []
	for child in get_children():
		if child is Node3D:
			if not child is VisualInstance3D:
				tf.append(child.transform)
	return tf


func attach_part(part_index : int, port_index : int) -> void:
	if connections[port_index] != null:
		printerr("Port %s is in use by %s!" % [port_index, connections[port_index]])
		return
	var inst = AirductGizmoPlugin.get_airduct_segment(part_index)
	inst.tree_exited.connect(open_port.bind(port_index))
	add_child(inst)

	inst.set_owner(get_tree().get_edited_scene_root())
	inst.transform = get_airduct_attachment_points()[port_index]
	inst.global_rotation.y += PI

	#Automatically connect this port.
	if inst.parent_connection_port > -1:
		inst.connections[inst.parent_connection_port] = self

	print("Created instance at port %s. Transform: %s" % [port_index, inst.global_transform])
	connections[port_index] = inst


func open_port(port_index : int) -> void:
	if is_instance_valid(connections[port_index]):
		connections[port_index].queue_free()
	connections[port_index] = null
	print("Opened port %d" % port_index)
