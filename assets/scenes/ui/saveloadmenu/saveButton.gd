extends Button
@onready var background : TextureRect = $background
@onready var saveIcon : TextureRect = $saveIcon
@onready var saveName : Label = $saveName
@onready var saveLocation : Label = $saveLocation
@onready var saveTimestamp : Label = $saveTimestamp
var sceneLoad : String
@export_enum("Save","CreateSave") var buttonType : int = 0
var saveFile:
	set(value):
		saveFile = value

func parseData(data:String)->void:
	var saveData = FileAccess.open(data,FileAccess.READ)
	if saveData != null:
		while saveData.get_position() < saveData.get_length():
			var string = saveData.get_line()
			var json = JSON.new()
			var result = json.parse(string)
			if not result == OK:
				Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%string)
				return
			var jsonData = json.get_data()
			saveName.text = jsonData["saveName"]
			saveIcon.texture = load(jsonData["saveScreenie"])
			saveLocation.text = jsonData["saveLocation"]
			sceneLoad = jsonData["scene"]


func _on_pressed()->void:
	match buttonType:
		0:
			gameManager.loadGame(saveFile)
		1:
			pass
