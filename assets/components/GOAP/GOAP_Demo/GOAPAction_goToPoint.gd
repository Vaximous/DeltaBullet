extends GOAP_Action


@export var tgt_pos : Sprite2D
var target_point : Vector2


func _execute_action() -> void:
	super()
	while !is_at_tgt_point() and action_busy:
		goal.root_node.global_position = goal.root_node.global_position.move_toward(tgt_pos.global_position, get_process_delta_time() * 200.0)
		await get_tree().process_frame
	if action_busy:
		finish_action()
		action_completed.emit()


func is_at_tgt_point() -> bool:
	return goal.root_node.global_position.is_equal_approx(tgt_pos.global_position)
