@tool
extends MeshInstance3D


@export_tool_button("Extend Above") var tb_extend_above = extend_above
@export_enum("16 bricks", "8 bricks", "4 bricks", "2 bricks") var size : int = 1:
	set(value):
		var models = [
			load("res://assets/models/world/brickedgeflourishes/brickedgeflourishes_brickedgeflourish16.res"),
			load("res://assets/models/world/brickedgeflourishes/brickedgeflourishes_brickedgeflourish8.res"),
			load("res://assets/models/world/brickedgeflourishes/brickedgeflourishes_brickedgeflourish4.res"),
			load("res://assets/models/world/brickedgeflourishes/brickedgeflourishes_brickedgeflourish2.res")
		]
		mesh = models[value]


func extend_above() -> void:
	if owner == null:
		return
	if get_child(0) is MeshInstance3D:
		return
	var new = load("res://assets/models/world/brickedgeflourishes/BrickEdgeDetail.tscn").instantiate()
	print(new)
	add_child(new)
	if Engine.is_editor_hint():
		new.set_owner(owner)
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(new)
	print(get_aabb())
	new.position.y = get_aabb().size.y
