class_name ElectricityComponent
extends Node3D

signal powered_on
signal powered_off

##If it's connected to another ElectricityComponent, it give power to that component.
@export var connected_to: ElectricityComponent:
	set(value):
		if connected_to != value:
			if connected_to != null:
				connected_to.connected_from = null
				connected_to.powered = false
			if value != null:
				connected_to = value
				connected_to.connected_from = self
				connected_to.powered = powered
##If it's powered, the children will also be powered.
@export var powered: bool = false:
	set(value):
		if powered != value:
			powered = value
			if powered:
				powered_on.emit()
			else:
				powered_off.emit()
			if connected_to != null:
				connected_to.powered = powered

var connected_from: ElectricityComponent


static func get_component(of_node: Node) -> ElectricityComponent:
	if of_node is ElectricityComponent:
		return of_node
	return of_node.get_node_or_null("electricityComponent")


func is_root() -> bool:
	return connected_from == null


func _exit_tree() -> void:
	powered = false
	if connected_from != null:
		connected_from.connected_to = null
	connected_to = null
