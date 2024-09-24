@tool
extends Button
@export var item : PackedScene:
	set(value):
		item = value
		update_configuration_warnings()
@onready var statusLabel : Label = $itemStatus
@onready var itemName : Label = $itemName
@onready var itemDescription : Label = $itemDescription

var isPurchased:bool = false:
	set(value):
		isPurchased = value
		statusLabel.text = "Purchased"
		disabled = true

func purchase_item()->void:
	pass

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
