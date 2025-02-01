extends CanvasLayer
var selectedMaterial = preload("res://assets/materials/editor/editorSelected.tres")
var autoselectAfterPlace:bool = true
@onready var itemContainer = %itemContainer
var placedItems : Array
var leaving : bool = false
@export_enum("Select","Translate","Rotate","Place") var selectedTool = 0
var selectedObject : Node3D
var selectedItem : PackedScene:
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
var itemGhost : Node3D
var itemButton = preload("res://assets/scenes/ui/safehouseEditor/editorItem.tscn")

func get_from_mouse()->Dictionary:
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
				itemGhost.global_position = lerp(itemGhost.global_position,get_from_mouse()["position"],18*delta)
				itemGhost.show()
			else:
				itemGhost.hide()
		else:
			itemGhost.hide()
	else:
		if is_instance_valid(itemGhost):
			itemGhost.hide()


func setTool(value:int)->void:
	selectedTool = value

func createItemButtons()->void:
	for placeable in gameManager.purchasedPlacables:
		var inst = itemButton.instantiate()
		itemContainer.add_child(inst)
		inst.placeableObject = placeable
		inst.button.pressed.connect(setSelectedItem.bind(inst.placeableObject))

func clearItemPanel()->void:
	for i in %itemContainer.get_children():
		i.queue_free()

func deselectObject()->void:
	if is_instance_valid(selectedObject):
		for i in selectedObject.get_children():
			if i is MeshInstance3D:
				i.material_override = null
				for ichild in i.get_children():
					if ichild is MeshInstance3D:
						ichild.material_override = null
	selectedObject = null

func setSelectedItem(item:PackedScene)->void:
	selectedItem = item
	selectedTool = 3

func initEditor()->void:
	clearItemPanel()
	createItemButtons()
	#gameManager.showMouse()
	gameManager.activeCamera.unposessObject(true)

func setSelectedObject(object:Node3D)->void:
	deselectObject()
	selectedObject = object
	for i in object.get_children():
		if i is MeshInstance3D:
			i.material_override = selectedMaterial
			for ichild in i.get_children():
				if ichild is MeshInstance3D:
					ichild.material_override = selectedMaterial

func _input(event: InputEvent) -> void:
	if !leaving:
		if event.is_action_pressed("gLeftClick"):
			if selectedTool == 3:
				if is_instance_valid(selectedItem) and get_from_mouse().has("position"):
					placeItem(get_from_mouse()["position"])

			if selectedTool == 1:
				if get_from_mouse().has("collider"):
					if get_from_mouse()["collider"].get_meta(&"canBeSelected"):
						setSelectedObject(get_from_mouse()["collider"])
					else:
						deselectObject()

		if event.is_action_pressed("gEditorDelete"):
			if is_instance_valid(selectedObject):
				selectedObject.queue_free()

		if event.is_action_pressed("gEscape"):
			leaving = true
			gameManager.removeSafehouseEditor()
			await get_tree().process_frame
			gameManager.pauseMenu.canPause = true
			gameManager.hideMouse()

	#if event.is_action_pressed("gEditorMouseToggle"):
		#if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			#gameManager.showMouse()
		#else:
			#gameManager.hideMouse()

func placeItem(gPosition:Vector3)->void:
	var inst = selectedItem.instantiate()
	gameManager.world.worldProps.add_child(inst)
	inst.global_position = gPosition
	inst.set_meta(&"canBeSelected",true)
	if autoselectAfterPlace:
		setSelectedObject(inst)
