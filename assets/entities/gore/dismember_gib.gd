extends FakePhysicsEntity

var decalTimer: float = 0.5


func _ready() -> void:
	super()
	rotation = Vector3(randf_range(-360, 360), randf_range(-360, 360), randf_range(-360, 360))
	get_tree().create_timer(UserConfig.game_decal_remove_time).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	super(delta)
	if Engine.get_physics_frames() % 2 == 0:
		if decalTimer > 0:
			decalTimer -= delta
		if decalTimer <= 0:
			decalTimer = 0


func _on_bounced() -> void:
	if decalTimer > 0:
		var splat = gameManager.createSplat(global_position, colNormal)
		%bloodSpurt.restart()
		decalTimer = 0.5
