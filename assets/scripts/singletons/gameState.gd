extends Node
##Gamestate
var notes : Dictionary
var saveVersion : float = 1.0
var stateInfo : Dictionary = {}
var _gameState : Dictionary = {
	"saveVersion" : 1.0,
	"stateSave" : {
		"screenshot" = "",
		"saveName" = "",
		"timestamp" = Time.get_unix_time_from_system(),
		"dateDict" = Time.get_date_dict_from_system(),
		"saveLocation" = "gameManager.world.worldData.worldName",
		"saveScene" = "",
		"prologueComplete" = gameManager.get_persistent_data().get("seen_prologue", false),
		"pawninfo" = "",
		"areaStats" = [],
		"pawnRank" = 0,
		"grit" = 0,
		"position" = Vector3.ZERO,
		"skills" = [],
		"ownedProperties" = []
	}
}

func clearStates()->void:
		_gameState.clear()
		stateInfo.clear()

func loadGame(save:String)->void:
	if save != "" or save != null:
		clearStates()
		var saveFile = FileAccess.open(save, FileAccess.READ)
		if saveFile != null:
			Engine.time_scale = 1.0
			get_tree().paused = false
			while saveFile.get_position() < saveFile.get_length():
				var string = saveFile.get_line()
				var json = JSON.new()
				var result = json.parse(string)
				if not result == OK:
					Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%string)
					return
				var nodeData = json.get_data() as Dictionary
				stateInfo = nodeData
				_gameState.get_or_add("stateSave",stateInfo)
				_gameState.get_or_add("saveVersion",saveVersion)
				gameManager.currentSave = save
				gameManager.modify_persistent_data("lastSave", save)
				gameManager.loadWorld(nodeData["saveScene"])
				gameManager.modify_persistent_data("lastSaveData", nodeData)
				#print(get_persistent_data()["lastSaveData"])
				#purchasedPlacables = nodeData["purchasePlacables"]
				#temporaryPawnInfo.clear()
		else:
			Console.add_rich_console_message("[color=red]Unable to find that save![/color]")

func saveGame(saveName : String = "Save1"):
	var saveInfo = _gameState.get_or_add("stateSave",stateInfo)
	if gameManager.world != null:
		# Ensure the saves directory exists
		if not DirAccess.dir_exists_absolute("user://saves"):
			DirAccess.make_dir_absolute("user://saves")
		var saveDir = DirAccess.open("user://saves")
		if saveDir == null:
			push_error("Failed to open user://saves directory.")
			return
		if not saveDir.dir_exists(saveName):
			saveDir.make_dir(saveName)
		var saveFile = FileAccess.open("user://saves/%s/%s.pwnSave" % [saveName, saveName], FileAccess.WRITE)
		gameManager.currentSave = "user://saves/%s/%s.pwnSave" % [saveName, saveName]
		gameManager.activeCamera.hud.hide()
		gameManager.getPauseMenu().hide()
		var screenshot = get_viewport().get_texture().get_image()
		screenshot.save_png("user://saves/%s/%s.png" % [saveName, saveName])
		print("user://saves/%s/%s.png" % [saveName, saveName])
		var pawnFile = gameManager.playerPawns[0].savePawnFile(gameManager.playerPawns[0].savePawnInformation(), "user://saves/%s/%s" % [saveName, saveName])
		stateInfo["saveName"] = saveName
		stateInfo["screenshot"] = "user://saves/%s/%s.png" % [saveName, saveName]
		stateInfo["dateDict"] = Time.get_date_dict_from_system()
		stateInfo["pawninfo"] = pawnFile
		stateInfo["saveLocation"] = gameManager.world.worldData.worldName
		stateInfo["position"] = gameManager.playerPawns[0].global_position
		stateInfo["saveScene"] = get_tree().current_scene.get_scene_file_path()
		stateInfo["prologueComplete"] = gameManager.get_persistent_data().get("seen_prologue", false)
		gameManager.activeCamera.hud.show()
		gameManager.getPauseMenu().show()
		var stringy = JSON.stringify(saveInfo)
		saveFile.store_line(stringy)
		Console.add_rich_console_message("[color=green] Saved game '%s' sucessfully!"%saveName)
		gameManager.modify_persistent_data("lastSaveData", saveInfo)
		gameManager.modify_persistent_data("lastSave", gameManager.currentSave)
		#print(get_persistent_data()["lastSaveData"])
		return saveFile


func addToOwnedProperties(property:String):
	var saveInfo = getGameState()
	if saveInfo["ownedProperties"].has(property): return
	saveInfo["ownedProperties"].append(property)

func addToSkills(skill:String):
	if gameManager.getModifierFromName(skill):
		var saveInfo = getGameState()
		saveInfo["skills"].append({"name":skill,"skill":gameManager.getModifierFromName(skill)})

func addToGamestate()->void:
	var saveInfo = getGameState()
	saveInfo["position"] = gameManager.getCurrentPawn().global_position
	saveInfo["grit"] = getPawnCash()
	saveInfo["weapons"] = gameManager.getCurrentPawn().itemInventory

func addPawnCash(value:int)->int:
	var saveInfo = getGameState()
	saveInfo["grit"] += value
	return saveInfo["grit"]

func AddProperty(id:StringName)->Array:
	var saveInfo = getGameState()
	if !saveInfo["ownedProperties"].has(id):
		saveInfo["ownedProperties"].append(id)
	return saveInfo["ownedProperties"]

func getGameState()->Dictionary:
	return _gameState.get_or_add("stateSave",stateInfo)

func setPawnCash(value:int)->int:
	var saveInfo = getGameState()
	saveInfo["grit"] = value
	return saveInfo["grit"]

func getPawnCash()->int:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("grit",0)

func getPawnSkills()->Array:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("skills",[])

func getPawnLevel()->int:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("pawnRank",0)

func getSaveScene()->String:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("saveScene" ,get_tree().current_scene.get_scene_file_path())

func getPrologueComplete()->bool:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("prologueComplete" ,gameManager.get_persistent_data().get("seen_prologue", false))

func getSaveLocation()->String:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("saveLocation" ,gameManager.world.worldData.worldName)

func getSaveTimestamp()->String:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("timestamp" , Time.get_unix_time_from_system())

func getSaveName()->String:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("saveName", "BlankName")

func getOwnedProperties()->Array:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("ownedProperties", [])

func hasOwnedProperty(id:StringName)->bool:
	var result : bool = false
	var saveInfo = getGameState()
	var properties = saveInfo["ownedProperties"]
	for i in properties:
		if i == id:
			result = true
	return result

func getOwnedProperty(id:StringName)->int:
	var properties = getGameState()
	return properties["ownedProperties"].find(id)

func getSaveDateDict()->Dictionary:
	var saveInfo = getGameState()
	return saveInfo.get_or_add("dateDict", Time.get_date_dict_from_system())

func updateSaveFile(save):
	##Update Old Saves to a new ver
	pass
