@tool
extends Node3D

const M_TOP_CURVED = preload("res://assets/models/world/ladder/ladder-parts_top-curved.res")
const M_TOP_HALF = preload("res://assets/models/world/ladder/ladder-parts_top-half.res")
const M_BOTTOM = preload("res://assets/models/world/ladder/ladder-parts_bottom.res")
const M_RUNG = preload("res://assets/models/world/ladder/ladder-parts_rung.res")
const M_CONNECTOR = preload("res://assets/models/world/ladder/ladder-parts_wall-connection.res")
const RUNG_OFFSET: float = 0.41339999999999993

@export_enum("None", "Curved", "Half") var top_rung: int = 0:
	set(value):
		top_rung = value
		create_ladder()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)
@export var bottom_rung: bool = false:
	set(value):
		bottom_rung = value
		create_ladder()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)
@export_range(0, 100, 1) var rung_count: int = 0:
	set(value):
		rung_count = value
		create_ladder()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)
@export_range(1, 100, 1) var connector_interval: int = 2:
	set(value):
		connector_interval = value
		create_ladder()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)
@export_range(0, 100, 1) var connector_offset: int = 0:
	set(value):
		connector_offset = value
		create_ladder()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)


func _ready() -> void:
	if Engine.is_editor_hint():
		create_ladder()


func create_ladder() -> void:
	for child in get_children(true):
		if child.has_meta("generated"):
			child.queue_free()

	if Engine.is_editor_hint():
		if get_tree().edited_scene_root == self:
			return

	var rung_position: float = 0.0

	#Create bottom most rung
	if bottom_rung:
		var bottom := create_mesh_instance(M_BOTTOM)
		bottom.name = "Bottom"
		bottom.position.y = rung_position
		rung_position += RUNG_OFFSET

	#Create rungs
	for i in rung_count:
		var new_rung := create_mesh_instance(M_RUNG)
		new_rung.position.y = rung_position
		new_rung.name = "Rung%d" % i
		#Connectors at every interval
		if i % connector_interval == (connector_offset % connector_interval):
			var new_connector := create_mesh_instance(M_CONNECTOR)
			new_connector.reparent(new_rung)
			new_connector.position = Vector3.ZERO
			new_connector.name = "Connector%d" % i
		rung_position += RUNG_OFFSET

	#Top rung
	match top_rung:
		0: #None
			pass
		1: #Curved
			var top := create_mesh_instance(M_TOP_CURVED)
			top.position.y = rung_position
			top.name = "Top"
		2: #Half
			var top := create_mesh_instance(M_TOP_HALF)
			top.position.y = rung_position
			top.name = "Top"


func create_mesh_instance(mesh: ArrayMesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	add_child(m, false, InternalMode.INTERNAL_MODE_FRONT)
	if Engine.is_editor_hint():
		m.set_owner(get_tree().edited_scene_root)
	m.set_meta("generated", true)
	return m
