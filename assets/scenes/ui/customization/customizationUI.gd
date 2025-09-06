extends CanvasLayer
@onready var equippedIndex : VBoxContainer = $customizationUi/equippedIndex
@onready var blur = $blur
@onready var customizationUI : Control = $customizationUi
@onready var equipSound : AudioStreamPlayer = $equipSounds
var customizeTween : Tween
@export_enum("Hair","Headgear","Bling","Body","Pants")var selectedSection : int = 1:
	set(value):
		selectedSection = value
		setSectionLabel(value)
var clothingPawn : BasePawn:
	set(value):
		clothingPawn = value
		setPreviewAppearance()
		setupButtons()
		refreshEquippedIndex()
		%characterColor.color = clothingPawn.pawnColor
@onready var animationTitlebar : AnimationPlayer = $customizationUi/animationPlayer
@onready var characterPreviewWorld = $customizationUi/characterPreviewContainer/subViewportContainer/subViewport/customizationWorld
@export var buttonHolder : HBoxContainer
@export var clothingButtonsHolder : GridContainer
@export var sectionLabel : Label
const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var colorInst : Array = []

func _ready() -> void:
	#setupButtons()
	customizationUI.modulate = Color.TRANSPARENT
	animationTitlebar.play("titlebarIn")
	gameManager.showMouse()
	fadeCustomizationUIIn()
	#refreshEquippedIndex()

func getPawnMesh()->MeshInstance3D:
	var ret
	if is_instance_valid(clothingPawn.pawnSkeleton):
		for mesh in clothingPawn.pawnSkeleton.get_children():
			if mesh is MeshInstance3D:
				ret = mesh
	return ret

func getPreviewPawn()->BasePawn:
	return characterPreviewWorld.customCharacter

func getPreviewPawnMeshes()->Array:
	var ret : Array
	if is_instance_valid(characterPreviewWorld.customCharacter.pawnSkeleton):
		for mesh in characterPreviewWorld.customCharacter.pawnSkeleton.get_children():
			if mesh is MeshInstance3D:
				ret.append(mesh)
	return ret

func getPreviewPawnMesh()->MeshInstance3D:
	var ret
	if is_instance_valid(characterPreviewWorld.customCharacter.pawnSkeleton):
		for mesh in characterPreviewWorld.customCharacter.pawnSkeleton.get_children():
			if mesh is MeshInstance3D:
				ret = mesh
	return ret

func changePawnColor()->void:
	if clothingPawn and clothingPawn.pawnColor !=$%characterColor.color:
		clothingPawn.pawnColor = %characterColor.color
		clothingPawn.setPawnMaterial()
		clothingPawn.setupPawnColor()

		for i in getPreviewPawnMeshes():
			i.set_surface_override_material(0,clothingPawn.currentPawnMat)


func _process(delta: float) -> void:
	if clothingPawn:
		changePawnColor()
		#setPreviewClothingMaterials()

