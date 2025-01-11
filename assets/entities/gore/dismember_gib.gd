extends FakePhysicsEntity

func _on_bounced() -> void:
	%bloodSpurt.restart()
	var splat = gameManager.createSplat(global_position,colNormal)
