extends Control
@onready var panelLabel : Label = $panel/textureRect/label
@onready var overridePanel : Panel = $panel/overwritePanel
@onready var saveContainer : VBoxContainer = $panel/saveContainer
var saveArray : Array = []

func initSavePanel()->void:
	showPanel()
	scanSaves()
	panelLabel.text = "Choose Save"

func initLoadPanel()->void:
	scanSaves()
	showPanel()
	panelLabel.text = "Load Save"

func scanSaves()->void:
	saveArray.clear()
	for saves in saveContainer.get_children():
		saves.queue_free()
	var saveButton = load("res://assets/scenes/ui/saveloadmenu/saveButton.tscn")
	var savesArray = gameManager.scanForSaves("user://saves/")
	for save in savesArray:
		if save.get_extension() == "pwnSave":
			var _save = saveButton.instantiate()
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
	hide()

func showOverridePanel():
	overridePanel.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overridePanel,"modulate",Color(1,1,1,1),0.3)
