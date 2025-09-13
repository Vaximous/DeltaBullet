extends Node
##Gamestate
var notes : Dictionary
var _gameState : Dictionary = {
	"saveVersion" : 1.0,
	"stateSave" : {
		"grit" = 0,
		"position" = Vector3.ZERO
	},
	"Skills": []
}

func loadGame()->void:
	pass

func saveGame()->void:
	pass

func addToGamestate()->void:
	var saveInfo = _gameState.get_or_add("stateSave","stateSave")
	saveInfo["position"] = gameManager.getCurrentPawn().global_position
	saveInfo["grit"] = getPawnCash()
	saveInfo["weapons"] = gameManager.getCurrentPawn().itemInventory

func addPawnCash(value:int)->int:
	var saveInfo = _gameState.get_or_add("stateSave","stateSave")
	saveInfo["grit"] += value
	return saveInfo["grit"]

func setPawnCash(value:int)->int:
	var saveInfo = _gameState.get_or_add("stateSave","stateSave")
	saveInfo["grit"] = value
	return saveInfo["grit"]

func getPawnCash()->int:
	var saveInfo = _gameState.get_or_add("stateSave","stateSave")
	return saveInfo["grit"]

func updateSaveFile(save):
	##Update Old Saves to a new ver
	pass
