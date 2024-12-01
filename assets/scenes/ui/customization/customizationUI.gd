extends Control
var selectedSection : int = 2
var clothingPawn : BasePawn
@onready var animationTitlebar : AnimationPlayer = $animationPlayer
@export var buttonHolder : HBoxContainer
@export var clothingButtonsHolder : GridContainer

const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT

func _ready() -> void:
	setupButtons()
	animationTitlebar.play("titlebarIn")

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


func generateClothingOptions(pawn:BasePawn)->void:
	##Clear the current catalog
	clearClothingItems()

	##Grab what clothing items the pawn has purchased and create clothing item options from it as well as making sure it matches the current category
