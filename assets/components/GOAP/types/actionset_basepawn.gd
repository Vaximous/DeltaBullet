extends RefCounted

static func get_target_pawn(blackboard : Dictionary) -> BasePawn:
	return blackboard.get_or_add("target_pawn", blackboard.get("close_enemy_pawn", null))


static func get_active_pawn(blackboard : Dictionary) -> BasePawn:
	return blackboard.get("active_pawn", null)


static func get_distance_to_target(blackboard : Dictionary) -> float:
	return get_target_pawn(blackboard).global_position.distance_to(get_active_pawn(blackboard).global_position)
