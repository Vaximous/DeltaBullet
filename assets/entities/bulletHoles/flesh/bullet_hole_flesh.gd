extends BulletHole


func _on_bullet_hole_emitted() -> void:
	%gush1.play("gush1")
	%gush2.play("gush2")
	%gush3.play("gush3")
	gameManager.createDroplet(global_position,bulletVelocity * randf_range(0.25,0.5),randi_range(1,4))
