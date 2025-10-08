extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#gameManager.preloadAllMaterials()
	if has_seen_prologue(): get_tree().change_scene_to_file("res://assets/scenes/menu/logo.tscn")
	else:
		get_tree().change_scene_to_file("res://assets/scenes/cutscenes/PrologueChapterCutscene.tscn")


func has_seen_prologue() -> bool:
	var data : Dictionary = gameManager.get_persistent_data()["lastSaveData"]
	return data.get_or_add("prologueComplete",false)
