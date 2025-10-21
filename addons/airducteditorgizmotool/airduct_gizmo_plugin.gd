class_name AirductGizmoPlugin
extends EditorNode3DGizmoPlugin

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
	TSplit,
}

const airduct_segments: Array[String] = [
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


#endregion
#region Duct Stuff
static func create_popup_panel(selected_part_name : String) -> Window:
	var popup : PanelContainer = load("res://addons/airducteditorgizmotool/AirductOptionPopupPanel.tscn").instantiate()
	popup.setup_available_parts(selected_part_name)
	var window := Window.new()
	window.add_child(popup)
	EditorInterface.popup_dialog(window, Rect2i(DisplayServer.mouse_get_position(), popup.size))
	window.set_deferred(&"min_size", popup.size)
	window.reset_size.call_deferred()
	window.close_requested.connect(window.queue_free)
	popup.tree_exited.connect(window.queue_free)
	popup.part_selected.connect(window.queue_free.unbind(1))
	return window


static func get_segment_by_name(name: String) -> MeshInstance3D:
	var k = Segments.find_key(name)
	if k is int:
		return get_airduct_segment(k)
	return null


static func get_airduct_segment(index: int) -> MeshInstance3D:
	var path = airduct_segments[index]
	var scn = load(path)
	if scn is PackedScene:
		return scn.instantiate()
	return null
#endregion

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
	var duct = gizmo.get_node_3d()
	duct.check_open_ports()
	var panel = create_popup_panel(duct.segment_name).get_child(0)
	panel.part_selected.connect(_on_panel_selected_part.bind(handle_id, duct))


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


func _on_panel_selected_part(part_name : String, port : int, duct : Node3D) -> void:
	duct.check_open_ports()
	print(part_name, port, duct, Segments)
	var new_duct = Segments[part_name]
	duct.attach_part(new_duct, port)
	return
