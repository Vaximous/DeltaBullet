extends CanvasLayer

const TOOL_SELECT: int = 0
const TOOL_TRANSLATE: int = 1
const TOOL_ROTATE: int = 2
const TOOL_PLACE: int = 3
const TOOL_DELETE: int = 4
const HISTORY_LIMIT : int = 30
const EditorInstancedNodeGroup := &"SafehoueEditorInstances"

@export_enum("Select", "Translate", "Rotate", "Place") var selectedTool = 0

var selectedMaterial = preload("res://assets/materials/editor/editorSelected.tres")
var autoselectAfterPlace: bool = true
var placedItems: Array
var leaving: bool = false
var selectedObject: Node3D
var selectedItem: PackedScene:
	set(value):
		selectedItem = value
		if is_instance_valid(selectedItem):
			for i in get_children():
				if i.is_in_group(&"itemGhost"):
					i.queue_free()
			itemGhost = selectedItem.instantiate()
			itemGhost.add_to_group(&"itemGhost")
			add_child(itemGhost)
			gameManager.activeCamera.editorCast.add_exception(itemGhost)
			itemGhost.global_position = gameManager.activeCamera.editorCast.get_collision_point()
var itemGhost: Node3D
var itemButton = preload("res://assets/scenes/ui/safehouseEditor/editorItem.tscn")
##for the Undo system
var editUndo: Array[SafehouseEditState]
var editRedo: Array[SafehouseEditState]
var instanced_nodes: Array[Node]

@onready var itemContainer = %itemContainer


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("gRightClick"):
		if !gameManager.isMouseHidden() and !leaving:
			gameManager.hideMouse()
	elif !leaving:
		gameManager.showMouse()

	if is_instance_valid(itemGhost) and selectedTool == 3 and !leaving:
		if itemGhost is RigidBody3D:
			itemGhost.freeze = true
			itemGhost.collision_layer = 0
			itemGhost.collision_mask = 0

		if !Input.is_action_pressed("gRightClick"):
			if get_from_mouse().has("position"):
				itemGhost.global_position = lerp(itemGhost.global_position, get_from_mouse()["position"], 18 * delta)
				itemGhost.show()
			else:
				itemGhost.hide()
		else:
			itemGhost.hide()
	else:
		if is_instance_valid(itemGhost):
			itemGhost.hide()


func _unhandled_input(event: InputEvent) -> void:
	if !leaving:
		if event.is_action_pressed("gLeftClick"):

			if %gizmo3d.hovering || %gizmo3d.editing:
				return

			if selectedTool == TOOL_SELECT:
				if get_from_mouse().has("collider"):
					if get_from_mouse()["collider"].get_meta(&"canBeSelected"):
						setSelectedObject(get_from_mouse()["collider"])
						%gizmo3d.mode = 0
					else:
						deselectObject()

			if selectedTool == TOOL_TRANSLATE:
				if get_from_mouse().has("collider"):
					if get_from_mouse()["collider"].get_meta(&"canBeSelected"):
						setSelectedObject(get_from_mouse()["collider"])
						%gizmo3d.mode = 1
					else:
						deselectObject()

			if selectedTool == TOOL_ROTATE:
				if get_from_mouse().has("collider"):
					if get_from_mouse()["collider"].get_meta(&"canBeSelected"):
						setSelectedObject(get_from_mouse()["collider"])
						%gizmo3d.mode = 2
					else:
						deselectObject()

			if selectedTool == TOOL_PLACE:
				if is_instance_valid(selectedItem) and get_from_mouse().has("position"):
					placeItem(get_from_mouse()["position"])

		if event.is_action_pressed("gEditorDelete"):
			if is_instance_valid(selectedObject):
				%gizmo3d.clear_selection()
				deleteItem(selectedObject)

		if event.is_action_pressed("gEscape"):
			deselectObject()
			leaving = true
			gameManager.removeSafehouseEditor()
			await get_tree().process_frame
			gameManager.pauseMenu.canPause = true
			gameManager.hideMouse()


