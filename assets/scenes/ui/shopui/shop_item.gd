@tool
extends Button
@export var item : PackedScene:
	set(value):
		item = value
		update_configuration_warnings()
@onready var statusLabel : Label = $itemStatus
@onready var itemName : Label = $itemName
@onready var itemDescription : Label = $itemDescription
@onready var purchaseSound : AudioStreamPlayer = $purchaseSound

var isPurchased:bool = false:
	set(value):
		isPurchased = value
		statusLabel.text = "Purchased"

func purchase_item()->void:
	if gameManager.playerPawns[0] != null:
		if !isPurchased:
			if item.instantiate() is Weapon:
				var instancedItem = item.instantiate()
				if gameManager.playerPawns[0].pawnCash >= instancedItem.weaponResource.gritPrice:
					if !doesHaveItem(gameManager.playerPawns[0]):
						purchaseSound.play()
						isPurchased = true
						gameManager.world.add_child(instancedItem)
						instancedItem.equipToPawn(gameManager.playerPawns[0])
						gameManager.notifyCheck("Purchased %s!"%instancedItem.objectName,4,5)
						gameManager.playerPawns[0].pawnCash -= instancedItem.weaponResource.gritPrice
				else:
					gameManager.notify_warn("You do not have enough grit!",4,5)
					print("Not enough grit!")

func get_item_description_long() -> String:
	if item.instantiate() is Weapon:
		return item.instantiate().weaponResource.itemDescriptionLong
	else:
		return ""

func get_item_description() -> String:
	if item.instantiate() is Weapon:
		return item.instantiate().weaponResource.itemDescriptionShort
	else:
		return ""

func get_item_price() -> int:
	if item.instantiate() is Weapon:
		return item.instantiate().weaponResource.gritPrice
	else:
		return 0

func get_item_name() -> String:
	if item.instantiate() is InteractiveObject:
		return item.instantiate().objectName
	else:
		return " "

func get_item_data() -> ItemData:
	if item.instantiate() is Weapon:
		return item.item.instantiate().weaponResource
	else:
		return null

func setItemInfo()->void:
	statusLabel.text = str("$%s"%get_item_price())
	itemName.text = str("%s"%get_item_name())
	itemDescription.text = str("%s"%get_item_description())

func _get_configuration_warnings() -> PackedStringArray:
	if item.instantiate() != InteractiveObject:
		return ["The item is not of type InteractiveObject."]
	return []

func doesHaveItem(pawn:BasePawn)->bool:
	if pawn.itemNames.has(item.instantiate().objectName):
		return true
	else:
		return false
