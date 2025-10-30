extends GOAP_Action

func _count_requirements() -> int:
	if !blackboard.has_all(["targetLastSeenPosition"]):
		return 0
	return 669699


func _enter() -> void:
	if aiComponent:
		aiComponent.stopLookingAt()
	var navAgent := getNavAgent()
	var point = getRandomNavPoints().global_position
	navAgent.target_position = point

func isSightToTargetBlocked()->bool:
	var result
	if getTargetEnemy() is BasePawn:
		result = aiComponent.rayTest(Vector3(getCurrentPawn().global_position.x,getCurrentPawn().global_position.y + 1,getCurrentPawn().global_position.z),getTargetEnemy().upperChestBone.global_position)
	else:
		result = aiComponent.rayTest(Vector3(getCurrentPawn().global_position.x,getCurrentPawn().global_position.y + 1,getCurrentPawn().global_position.z),getTargetEnemy().global_position)
	if result:
		return true
	else:
		return false

func process_action() -> void:
	#don't do anything at all
	var nav := getNavAgent()
	var target := getTargetEnemy()
	if target:
		var cansee = isSightToTargetBlocked()
		if !cansee:
			goal_request_repath = true
			blackboard["targetLastSeenPosition"] = target.global_position
			return
	blackboard["lookTarget"] = lerp(blackboard.get("lookTarget", Vector3.ZERO), blackboard.get("nextPathPosition", Vector3.ZERO) + Vector3.UP, 0.25)


	if randi()%10 == 0:
		goal_request_repath = true
	if nav.is_navigation_finished() or randi()%200 == 0:
		if getTargetEnemy() != null:
			var point = blackboard["targetLastSeenPosition"]
			nav.target_position = point
	return

func getRandomNavPoints()->AIMarker:
	if gameManager.world:
		return gameManager.world.getWaypoints(0).pick_random()
	else:
		return null
