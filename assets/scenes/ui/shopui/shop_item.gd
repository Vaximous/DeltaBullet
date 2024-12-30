@tool
extends Button
var instancedItem
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
		var _instancedItem = item.instantiate()
		if !isPurchased:
			if _instancedItem is Weapon:
				if gameManager.playerPawns[0].pawnCash >= _instancedItem.weaponResource.displayData.gritPrice:
					if !doesHaveItem(gameManager.playerPawns[0]):
						purchaseSound.play()
						isPurchased = true
						gameManager.world.add_child(_instancedItem)
						_instancedItem.equipToPawn(gameManager.playerPawns[0])
						gameManager.notifyCheck("Purchased %s!"%_instancedItem.objectName,4,5)
						gameManager.playerPawns[0].pawnCash -= _instancedItem.weaponResource.displayData.gritPrice
				else:
					_instancedItem.queue_free()
					gameManager.notify_warn("You do not have enough grit!",4,5)
					print("Not enough grit!")

func get_item_description_long() -> String:
	var result = null
	instancedItem = item.instantiate()
	if instancedItem is Weapon:
		result = instancedItem.weaponResource.displayData.itemDescriptionLong
	instancedItem.queue_free()
	return result

func get_item_description() -> String:
	instancedItem = item.instantiate()
	var result = null
	if instancedItem is Weapon:
		result = instancedItem.weaponResource.displayData.itemDescriptionShort
	instancedItem.queue_free()
	return result

func get_item_price() -> int:
	instancedItem = item.instantiate()
	var result = null
	if instancedItem is Weapon:
		result = instancedItem.weaponResource.displayData.gritPrice
	instancedItem.queue_free()
	return result

func get_item_fire_rate() -> float:
	var result = null
	var instancedItem = item.instantiate()
	if instancedItem is InteractiveObject:
		result = instancedItem.weaponResource.displayData.fireRate
	instancedItem.queue_free()
	return result

func get_item_damage() -> float:
	var result = null
	instancedItem = item.instantiate()
	if instancedItem is InteractiveObject:
		result = instancedItem.weaponResource.displayData.damage
	instancedItem.queue_free()
	return result

func get_item_penetration() -> float:
	var result = null
	instancedItem = item.instantiate()
	if instancedItem is InteractiveObject:
		result = instancedItem.weaponResource.displayData.penetration
	instancedItem.queue_free()
	return result

func get_item_name() -> String:
	var result = null
	instancedItem = item.instantiate()
	if instancedItem is InteractiveObject:
		result = instancedItem.objectName
	instancedItem.queue_free()
	return result

func get_item_data() -> ItemData:
	var result
	var instancedItem = item.instantiate()
	if instancedItem is Weapon:
		result = instancedItem.weaponResource.displayData

	instancedItem.queue_free()
	return result

func setItemInfo()->void:
	statusLabel.text = str("$%s"%get_item_price())
	itemName.text = str("%s"%get_item_name())
	itemDescription.text = str("%s"%get_item_description())

func _get_configuration_warnings() -> PackedStringArray:
	var result = []
	instancedItem = item.instantiate()
	if instancedItem != InteractiveObject:
		result = ["The item is not of type InteractiveObject."]
	instancedItem.queue_free()
	return result

func doesHaveItem(pawn:BasePawn)->bool:
	var result = false
	instancedItem = item.instantiate()
	result = pawn.itemNames.has(instancedItem.objectName)
	instancedItem.queue_free()
	return result
