extends CanvasLayer
@onready var backgroundElement : ColorRect = $gradientBG
@onready var contractsPanel : Control = $gradientBG/tabContainer/Contracts/contractsPanel
@onready var background : TextureRect = $gradientBG/background
#func _input(event)->void:
	#if event.is_action_pressed("gTabMenu"):
		#if visible:
			#unpauseGame()
		#else:
			##gradientAnim.play("in")
			#contractsPanel.scanContracts()
			#pauseGame()

func pauseGame()->void:
	show()
	backgroundElement.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_LINEAR)
	backgroundElement.position.y += 10
	tween.tween_property(backgroundElement,"modulate",Color.WHITE,0.065)
	tween.tween_property(backgroundElement,"position",Vector2(0,0),0.065)
#	musicManager.pauseMusic()
	#Dialogic.end_timeline()
	Input.mouse_mode = gameManager.get_meta(&"stored_mouse_mode", Input.MOUSE_MODE_CAPTURED)
	gameManager.showMouse()
	refreshBG()
	#get_tree().paused = true

func unpauseGame()->void:
	var tween = create_tween()
#	musicManager.resumeMusic()
	gameManager.set_meta(&"stored_mouse_mode", Input.mouse_mode)
	gameManager.hideMouse()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	await tween.tween_property(backgroundElement,"modulate",Color.TRANSPARENT,0.1).finished
	refreshBG()
	hide()
	#get_tree().paused = false

func refreshBG()->void:
	var tween = create_tween()
	var bg : CompressedTexture2D = load(["res://assets/misc/db7.png","res://assets/scenes/ui/saveloadmenu/save1.png","res://assets/scenes/ui/saveloadmenu/save2.png","res://assets/scenes/ui/saveloadmenu/save3.png","res://assets/scenes/ui/saveloadmenu/save4.png"].pick_random())
	await get_tree().process_frame
	background.texture = bg
	background.position += Vector2(randf_range(-150,-100),randf_range(-20,20))
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(background,"position",Vector2(0,0),0.65)
