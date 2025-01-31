extends Control
class_name PauseMenu
var fadeSpeed : int = 8
var canPause : bool = true
@onready var soundPlayer : AudioStreamPlayer = $audioStreamPlayer
@onready var secondSound : AudioStreamPlayer = $audioStreamPlayer2
@onready var gradientBG : TextureRect = $gradientBG
@onready var saveLoadMenu : Control = $saveloadmenu
@onready var resumeButton : Button = $buttons/ResumeButton
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var tweenFade : Tween

func _ready() -> void:
	gradientBG.self_modulate = Color.TRANSPARENT
	modulate = Color.TRANSPARENT
	saveLoadMenu.modulate = Color.TRANSPARENT
	hide()


func fadeOut()->bool:
	if tweenFade:
		tweenFade.kill()
	tweenFade = create_tween()
	tweenFade.parallel().tween_property(gradientBG,"self_modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	await tweenFade.parallel().tween_property(self,"modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
	return true

func fadeIn()->bool:
	if tweenFade:
		tweenFade.kill()
	tweenFade = create_tween()
	modulate = Color.TRANSPARENT
	tweenFade.tween_property(gradientBG,"self_modulate",Color.WHITE,0.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	await tweenFade.parallel().tween_property(self,"modulate",Color.WHITE,0.5).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
	return true

#func _process(delta)->void:
	#if get_tree().paused:
		#modulate = lerp(modulate,Color.WHITE,fadeSpeed*delta)
		#gradientBG.self_modulate = lerp(gradientBG.self_modulate,Color.WHITE,fadeSpeed*delta)
	#else:
		#modulate = Color.TRANSPARENT
		#gradientBG.self_modulate = lerp(gradientBG.self_modulate,Color.TRANSPARENT,fadeSpeed*delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		if canPause:
			if visible:
				unpauseGame()
			else:
				pauseGame()

func _on_resume_button_pressed()->void:
	unpauseGame()

func _on_menu_button_pressed()->void:
	musicManager.fade_all_audioplayers_out(0.5)
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://assets/scenes/menu/menu.tscn")

func unpauseGame()->void:
	if musicManager.get_all_channels():
		for i in musicManager.get_all_channels():
			musicManager.set_channel_pause(i,false)
	#musicManager.resumeMusic()
	soundPlayer.play()
	gameManager.set_meta(&"stored_mouse_mode", Input.mouse_mode)
	gameManager.hideMouse()
	await fadeOut()
	hide()
	get_tree().paused = false

func pauseGame()->void:
	show()
	fadeIn()
	resumeButton.focus_mode = 2
	if musicManager.get_all_channels():
		for i in musicManager.get_all_channels():
			musicManager.set_channel_pause(i,true)
	#Dialogic.end_timeline()
	secondSound.play()
	Input.mouse_mode = gameManager.get_meta(&"stored_mouse_mode", Input.MOUSE_MODE_CAPTURED)
	gameManager.showMouse()
	get_tree().paused = true
