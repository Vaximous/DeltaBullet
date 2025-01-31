extends CanvasLayer
var tween : Tween

func tweenBlur()->void:
	if !tween:
		tween = create_tween()
	%blurMargin.modulate = Color.TRANSPARENT
	tween.parallel().tween_property(%blurMargin,"modulate", Color.WHITE,0.3)


func tweenDeathOptions()->void:
	if !tween:
		tween = create_tween()
		#tween.kill()
	%deathOptions.modulate = Color.TRANSPARENT
	tween.parallel().tween_property(%deathOptions,"modulate", Color.WHITE,0.3)

func _ready() -> void:
	add_to_group(&"DeathScreen")
	gameManager.showMouse()
	gameManager.pauseMenu.canPause = false
	tweenBlur()
	tweenDeathOptions()

func fadeOut()->void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(%deathOptions,"modulate", Color.TRANSPARENT,0.5)
	await tween.parallel().tween_property(%blurMargin,"modulate", Color.TRANSPARENT,0.3).finished
	queue_free()

func _on_restart_button_pressed() -> void:
	gameManager.restartScene()
	fadeOut()


func _on_back_to_menu_pressed() -> void:
	await Fade.fade_out(0.4, Color(0,0,0,1),"GradientVertical",false,true).finished
	get_tree().change_scene_to_file("res://assets/scenes/menu/menu.tscn")
	fadeOut()