func get_from_mouse() -> Dictionary:
	var RAY_LENGTH = 1000
	var space_state = gameManager.world.worldMisc.get_world_3d().direct_space_state
	var cam = gameManager.activeCamera.camera
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false

	var result = space_state.intersect_ray(query)
	return result


func setTool(value: int) -> void:
	#if value != selectedTool:
		#addActionToUndoList("Change Tool")
	selectedTool = value
	%gizmo3d.mode = value


func createItemButtons() -> void:
	for placeable in gameManager.purchasedPlacables:
		var inst = itemButton.instantiate()
		itemContainer.add_child(inst)
		inst.placeableObject = placeable
		inst.button.pressed.connect(setSelectedItem.bind(inst.placeableObject))


func clearItemPanel() -> void:
	for i in %itemContainer.get_children():
		i.queue_free()


func deselectObject() -> void:
	if is_instance_valid(selectedObject):
		for i in selectedObject.get_children():
			if i is MeshInstance3D:
				i.material_override = null
				for ichild in i.get_children():
					if ichild is MeshInstance3D:
						ichild.material_override = null
	%gizmo3d.clear_selection()
	selectedObject = null


func setSelectedItem(item: PackedScene) -> void:
	selectedItem = item
	selectedTool = 3


func initEditor() -> void:
	clearItemPanel()
	createItemButtons()
	#gameManager.showMouse()
	gameManager.activeCamera.unposessObject(true)


func clearOrphanedAndExpiredNodes() -> void:
	#Clear nodes that are instanced, but not tracked by any history.
	var tracked : Array[Node]
	for i in editRedo:
		tracked.append_array(i.tracked_items.keys())
	for i in editUndo:
		tracked.append_array(i.tracked_items.keys())
	var erase_list : Array
	for i in instanced_nodes:
		if not is_instance_valid(i):
			erase_list.append(i)
			continue
		if not i in tracked and not i.is_inside_tree():
			i.queue_free()
			erase_list.append(i)
	for i in erase_list:
		if instanced_nodes.has(i):
			instanced_nodes.erase(i)


func addActionToUndoList(action_description: String) -> SafehouseEditState:
	var state = SafehouseEditState.new(self, action_description, get_tree().get_nodes_in_group(EditorInstancedNodeGroup))
	editUndo.append(state)
	#Clear the redo list, since it no longer applies.
	editRedo.clear()
	while editUndo.size() > HISTORY_LIMIT:
		editUndo.pop_front()
	clearOrphanedAndExpiredNodes()
	refreshUndoRedoHistoryContainer()
	return state


func refreshUndoRedoHistoryContainer() -> void:
	Util.queueFreeNodeChildren(%HistoryContainer)

	var title : Label = Label.new()
	title.text = "Undo"
	if not editUndo.is_empty():
		%HistoryContainer.add_child(title)
		%HistoryContainer.add_child(HSeparator.new())

	for i in editUndo:
		#TODO : make this a button that you can press
		var label : Label = Label.new()
		label.text = i.action_description
		%HistoryContainer.add_child(label)

	title = Label.new()
	title.text = "Redo"
	if not editRedo.is_empty():
		%HistoryContainer.add_child(title)
		%HistoryContainer.add_child(HSeparator.new())

	for i in editRedo:
		#TODO : make this a button that you can press
		var label : Label = Label.new()
		label.text = i.action_description
		%HistoryContainer.add_child(label)

	%HistoryContainerPanel.visible = %HistoryContainer.get_child_count() != 0


func undoChange() -> void:
	#Remove from editUndo list and add to editRedo list
	var revert = editUndo.pop_back()
	if revert == null:
		return
	editRedo.append(revert)
	revert.revert()
	refreshUndoRedoHistoryContainer()


func redoChange() -> void:
	#Remove from editRedo list and add to editUndo list
	var revert = editRedo.pop_back()
	if revert == null:
		return
	editUndo.append(revert)
	revert.revert()
	refreshUndoRedoHistoryContainer()


