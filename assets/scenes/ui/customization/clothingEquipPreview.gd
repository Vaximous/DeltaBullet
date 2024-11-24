extends MarginContainer
@export var itemText : Label
@export var pawnHolder : Node3D
@export var examplePawn : BasePawn:
	set(value):
		examplePawn = value
		examplePawn.pawnColor = Color.WHITE
		examplePawn.pawnEnabled = false
		examplePawn.animationToForce = "PawnAnim/Idle"
		examplePawn.forceAnimation = true
@export_category("Clothing Options")
@export var clothingItem : PackedScene:
	set(value):
		clothingItem = value

func _ready() -> void:
	initClothingItem()


func initClothingItem()->void:
	if clothingItem != null:
		var item : ClothingItem = clothingItem.instantiate().duplicate()
		examplePawn.clothingHolder.add_child(item)
		examplePawn.pawnColor = Color.WHITE
		itemText.text = item.itemName
		examplePawn.checkClothes()
		examplePawn.setPawnMaterial()
	else:
		pass
		#queue_free()
