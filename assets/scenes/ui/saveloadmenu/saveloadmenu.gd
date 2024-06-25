extends Control
@onready var panelLabel : Label = $panel/textureRect/label


func initSavePanel()->void:
	panelLabel.text = "Choose Save"

func initLoadPanel()->void:
	panelLabel.text = "Load Save"
