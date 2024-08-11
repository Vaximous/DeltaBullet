extends Control
@onready var subviewportContainer : SubViewportContainer = $subViewportContainer

var showMenu : bool = false:
	set(value):
		showMenu = value
		if value:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event.is_action_pressed("gUse"):
		if showMenu:
			showMenu = false
		else:
			showMenu = true
