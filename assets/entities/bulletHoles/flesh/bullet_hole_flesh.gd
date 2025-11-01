extends BulletHole


func _on_bullet_hole_emitted() -> void:
	var spurts = [%bloodSpurt, %bloodSpurtBigSpray]
	spurts.pick_random().play()
	for i in randi_range(4, 8):
		gameManager.createDroplet(
			global_position,
			Vector3(bulletVelocity.x + randf_range(-5.5, 5.5), bulletVelocity.y + randf_range(-5.5, 5.5), bulletVelocity.y + randf_range(-5.5, 5.5)) * randf_range(1.25, 6.5), randi_range(0, 2),
			Vector3.DOWN,
			false
		)
