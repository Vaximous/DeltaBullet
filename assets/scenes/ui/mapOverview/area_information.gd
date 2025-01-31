extends MarginContainer
var marker
@export var map : CanvasLayer
func _on_travel_button_pressed() -> void:
	if marker:
		marker.gotoLocation()
