extends Node3D


@export var scene : PackedScene


func instance_scene(parent : Node = null) -> Node:
	if parent == null:
		if gameManager.world != null:
			parent = gameManager.world
		else:
			parent = get_tree().current_scene

	var instance = scene.instantiate()

	parent.add_child(instance)
	if instance is Node3D:
		instance.global_transform = global_transform
	return instance
