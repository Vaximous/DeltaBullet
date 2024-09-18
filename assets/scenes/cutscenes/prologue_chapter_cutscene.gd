extends Node


@onready var animation_player : AnimationPlayer = $animationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play(&"cutscene")
	await animation_player.animation_finished
	await get_tree().create_timer(3.0).timeout
	var data = gameManager.get_persistent_data()
	data["seen_prologue"] = true
	gameManager.write_persistent_data(data)
	get_tree().change_scene_to_file("res://assets/scenes/menu/logo.tscn")
