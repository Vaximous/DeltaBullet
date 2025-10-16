extends Control
@onready var gameLogo : TextureRect = $gameLogo
@onready var verSeperator : HSeparator = $verSep
@onready var versionLabel : Label = $versionLabel
@onready var optionsMenu : Control = $Options
@onready var buttonHolder : VBoxContainer = $buttonHolder
var anykey = false
var pressed = false
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	gameManager.getEventSignal("refreshCurrSave").connect(continueCheck)
	SmackneckClient.Authentication.auth_success.connect(%smacknetConnect.hide)
	gameManager.clearTemporaryPawnInfo()
	versionLabel.text = ProjectSettings.get_setting("application/config/version")
	continueCheck()

func _process(delta)->void:
	if optionsMenu.visible:
		gameLogo.modulate = lerp(gameLogo.modulate,Color(1, 1, 1, 0),12*delta)
		versionLabel.modulate = lerp(versionLabel.modulate,Color(1, 1, 1, 0),12*delta)
		buttonHolder.modulate = lerp(buttonHolder.modulate,Color(1, 1, 1, 0),12*delta)
		verSeperator.modulate = lerp(versionLabel.modulate,Color(1, 1, 1, 0),12*delta)
	else:
		gameLogo.modulate = lerp(gameLogo.modulate,Color(1, 1, 1, 1),12*delta)
		verSeperator.modulate = lerp(verSeperator.modulate,Color(1, 1, 1, 1),12*delta)
		versionLabel.modulate = lerp(versionLabel.modulate,Color(1, 1, 1, 1),12*delta)
		buttonHolder.modulate = lerp(buttonHolder.modulate,Color(1, 1, 1, 1),12*delta)

func _on_play_button_pressed()->void:
	gameManager.playSound(gameManager.getGlobalSound("startGame"), -15)
	gameManager.clearTemporaryPawnInfo()
	gameManager.currentSave = ""
	gameState.clearStates()
	musicManager.change_song_to(null,0.5)
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	gameManager.loadWorld("res://assets/scenes/worlds/areas/playerHome/playerHome.tscn")

func _on_quit_button_pressed()->void:
	await Fade.fade_out(0.4, Color(0,0,0,1),"GradientVertical",false,true).finished
	get_tree().quit()

func _on_options_button_pressed()->void:
	optionsMenu.show()

func _on_credits_button_pressed()->void:
	gameManager.notify_warn("Not yet implemented.", 2, 10)

func _on_continue_button_pressed() -> void:
	gameManager.playSound(gameManager.getGlobalSound("startGame"), -15)
	gameManager.clearTemporaryPawnInfo()
	gameManager.currentSave = gameManager.get_persistent_data()["lastSave"]
	musicManager.change_song_to(null,0.5)
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	gameState.loadGame(gameManager.get_persistent_data()["lastSave"])

func continueCheck()->void:
	if checkCurrentSaveExists():
		%continueButton.show()
	else:
		%continueButton.hide()

func checkCurrentSave():
	return gameManager.get_persistent_data().has("lastSave")

func checkCurrentSaveExists()->bool:
	if checkCurrentSave():
		return Util.doesFileExist(gameManager.get_persistent_data().get_or_add("lastSave",null))
	return false

func _on_smacknet_connect_pressed() -> void:
	if !%LoginScreen.visible:
		%LoginScreen.show()
