extends CanvasLayer
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

func getSelectedSectionID(button:Button)->int:
	var id : int = 0
	for buttonid in buttonHolder.get_children().size():
		if buttonHolder.get_child(buttonid) == button:
			id = buttonid
	return id

func _exit_tree() -> void:
	gameManager.hideMouse()
	gameManager.pauseMenu.canPause = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		gameManager.removeCustomization()


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
