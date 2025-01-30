@tool extends MarginContainer
@export_category("Editor Item")
@onready var itemHolder = %itemHolder
@onready var button : Button = $button
## What item is this?
@export var placeableObject : PackedScene:
	set(value):
		placeableObject = value
		if is_instance_valid(itemHolder):
			for i in itemHolder.get_children():
				i.queue_free()

			var inst = placeableObject.instantiate()
			itemHolder.add_child(inst)


func _process(delta: float) -> void:
	if itemHolder.rotation.y >= 180:
		itemHolder.rotation.y = 0

	itemHolder.rotation.y += 0.55 * delta
