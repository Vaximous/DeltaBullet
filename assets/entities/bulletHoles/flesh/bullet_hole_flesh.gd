extends BulletHole


func _on_bullet_hole_emitted() -> void:
	%gush1.play("gush1")
	%gush2.play("gush2")
	%gush3.play("gush3")
	gameManager.sprayBlood(global_position,randi_range(1,2),5,randf_range(1.0,1.7))
