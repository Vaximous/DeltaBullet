extends GOAP_Action


var target_position


func _execute_action() -> void:
	super()
	target_position = goal.root_node.global_position + Vector2(randf() - 0.5, randf() - 0.5).normalized() * 50.0
	while !is_at_tgt_point() and action_busy:
		goal.root_node.global_position = goal.root_node.global_position.move_toward(target_position, get_process_delta_time() * 500.0)
		await get_tree().process_frame
	await finish_action()
	action_completed.emit()



func is_at_tgt_point() -> bool:
	return goal.root_node.global_position.is_equal_approx(target_position)
