class_name ElectricityComponent
extends Node3D

signal powered_on
signal powered_off
signal state_change(new_state: bool)

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
		if disabled:
			value = false
		if powered != value:
			powered = value
			if powered:
				powered_on.emit()
			else:
				powered_off.emit()
			state_change.emit(powered)
			if connected_to != null:
				connected_to.powered = powered

@export_storage var disabled: bool = false:
	set(value):
		if value:
			powered = false
		disabled = value

var connected_from: ElectricityComponent


func _ready() -> void:
	state_change.emit(powered)


static func get_component(of_node: Node) -> ElectricityComponent:
	if of_node is ElectricityComponent:
		return of_node
	return of_node.get_node_or_null("electricityComponent")


func disable() -> void:
	disabled = true


func enable() -> void:
	disabled = false


func set_disabled(state: bool) -> void:
	disabled = state


func power_on() -> void:
	powered = true


func power_off() -> void:
	powered = false


func set_power(power: bool) -> void:
	powered = power


func is_root() -> bool:
	return connected_from == null


func set_power_no_signal(power: bool) -> void:
	set_block_signals(true)
	powered = power
	set_block_signals(false)


func _exit_tree() -> void:
	powered = false
	if connected_from != null:
		connected_from.connected_to = null
	connected_to = null
