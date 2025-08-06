extends EditorNode3DGizmoPlugin
class_name AirductGizmoPlugin


const airduct_segments : Array[String] = [
	"res://assets/models/world/airducts/segments/AirDuct4WaySplit.tscn",
	"res://assets/models/world/airducts/segments/AirDuct45BendLeft.tscn",
	"res://assets/models/world/airducts/segments/AirDuct45BendRight.tscn",
	"res://assets/models/world/airducts/segments/AirductConnector.tscn",
	"res://assets/models/world/airducts/segments/AirDuctLong.tscn",
	"res://assets/models/world/airducts/segments/AirDuctSharpBendLeft.tscn",
	"res://assets/models/world/airducts/segments/AirDuctSharpBendRight.tscn",
	"res://assets/models/world/airducts/segments/AirDuctSingle.tscn",
	"res://assets/models/world/airducts/segments/AirDuctSingleHoleDown.tscn",
	"res://assets/models/world/airducts/segments/AirDuctSingleHoleLeft.tscn",
	"res://assets/models/world/airducts/segments/AirDuctSingleHoleRight.tscn",
	"res://assets/models/world/airducts/segments/AirDuctTSplit.tscn"
]

enum Segments {
	OmniSplit,
	Left45,
	Right45,
	DuctConnector,
	LongAirduct,
	Left90,
	Right90,
	Single,
	VentDown,
	VentLeft,
	VentRight,
	TSplit
}


#region Gizmo / Editor Stuff


func _init() -> void:
	create_material("main", Color.RED)
	create_handle_material("handles")


func _get_gizmo_name() -> String:
	return "AirductHandle"


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	return "Duct Connection ( %d ) " % handle_id


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	return 0


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	print(gizmo)
	print(handle_id)
	print(secondary)
	print(restore)
	print(cancel)
	var duct = gizmo.get_node_3d()
	duct.attach_part([0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11].pick_random(), handle_id)


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var node3d := gizmo.get_node_3d()
	var handles := PackedVector3Array()

	for attach_pt in node3d.get_airduct_attachment_points():
		handles.push_back(attach_pt.origin)

	if handles.size() > 0:
		gizmo.add_handles(handles, get_material(&"handles", gizmo), [])


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is MeshInstance3D and for_node_3d.has_method(&"get_airduct_attachment_points")


#endregion
#region Duct Stuff


static func get_segment_by_name(name : String) -> MeshInstance3D:
	var k = Segments.find_key(name)
	if k is int:
		return get_airduct_segment(k)
	return null



static func get_airduct_segment(index : int) -> MeshInstance3D:
	var path = airduct_segments[index]
	var scn = load(path)
	if scn is PackedScene:
		return scn.instantiate()
	return null


#endregion
