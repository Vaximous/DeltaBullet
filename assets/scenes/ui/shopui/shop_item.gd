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


func get_item_price() -> int:
	return 0


func get_item_data() -> ItemData:
	return null


func _get_configuration_warnings() -> PackedStringArray:
	if item.instantiate() != InteractiveObject:
		return ["The item is not of type InteractiveObject."]
	return []
