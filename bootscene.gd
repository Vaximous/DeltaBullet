extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#gameManager.preloadAllMaterials()
	if has_seen_prologue():
		get_tree().change_scene_to_file("res://assets/scenes/menu/logo.tscn")
		return
	get_tree().change_scene_to_file("res://assets/scenes/cutscenes/PrologueChapterCutscene.tscn")
	pass # Replace with function body.


func has_seen_prologue() -> bool:
	var data = gameManager.get_persistent_data()
	return data.has("seen_prologue")
