@tool
extends Node3D

const M_StairSharp := preload("res://assets/models/interior/interior-set/big-interior-set_StaircaseSharpSingleStepMesh.res")
const M_StairRounded := preload("res://assets/models/interior/interior-set/big-interior-set_StaircaseSingleStepMesh.res")
const CS_StairStep := preload("res://assets/models/world/staircase/staircase_collision_shape.tres")

const STEP_OFFSET: Vector3 = Vector3(0.0, 0.158531, 0.191295)

@export_enum("Sharp", "Rounded") var step_type: int = 1:
	set(value):
		step_type = value
		create_staircase()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)

@export_range(1, 300, 1.0) var step_count: int = 0:
	set(value):
		step_count = value
		create_staircase()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)

@export var step_material_override: Material:
	set(value):
		step_material_override = value
		create_staircase()
		if Engine.is_editor_hint():
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(self)


func _ready() -> void:
	if Engine.is_editor_hint():
		create_staircase()


func create_staircase() -> void:
	for child in get_children(true):
		if child.has_meta("generated"):
			child.queue_free()

	if Engine.is_editor_hint():
		if get_tree().edited_scene_root == self:
			return

	var last_step: MeshInstance3D = null

	var staticbody : StaticBody3D = StaticBody3D.new()
	add_child(staticbody, false, Node.INTERNAL_MODE_FRONT)
	if Engine.is_editor_hint():
		staticbody.set_owner(get_tree().edited_scene_root)
	staticbody.set_meta("generated", true)
	staticbody.collision_mask = 0
	staticbody.name = "StaticBody3D"

	for i in step_count:
		var mi3d = create_mesh_instance(
			[M_StairSharp, M_StairRounded][step_type]
		)
		if last_step != null:
			mi3d.reparent(last_step)
			mi3d.position = STEP_OFFSET
		last_step = mi3d
		mi3d.name = "Step%d" % i

		var collider := CollisionShape3D.new()
		staticbody.add_child(collider, false, Node.INTERNAL_MODE_FRONT)
		collider.set_owner(get_tree().edited_scene_root)
		collider.global_position = mi3d.global_position
		collider.shape = CS_StairStep
		collider.name = "StepCollider%d" % i


func create_mesh_instance(mesh: ArrayMesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	add_child(m, false, Node.INTERNAL_MODE_FRONT)
	if Engine.is_editor_hint():
		m.set_owner(get_tree().edited_scene_root)
	m.material_override = step_material_override
	m.set_meta("generated", true)
	return m
