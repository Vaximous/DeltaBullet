extends CanvasLayer
@onready var blur = $blur
@onready var customizationUI : Control = $customizationUi
@onready var equipSound : AudioStreamPlayer = $equipSounds
@export_enum("Hair","Headwear","Facewear","Body","Pants")var selectedSection : int = 2:
	set(value):
		selectedSection = value
		setSectionLabel(value)
var clothingPawn : BasePawn:
	set(value):
		clothingPawn = value
		setPreviewAppearance()
		setupButtons()
@onready var animationTitlebar : AnimationPlayer = $customizationUi/animationPlayer
@onready var characterPreviewWorld = $customizationUi/characterPreviewContainer/subViewportContainer/subViewport/customizationWorld
@export var buttonHolder : HBoxContainer
@export var clothingButtonsHolder : GridContainer
@export var sectionLabel : Label
const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT

func _ready() -> void:
	#setupButtons()
	animationTitlebar.play("titlebarIn")
	gameManager.showMouse()


func enlargeControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1.5,1.5),defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func resetControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1,1),defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func setupButtons()->void:
	if buttonHolder != null:
		for buttons in buttonHolder.get_children():
			buttons.pivot_offset = buttons.size/2
			buttons.mouse_entered.connect(enlargeControlScale.bind(buttons))
			buttons.mouse_exited.connect(resetControlScale.bind(buttons))
			buttons.pressed.connect(setSection.bind(getSelectedSectionID(buttons)))
			buttons.pressed.connect(generateClothingOptions.bind(clothingPawn))



func clearClothingItems()->void:
	for items in clothingButtonsHolder.get_children():
		items.queue_free()


func setSection(id:int)->void:
	selectedSection = id
	print(selectedSection)

func getSelectedSectionID(button:TextureButton)->int:
	var id : int = 0
	for buttonid in buttonHolder.get_children().size():
		if buttonHolder.get_child(buttonid) == button:
			id = buttonid
	return id

func _exit_tree() -> void:
	gameManager.hideMouse()
	gameManager.pauseMenu.canPause = true
	clothingPawn.checkClothes()
	gameManager.saveTemporaryPawnInfo()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		fadeOut()


func setPreviewAppearance()->void:
	if clothingPawn:
		characterPreviewWorld.customCharacter.loadPawnInfo(clothingPawn.savePawnInformation())



func setSectionLabel(section:int = 0)->void:
	if sectionLabel:
		match selectedSection:
			0:
				sectionLabel.text = "Hair"
			1:
				sectionLabel.text = "Hats"
			2:
				sectionLabel.text = "Face"
			3:
				sectionLabel.text = "Body"
			4:
				sectionLabel.text = "Pants"


func checkClothingItem(item:PackedScene)->bool:
	var boolean : bool = false
	if item and clothingPawn:
		for i in clothingPawn.clothingInventory:
			if i != null:
				if i.scene_file_path == item.instantiate().scene_file_path:
					boolean = true
	return boolean


func fadeOut()->void:
	var tween = create_tween()
	tween.parallel().tween_property(blur,"modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	await tween.parallel().tween_property(customizationUI,"modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
	gameManager.removeCustomization()

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
	#clothingPawn.checkClothes()


func equipClothingToPawn(item:PackedScene)->void:
	if clothingPawn and item:
		var itemInstance = item.instantiate()
		clothingPawn.clothingHolder.add_child(itemInstance)
		clothingPawn.checkClothes()
		setPreviewAppearance()

func unequipClothingFromPawn(item:PackedScene)->void:
	if clothingPawn and item:
		var filePath = item.instantiate().scene_file_path
		for clothing in clothingPawn.clothingInventory:
			if clothing.scene_file_path == filePath:
				clothingPawn.clothingInventory.erase(clothing)
				clothing.queue_free()
				#clothingPawn.clothingInventory.remove_at(clothingInt)
		clothingPawn.setBodyVisibility(true)
		clothingPawn.clothingInventory.clear()
		await get_tree().process_frame
		clothingPawn.checkClothes()
		setPreviewAppearance()


func generateClothingOptions(pawn:BasePawn)->void:
	var clothingItem = load("res://assets/scenes/ui/customization/customizationClothing.tscn")
	##Clear the current catalog
	clearClothingItems()

	##Grab what clothing items the pawn has purchased and create clothing item options from it as well as making sure it matches the current category
	if pawn != null:
		for clothing in pawn.purchasedClothing:
			var itemLoad = load(clothing)
			if itemLoad.instantiate().clothingCategory == selectedSection:
				var button = clothingItem.instantiate()
				button.clothingItem = itemLoad
				clothingButtonsHolder.add_child(button)
				button.isEquipped = checkClothingItem(itemLoad)
				button.button.pressed.connect(toggleItem.bind(button))
