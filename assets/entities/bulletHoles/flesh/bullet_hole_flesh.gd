extends BulletHole


func _on_bullet_hole_emitted() -> void:
	gameManager.sprayBlood(global_position,randi_range(1,2),5,randf_range(1.0,1.7))
