extends Node3D


func _onClosetUsed(user: Variant) -> void:
	gameManager.initCustomization(user)