func enlargeControlScale(control:Control,size:float=1.5)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(size,size),defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func resetControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1,1),defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func fadeCustomizationUIOut()->void:
	if customizeTween:
		customizeTween.kill()
	customizeTween = create_tween()
	customizeTween.parallel().tween_property(blur,"modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	await customizeTween.parallel().tween_property(customizationUI,"modulate",Color.TRANSPARENT,0.35).set_trans(defaultTransitionType).set_ease(defaultEaseType).finished
	gameManager.removeCustomization()

func fadeCustomizationUIIn()->void:
	if customizeTween:
		customizeTween.kill()
	customizeTween = create_tween()
	customizeTween.tween_property(customizationUI,"modulate",Color.WHITE,0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)

func setupButtons()->void:
	if buttonHolder != null:
		for buttons in buttonHolder.get_children():
			buttons.pivot_offset = buttons.size/2
			buttons.mouse_entered.connect(enlargeControlScale.bind(buttons,1.15))
			buttons.mouse_entered.connect(playHoverSound)
			buttons.mouse_exited.connect(resetControlScale.bind(buttons))
			buttons.pressed.connect(setSection.bind(getSelectedSectionID(buttons)))
			buttons.pressed.connect(generateClothingOptions.bind(clothingPawn))
			#buttons.pressed.connect(playClickSound)


func clearEquippedIndex()->void:
	for i in equippedIndex.get_children():
		if i is PanelContainer:
			i.queue_free()

func createEquippedIndexEntry(item:ClothingItem)->PanelContainer:
	var entry = load("res://assets/scenes/ui/customization/equippedIndexEntry.tscn").instantiate()
	entry.clothingItem = item
	equippedIndex.add_child(entry)
	return entry


func playHoverSound()->void:
	#if !%hoverSound.playing:
	%hoverSound.play()


func playClickSound()->void:
	#if !%clickSound.playing:
	%clickSound.play()


func clearClothingItems()->void:
	for items in clothingButtonsHolder.get_children():
		items.queue_free()


func setSection(id:int)->void:
	selectedSection = id

func getSelectedSectionID(button:TextureButton)->int:
	var id : int = 0
	for buttonid in buttonHolder.get_children().size():
		if buttonHolder.get_child(buttonid) == button:
			id = buttonid
	return id

func _exit_tree() -> void:
	gameManager.hideMouse()
	for i in colorInst:
		i.queue_free()
	gameManager.pauseMenu.canPause = true
	clothingPawn.checkClothes()
	gameManager.saveTemporaryPawnInfo()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		fadeCustomizationUIOut()

func setClothingMaterial(clothingItemFrom:ClothingItem,Pawn:BasePawn):
	for i in Pawn.clothingInventory:
		if i.scene_file_path == clothingItemFrom.scene_file_path:
			for overrideindex in i.clothingMesh.get_surface_override_material_count():
				i.clothingMesh.set_surface_override_material(overrideindex,clothingItemFrom.clothingMesh.get_surface_override_material(overrideindex))

func setPreviewClothingMaterials()->void:
	#getPreviewPawn().clothingInventory.clear()
	if clothingPawn:
		for i in clothingPawn.clothingInventory.size():
			print(getPreviewPawn().clothingInventory.size())
			for overrideindex in getPreviewPawn().clothingInventory[i].clothingMesh.get_surface_override_material_count():
				getPreviewPawn().clothingInventory[i].clothingMesh.set_surface_override_material(overrideindex,clothingPawn.clothingInventory[i].clothingMesh.get_surface_override_material(overrideindex))

func setPreviewAppearance()->void:
	if clothingPawn:
		characterPreviewWorld.customCharacter.loadPawnInfo(clothingPawn.savePawnInformation())
		setPreviewClothingMaterials()
		for i in clothingPawn.clothingInventory:
			setClothingMaterial(i,getPreviewPawn())

func setSectionLabel(section:int = 0)->void:
	if sectionLabel:
		match selectedSection:
			0:
				sectionLabel.text = "Hair"
			1:
				sectionLabel.text = "Headgear"
			2:
				sectionLabel.text = "Bling"
			3:
				sectionLabel.text = "Body"
			4:
				sectionLabel.text = "Pants"


func checkClothingItem(item:PackedScene)->bool:
	var boolean : bool = false
	var itemInstance = item.instantiate()
	if item and clothingPawn:
		for i in clothingPawn.clothingInventory:
			if i != null:
				if i.scene_file_path == itemInstance.scene_file_path:
					boolean = true
	itemInstance.queue_free()
	return boolean



func toggleItem(item)->void:
	if item:
		equipSound.play()
		if item.isEquipped:
			item.isEquipped = false
			unequipClothingFromPawn(item.clothingItem)
		else:
			item.isEquipped = true
			equipClothingToPawn(item.clothingItem)
	setPreviewAppearance()
	#setPreviewClothingMaterials()
	#clothingPawn.checkClothes()


func equipClothingToPawn(item:PackedScene)->void:
	if clothingPawn and item:
		getPreviewPawn().clothingInventory.clear()
		var itemInstance = item.instantiate()
		clothingPawn.clothingHolder.add_child(itemInstance)
		clothingPawn.checkClothes()
		refreshEquippedIndex()
		setPreviewAppearance()
		setClothingMaterial(itemInstance,getPreviewPawn())
		gameManager.saveTemporaryPawnInfo()

func refreshEquippedIndex()->void:
	clearEquippedIndex()
	for i in clothingPawn.clothingInventory:
		var entry = createEquippedIndexEntry(i)
		entry.setPreviewMesh(i.clothingMesh)

func unequipClothingFromPawn(item:PackedScene)->void:
	if clothingPawn and item:
		var itemInstance = item.instantiate()
		if is_instance_valid(itemInstance):
			var filePath = itemInstance.scene_file_path
			for clothing in clothingPawn.clothingInventory:
				if clothing.scene_file_path == filePath and is_instance_valid(clothing) and clothing != null:
					clothingPawn.clothingInventory.erase(clothing)
					clothing.queue_free()
					#clothingPawn.clothingInventory.remove_at(clothingInt)
		clothingPawn.resetBodyShape()
		clothingPawn.clothingInventory.clear()
		await get_tree().process_frame
		await get_tree().process_frame
		clothingPawn.checkClothes()
		itemInstance.queue_free()
		setPreviewAppearance()
		refreshEquippedIndex()
		gameManager.saveTemporaryPawnInfo()


func generateClothingOptions(pawn:BasePawn)->void:
	var clothingItem = load("res://assets/scenes/ui/customization/customizationClothing.tscn")
	##Clear the current catalog
	clearClothingItems()

	##Grab what clothing items the pawn has purchased and create clothing item options from it as well as making sure it matches the current category
	if pawn != null:
		for clothing in pawn.purchasedClothing:
			var itemLoad = load(clothing)
			var itemInstance = itemLoad.instantiate()
			if itemInstance.clothingCategory == selectedSection:
				var button = clothingItem.instantiate()
				button.clothingItem = itemLoad
				clothingButtonsHolder.add_child(button)
				button.isEquipped = checkClothingItem(itemLoad)
				button.button.pressed.connect(toggleItem.bind(button))
			itemInstance.queue_free()