func deleteItem(item : Node) -> void:
	%gizmo3d.clear_selection()
	if selectedItem == item:
		selectedItem = null

	addActionToUndoList("Delete Item")
	#don't queue free from memory cause of undo/redo system
	Util.removeNodeFromTree(item)
	return


func setSelectedObject(object: Node3D) -> void:
	deselectObject()
	selectedObject = object
	if selectedTool == TOOL_DELETE:
		deleteItem(object)
	%gizmo3d.select(selectedObject)
	for i in object.get_children():
		if i is MeshInstance3D:
			i.material_override = selectedMaterial
			for ichild in i.get_children():
				if ichild is MeshInstance3D:
					ichild.material_override = selectedMaterial

	#if event.is_action_pressed("gEditorMouseToggle"):
		#if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			#gameManager.showMouse()
		#else:
			#gameManager.hideMouse()


func placeItem(gPosition: Vector3) -> void:
	var inst = selectedItem.instantiate()
	addActionToUndoList("Place '%s'" % inst.name)
	gameManager.world.worldProps.add_child(inst)
	inst.global_position = gPosition
	inst.set_meta(&"canBeSelected", true)
	inst.add_to_group(EditorInstancedNodeGroup)
	instanced_nodes.append(inst)
	if autoselectAfterPlace:
		setSelectedObject(inst)


class SafehouseEditState extends RefCounted:
	##BEFORE you commit an action, write state
	var editor: Node
	var action_description: String
	var pre_action: Dictionary[Node, Dictionary]
	var post_action: Dictionary[Node, Dictionary]
	var tool_state: Dictionary


	func _init(_editor: Node, a_d: String, nodes: Array[Node]) -> void:
		editor = _editor

		action_description = a_d

		tool_state = {
			"selectedTool": editor.selectedTool,
		}

		for n in nodes:
			var prop_dict := {}
			if n is Node3D:
				prop_dict["global_transform"] = n.global_transform
			pre_action[n] = prop_dict
		return


	func undo() -> void:
		editor.setTool(tool_state.get("selectedTool", 0))

		for node: Node in editor.instanced_nodes:
			#Node is tracked
			if node in pre_action:
				if not node.is_inside_tree():
					print("Undo- Adding node %s, since it is tracked." % node)
					gameManager.world.worldProps.add_child(node)
				assert(is_instance_valid(node), "Tracked node is invalid, when it should never be.")
				var prop_dict: Dictionary = pre_action.get(node, {})
				for key in prop_dict.keys():
					node[key] = prop_dict[key]
			#Node isn't tracked, meaning it shouldn't exist right now.
			else:
				if node.is_inside_tree():
					print("Undo- Removing node %s, since it isn't tracked." % node)
					node.get_parent().remove_child(node)

	func redo() -> void:
		for node: Node in editor.instanced_nodes:
			#Node is tracked
			if node in post_action:
				if not node.is_inside_tree():
					print("Redo- Adding node %s, since it is tracked." % node)
					gameManager.world.worldProps.add_child(node)
				assert(is_instance_valid(node), "Tracked node is invalid, when it should never be.")
				var prop_dict: Dictionary = post_action.get(node, {})
				for key in prop_dict.keys():
					node[key] = prop_dict[key]
			#Node isn't tracked, meaning it shouldn't exist right now.
			else:
				if node.is_inside_tree():
					print("Redo- Removing node %s, since it isn't tracked." % node)
					node.get_parent().remove_child(node)

#class SafehouseEditState extends RefCounted:
	###Describe what you did- ie "rotated Chair"
	#var action_description: String
	###The item being changed
	#var item: Object
	###The state the item should revert to when undoing
	#var revert_state: Dictionary
#
#
	#func _init(action: String, _item: Object, parameters: PackedStringArray) -> void:
		#action_description = action
		#item = _item
		#for p in parameters:
			#if p in item:
				#revert_state[p] = item.get(p)
#
#
	#func revert() -> void:
		#for key in revert_state.keys():
			#item.set(key, revert_state[key])
