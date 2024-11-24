extends MarginContainer
@export var itemText : Label
@export var pawnHolder : Node3D
@export var animationPlayer : AnimationPlayer
@export var examplePawn : BasePawn:
	set(value):
		examplePawn = value

@export_category("Clothing Options")
@export var clothingItem : PackedScene

func _ready() -> void:
	initClothingItem()


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
		animationPlayer.play("buffer_done")
