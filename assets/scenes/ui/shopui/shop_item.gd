extends Button
@export var item : InteractiveObject = null
@onready var statusLabel : Label = $itemStatus
@onready var itemName : Label = $itemName
@onready var itemDescription : Label = $itemDescription
var isPurchased:bool = false:
	set(value):
		isPurchased = value
		statusLabel.text = "Purchased"
		disabled = true

func purchase()->void:
	pass
