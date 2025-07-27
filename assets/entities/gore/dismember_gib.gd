extends FakePhysicsEntity

func _ready() -> void:
	super()
	rotation = Vector3(randf_range(-360,360),randf_range(-360,360),randf_range(-360,360))
	get_tree().create_timer(UserConfig.game_decal_remove_time).timeout.connect(queue_free)

func _on_bounced() -> void:
	var splat = gameManager.createSplat(global_position,colNormal)
	%bloodSpurt.restart()
