extends CanvasLayer
@onready var previewIcon : TextureRect = $previewIcon
@onready var notifSound2 : AudioStreamPlayer = $sounds/notifSound2
@onready var animPlayer : AnimationPlayer = $animationPlayer
@onready var contractsPanel : Control = $contractsPanel
@onready var gradientAnim : AnimationPlayer = $gradientBG/animationPlayer
func _input(event)->void:
	if event.is_action_pressed("gTabMenu"):
		if visible:
			animPlayer.play("iconOut")
			previewIcon.visible = false
			gradientAnim.play("out")
			unpauseGame()
		else:
			gradientAnim.play("in")
			contractsPanel.scanContracts()
			pauseGame()

func pauseGame()->void:
	musicManager.pauseMusic()
	Dialogic.end_timeline()
	Input.mouse_mode = gameManager.get_meta(&"stored_mouse_mode", Input.MOUSE_MODE_CAPTURED)
	gameManager.showMouse()
	show()
	#get_tree().paused = true

func unpauseGame()->void:
	musicManager.resumeMusic()
	gameManager.set_meta(&"stored_mouse_mode", Input.mouse_mode)
	gameManager.hideMouse()
	hide()
	#get_tree().paused = false


func _on_contracts_mouse_entered():
	var contractIcon = load("res://assets/textures/menu/delta2_logo_vig.png")
	previewIcon.visible = true
	animPlayer.play("iconIn")

func _on_contracts_mouse_exited():
	animPlayer.play("iconOut")
