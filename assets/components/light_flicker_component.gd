@tool
extends Node


signal flickered(curved_value : float)

#@export var flicker_min: float = 0.2
#@export var flicker_max: float = 1.0
@export var flicker_curve : Curve = preload("res://assets/resources/default_flicker_curve.tres"):
	get:
		if flicker_curve == null:
			return preload("res://assets/resources/default_flicker_curve.tres")
		return flicker_curve
@export var flicker_delta: float = 0.1
@export var flicker_multiply_by_deltatime: bool = false
@export var property_path: String

var flicker_value_curved : float
var _flicker_value: float = 0.0:
	set(value):
		value = clamp(value, 0.0, 1.0)
		_flicker_value = value
		flicker_value_curved = flicker_curve.sample(value)
		flickered.emit(flicker_value_curved)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not ProjectSettings.get_setting("smackneck/dev/light_flicker_preview"):
		return
	var _property_path: NodePath = NodePath(property_path).get_as_property_path()
	var add = randf_range(-flicker_delta, flicker_delta)
	if flicker_multiply_by_deltatime:
		add *= delta
	_flicker_value += add

	var p = get_parent()
	if _property_path.get_subname(0) in p:
		get_parent().set_indexed(property_path, flicker_value_curved)
