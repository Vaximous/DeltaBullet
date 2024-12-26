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
		instancedItem = item.instantiate()
		if !isPurchased:
			if instancedItem is Weapon:
				if gameManager.playerPawns[0].pawnCash >= instancedItem.weaponResource.displayData.gritPrice:
					if !doesHaveItem(gameManager.playerPawns[0]):
						purchaseSound.play()
						isPurchased = true
						gameManager.world.add_child(instancedItem)
						instancedItem.equipToPawn(gameManager.playerPawns[0])
						gameManager.notifyCheck("Purchased %s!"%instancedItem.objectName,4,5)
						gameManager.playerPawns[0].pawnCash -= instancedItem.weaponResource.displayData.gritPrice
				else:
					instancedItem.queue_free()
					gameManager.notify_warn("You do not have enough grit!",4,5)
					print("Not enough grit!")

func get_item_description_long() -> String:
	var inst = item.instantiate()
	if inst is Weapon:
		return inst.weaponResource.displayData.itemDescriptionLong
	else:
		return ""
	inst.queue_free()

func get_item_description() -> String:
	var inst = item.instantiate()
	if inst is Weapon:
		return inst.weaponResource.displayData.itemDescriptionShort
	else:
		return ""
	inst.queue_free()

func get_item_price() -> int:
	var inst = item.instantiate()
	if inst is Weapon:
		return inst.weaponResource.displayData.gritPrice
	else:
		return 0
	inst.queue_free()

func get_item_fire_rate() -> float:
	var inst = item.instantiate()
	if inst is InteractiveObject:
		return inst.weaponResource.displayData.fireRate
	else:
		return 0.0
	inst.queue_free()

func get_item_damage() -> float:
	var inst = item.instantiate()
	if inst is InteractiveObject:
		return inst.weaponResource.displayData.damage
	else:
		return 0.0
	inst.queue_free()

func get_item_penetration() -> float:
	var inst = item.instantiate()
	if inst is InteractiveObject:
		return inst.weaponResource.displayData.penetration
	else:
		return 0.0
	inst.queue_free()

func get_item_name() -> String:
	var inst = item.instantiate()
	if inst is InteractiveObject:
		return inst.objectName
	else:
		return " "
	inst.queue_free()

func get_item_data() -> ItemData:
	var inst = item.instantiate()
	if inst is Weapon:
		return inst.weaponResource.displayData
	else:
		return null
	inst.queue_free()

func setItemInfo()->void:
	statusLabel.text = str("$%s"%get_item_price())
	itemName.text = str("%s"%get_item_name())
	itemDescription.text = str("%s"%get_item_description())

func _get_configuration_warnings() -> PackedStringArray:
	var inst = item.instantiate()
	if inst != InteractiveObject:
		return ["The item is not of type InteractiveObject."]
	inst.queue_free()
	return []

func doesHaveItem(pawn:BasePawn)->bool:
	var inst = item.instantiate()
	if pawn.itemNames.has(inst.objectName):
		return true
	else:
		return false
	inst.queue_free()
