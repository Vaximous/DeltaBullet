extends CanvasLayer
@onready var equippedIndex : VBoxContainer = $customizationUi/equippedIndex
@onready var blur = $blur
@onready var customizationUI : Control = $customizationUi
@onready var equipSound : AudioStreamPlayer = $equipSounds
@onready var colorChanger : Control = $customizationUi/colorChanger
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

func toggleColorChanger(item)->void:
	var itm = item.instantiate()
	colorInst.append(itm)
	colorChanger.visible = !colorChanger.visible
	colorChanger.selectItem(itm)
	colorChanger.selectedID = 0

func clearEquippedIndex()->void:
	for i in equippedIndex.get_children():
		if i is PanelContainer:
			i.queue_free()

func createEquippedIndexEntry(item:ClothingItem)->void:
	var entry = load("res://assets/scenes/ui/customization/equippedIndexEntry.tscn").instantiate()
	entry.clothingItem = item
	equippedIndex.add_child(entry)


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
	print(selectedSection)

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


func setPreviewAppearance()->void:
	if clothingPawn:
		characterPreviewWorld.customCharacter.loadPawnInfo(clothingPawn.savePawnInformation())




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
	#clothingPawn.checkClothes()


func equipClothingToPawn(item:PackedScene)->void:
	if clothingPawn and item:
		var itemInstance = item.instantiate()
		clothingPawn.clothingHolder.add_child(itemInstance)
		clothingPawn.checkClothes()
		setPreviewAppearance()
		refreshEquippedIndex()
		gameManager.saveTemporaryPawnInfo()

func refreshEquippedIndex()->void:
	clearEquippedIndex()
	for i in clothingPawn.clothingInventory:
		createEquippedIndexEntry(i)

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
		clothingPawn.setBodyVisibility(true)
		clothingPawn.clothingInventory.clear()
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
