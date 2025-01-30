extends CanvasLayer
@onready var itemContainer = %itemContainer
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

func _physics_process(delta: float) -> void:
	if is_instance_valid(itemGhost):
		if itemGhost is RigidBody3D:
			itemGhost.freeze = true
			itemGhost.collision_layer = 0
			itemGhost.collision_mask = 0


		itemGhost.global_position = lerp(itemGhost.global_position,gameManager.activeCamera.editorCast.get_collision_point(),18*delta)

func createItemButtons()->void:
	for placeable in gameManager.purchasedPlacables:
		var inst = itemButton.instantiate()
		itemContainer.add_child(inst)
		inst.placeableObject = placeable
		inst.button.pressed.connect(setSelectedItem.bind(inst.placeableObject))

func clearItemPanel()->void:
	for i in %itemContainer.get_children():
		i.queue_free()

func setSelectedItem(item:PackedScene)->void:
	selectedItem = item

func initEditor()->void:
	clearItemPanel()
	createItemButtons()
	#gameManager.showMouse()
	gameManager.activeCamera.unposessObject(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gLeftClick") and gameManager.isMouseHidden():
		if is_instance_valid(selectedItem):
			var inst = selectedItem.instantiate()
			gameManager.world.worldProps.add_child(inst)
			inst.global_position = gameManager.activeCamera.camCast.get_collision_point()

	if event.is_action_pressed("gEscape"):
		gameManager.removeSafehouseEditor()
		gameManager.pauseMenu.canPause = true

	if event.is_action_pressed("gEditorMouseToggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			gameManager.showMouse()
		else:
			gameManager.hideMouse()
