extends Button
@onready var selectSound : AudioStreamPlayer = $selectSound
@onready var hoverSound : AudioStreamPlayer = $audioStreamPlayer
@onready var background : TextureRect = $background
@onready var saveIcon : TextureRect = $saveIcon
@onready var saveName : Label = $saveName
@onready var saveLocation : Label = $saveLocation
@onready var saveTimestamp : Label = $saveTimestamp
var sceneLoad : String
@export_enum("Load","CreateSave","Save") var buttonType : int = 0:
	set(value):
		buttonType = value
		if buttonType == 1:
			saveIcon.texture = load(["res://assets/misc/db7.png","res://assets/scenes/ui/saveloadmenu/save1.png","res://assets/scenes/ui/saveloadmenu/save2.png","res://assets/scenes/ui/saveloadmenu/save3.png","res://assets/scenes/ui/saveloadmenu/save4.png"].pick_random())
			saveName.text = "Create New Save"
			saveLocation.text = ""
			saveTimestamp.text = ""
			%removeSave.hide()
var saveFile:
	set(value):
		saveFile = value

func _ready()->void:
	hoverOff()

func parseData(data:String)->void:
	var imgicon = Image.new()
	var imgtexture = ImageTexture.new()
	var saveData = FileAccess.open(data,FileAccess.READ)
	if saveData != null:
		while saveData.get_position() < saveData.get_length():
			var string = saveData.get_line()
			var json = JSON.new()
			var result = json.parse(string)
			if not result == OK:
				Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%string)
				return
			var jsonData : Dictionary = json.get_data()
			var date = jsonData["dateDict"]
			saveTimestamp.text = "%d/%02d/%02d" % [date.month, date.day, date.year]
			saveName.text = jsonData["saveName"]
			imgicon.load(jsonData["screenshot"])
			imgtexture.set_image(imgicon)
			saveIcon.texture = imgtexture
			saveLocation.text = jsonData["saveLocation"]
			sceneLoad = jsonData["saveScene"]

func hoverOn()->void:
	hoverSound.play()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background,"size",Vector2(615,152),0.25)

func hoverOff()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(background,"size",Vector2(256,152),0.25)

func _on_pressed()->void:
	if selectSound.playing != true:
		selectSound.play()
		hoverSound.stop()
	match buttonType:
		0:
			gameManager.playSound(gameManager.getGlobalSound("startGame"), -10)
			gameManager.removeAllDeathScreens()
			gameManager.removeCustomization()
			gameManager.removeShop()
			gameManager.removeWorldMap()
			await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
			#gameManager.notifyCheck("'%s' Sucessfully Loaded."%saveName.text, 2, 1.5)
			gameState.loadGame(saveFile)
			gameManager.clearTemporaryPawnInfo()
		2:
			gameManager.getEventSignal("overwriteSave").emit()
			gameManager.saveOverwrite = saveName.text

func startRemoveSave()->void:
		gameManager.saveOverwrite = saveName.text
		gameManager.getEventSignal("removeSave").emit()
