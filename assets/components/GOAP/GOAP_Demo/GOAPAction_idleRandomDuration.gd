extends GOAP_Action


func _execute_action() -> void:
	super()
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	if action_busy:
		await finish_action()
		action_completed.emit()
