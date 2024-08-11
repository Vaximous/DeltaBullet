extends Control
class_name PauseMenu
var fadeSpeed : int = 8
var canPause : bool = true
@onready var soundPlayer : AudioStreamPlayer = $audioStreamPlayer
@onready var secondSound : AudioStreamPlayer = $audioStreamPlayer2
@onready var gradientBG : TextureRect = $gradientBG
@onready var saveLoadMenu : Control = $saveloadmenu
@onready var resumeButton : Button = $buttons/ResumeButton

func _ready() -> void:
	gradientBG.self_modulate = Color.TRANSPARENT
	modulate = Color.TRANSPARENT
	saveLoadMenu.modulate = Color.TRANSPARENT
	hide()

func _process(delta)->void:
	if get_tree().paused:
		modulate = lerp(modulate,Color.WHITE,fadeSpeed*delta)
		gradientBG.self_modulate = lerp(gradientBG.self_modulate,Color.WHITE,fadeSpeed*delta)
	else:
		modulate = Color.TRANSPARENT
		gradientBG.self_modulate = lerp(gradientBG.self_modulate,Color.TRANSPARENT,fadeSpeed*delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		if canPause:
			if Dialogic.current_timeline == null:
				if visible:
					unpauseGame()
				else:
					pauseGame()
			else:
				Dialogic.end_timeline()

func _on_resume_button_pressed()->void:
	unpauseGame()

func _on_menu_button_pressed()->void:
	musicManager.change_song_to(null,0.5)
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://assets/scenes/menu/menu.tscn")

func unpauseGame()->void:
	musicManager.resumeMusic()
	soundPlayer.play()
	gameManager.set_meta(&"stored_mouse_mode", Input.mouse_mode)
	gameManager.hideMouse()
	hide()
	get_tree().paused = false

func pauseGame()->void:
	resumeButton.focus_mode = 2
	musicManager.pauseMusic()
	Dialogic.end_timeline()
	secondSound.play()
	Input.mouse_mode = gameManager.get_meta(&"stored_mouse_mode", Input.MOUSE_MODE_CAPTURED)
	gameManager.showMouse()
	show()
	get_tree().paused = true
