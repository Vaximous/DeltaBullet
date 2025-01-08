extends FakePhysicsEntity

func _on_bounced() -> void:
	%bloodSpurt.restart()
	gameManager.createSplat(global_position,colNormal)
