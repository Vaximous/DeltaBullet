extends Marker3D


var control_nodes : Array[Control]


@export_subgroup("Behavior")
@export var clamp_to_edge : bool = true


func _ready() -> void:
	assign_control_children()


func _process(_delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam is Camera3D:
		var unprojected_position = cam.unproject_position(global_position)
		for n in control_nodes:
			n.global_position = unprojected_position
			n.visible = !cam.is_position_behind(global_position)
			if clamp_to_edge:
				clamp_to_screen(n)


func clamp_to_screen(item : Control) -> void:
	var view_rect : Rect2 = get_viewport().get_visible_rect()
	item.global_position = item.global_position.clamp(Vector2.ZERO, view_rect.size - (item.size * item.scale))


func assign_control_children() -> void:
	control_nodes.assign(get_children())
