extends BulletHole


func _on_bullet_hole_emitted() -> void:
	%gush1.play("gush1")
	%gush2.play("gush2")
	%gush3.play("gush3")
	for i in randi_range(1,8):
		gameManager.createDroplet(global_position,bulletVelocity * randf_range(1.25,3.5),randi_range(0,2))
