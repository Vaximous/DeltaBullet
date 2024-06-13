extends Control


func _input(event)->void:
	if event.is_action_pressed("ui_focus_next"):
		visible = !visible
