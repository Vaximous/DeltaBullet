extends Node
##Gamestate
var notes : Dictionary
var gameState : Dictionary = {
	"saveVersion" : 1.0,
	"stateSave" : "",
	"pawn" : ""
}

func loadGame()->void:
	pass

func saveGame()->void:
	pass


func updateSaveFile(save):
	##Update Old Saves to a new ver
	pass
