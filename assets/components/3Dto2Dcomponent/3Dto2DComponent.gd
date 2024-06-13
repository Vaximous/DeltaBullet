extends Marker3D


static var control_nodes : Array[Control]


@export_subgroup("Behavior")
@export var clamp_to_edge : bool = true


func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _physics_process(delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam is Camera3D:
		var unprojected_position = cam.unproject_position(global_position)
		for n in get_children():
			n.global_position = unprojected_position
			n.visible = !cam.is_position_behind(global_position)
			if clamp_to_edge:
				clamp_to_screen(n)


func clamp_to_screen(item : Control) -> void:
	var view_rect : Rect2 = get_viewport().get_visible_rect()
	item.global_position = item.global_position.clamp(Vector2.ZERO, view_rect.size - (item.size * item.scale))


func _on_child_entered_tree(node: Node) -> void:
	if !control_nodes.has(node):
		if node is Control:
			control_nodes.append(node)


func _on_child_exiting_tree(node: Node) -> void:
	if control_nodes.has(node):
		control_nodes.erase(node)
