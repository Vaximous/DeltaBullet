extends CanvasLayer
@onready var animPlayer : AnimationPlayer = $animationPlayer
@onready var contractsPanel : Control = $contractsPanel

func _input(event)->void:
	if event.is_action_pressed("gTabMenu"):
		if visible:
			unpauseGame()
		else:
			contractsPanel.scanContracts()
			pauseGame()

func pauseGame()->void:
	#musicManager.pauseMusic()
	Dialogic.end_timeline()
	Input.mouse_mode = gameManager.get_meta(&"stored_mouse_mode", Input.MOUSE_MODE_CAPTURED)
	gameManager.showMouse()
	show()
	#get_tree().paused = true

func unpauseGame()->void:
	#musicManager.resumeMusic()
	gameManager.set_meta(&"stored_mouse_mode", Input.mouse_mode)
	gameManager.hideMouse()
	hide()
	#get_tree().paused = false
