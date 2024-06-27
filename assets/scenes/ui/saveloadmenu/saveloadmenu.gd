extends Control
@onready var panelLabel : Label = $panel/textureRect/label
@onready var overridePanel : Panel = $panel/overwritePanel
@onready var saveContainer : VBoxContainer = $panel/scrollContainer/saveContainer
@onready var saveNamePanel : Panel = $panel/saveNamePanel
@onready var saveName : TextEdit = $panel/saveNamePanel/textEdit

func _unhandled_input(event):
	if Input.is_key_pressed(KEY_ENTER) and saveName.focus_mode == 1:
		saveGame()

func _ready()->void:
	clearSaves()
	hidePanel()

func initSavePanel()->void:
	clearSaves()
	var saveButton = load("res://assets/scenes/ui/saveloadmenu/saveButton.tscn")
	var newSave : Button = saveButton.instantiate()
	saveContainer.add_child(newSave)
	newSave.buttonType = 1
	newSave.pressed.connect(showSaveNamePanel)
	showPanel()
	scanSaves(2)
	panelLabel.text = "Choose Save"

func initLoadPanel()->void:
	clearSaves()
	scanSaves()
	showPanel()
	panelLabel.text = "Load Save"

func clearSaves()->void:
	for saves in saveContainer.get_children():
		saves.queue_free()

func scanSaves(type:int = 0)->void:
	var saveButton = load("res://assets/scenes/ui/saveloadmenu/saveButton.tscn")
	var savesArray = gameManager.scanForSaves("user://saves/")
	for save in savesArray:
		if save.get_extension() == "pwnSave":
			var _save = saveButton.instantiate()
			_save.buttonType = type
			_save.saveFile = save
			saveContainer.add_child(_save)
			_save.parseData(save)

func hidePanel()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	await tween.tween_property(self,"modulate",Color(1,1,1,0),0.25).finished
	hide()

func showPanel()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self,"modulate",Color(1,1,1,1),0.25)

func hideOverridePanel()->void:
	overridePanel.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	await tween.tween_property(overridePanel,"modulate",Color(1,1,1,0),0.3).finished
	overridePanel.hide()

func showOverridePanel()->void:
	overridePanel.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overridePanel,"modulate",Color(1,1,1,1),0.3)

func hideSaveNamePanel()->void:
	saveNamePanel.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	await tween.tween_property(saveNamePanel,"modulate",Color(1,1,1,0),0.3).finished
	saveNamePanel.hide()

func showSaveNamePanel()->void:
	saveNamePanel.visible = true
	saveNamePanel.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(saveNamePanel,"modulate",Color(1,1,1,1),0.3)

func saveGame()->void:
	if saveName.text != "" or saveName.text != " ":
		gameManager.saveGame(saveName.text)
		hideSaveNamePanel()
