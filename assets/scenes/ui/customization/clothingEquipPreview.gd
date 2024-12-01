extends MarginContainer
@onready var equippedIcon : TextureRect = $backgroundPanel/equippedIcon
@export var isEquipped : bool = false:
	set(value):
		isEquipped = value
		if equippedIcon:
			if isEquipped:
				equippedIcon.show()
			else:
				equippedIcon.hide()
@export var button : Button
@export var itemText : Label
@export var pawnHolder : Node3D
@export var animationPlayer : AnimationPlayer
@export var viewportCamera : Camera3D
@export var examplePawn : BasePawn:
	set(value):
		examplePawn = value

const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT


@export_category("Clothing Options")
@export var clothingItem : PackedScene

func _ready() -> void:
	initClothingItem()
	setupButton()

func initClothingItem()->void:
	animationPlayer.play("buffer")
	if clothingItem != null:
		#Set up the pawn
		if examplePawn != null:
			examplePawn.hide()
			examplePawn.pawnColor = Color.WHITE
			examplePawn.pawnEnabled = false
			examplePawn.animationToForce = "PawnAnim/Idle"
			examplePawn.forceAnimation = true

		#Spawn the clothing item and add it to the pawn
		var item : ClothingItem = clothingItem.instantiate()
		examplePawn.clothingHolder.add_child(item)
		itemText.text = item.itemName
		examplePawn.checkClothes()
		examplePawn.setPawnMaterial()
		examplePawn.show()
		setCameraPosition()
		animationPlayer.play("buffer_done")


func enlargeControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1.1,1.1),defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func resetControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1,1),defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func setupButton()->void:
	if button:
		pivot_offset = size/2
		button.mouse_entered.connect(enlargeControlScale.bind(self))
		button.mouse_exited.connect(resetControlScale.bind(self))


func setCameraPosition()->void:
	if viewportCamera != null and clothingItem != null:
		match clothingItem.instantiate().clothingType:
			0:
				viewportCamera.position.y = 1.835
			1:
				viewportCamera.position.y = 1.835
			2:
				viewportCamera.position.y = 1.835
			3:
				viewportCamera.position.y = 1.625
			4:
				viewportCamera.position.y = 1.025
			5:
				viewportCamera.position.y = 1.025
