extends Node


@onready var animation_player : AnimationPlayer = $animationPlayer


@export var audio_bus_layout : AudioBusLayout


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioServer.set_bus_layout(audio_bus_layout)
	animation_player.play(&"cutscene")
	await animation_player.animation_finished
	await get_tree().create_timer(3.0).timeout
	gameManager.modify_persistent_data("seen_prologue", true)
	AudioServer.set_bus_layout(load("res://default_bus_layout.tres"))
	get_tree().change_scene_to_file("res://assets/scenes/menu/logo.tscn")
