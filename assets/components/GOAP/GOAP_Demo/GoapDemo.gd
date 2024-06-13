extends Node2D


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				$TargetPos.global_position = get_global_mouse_position()
