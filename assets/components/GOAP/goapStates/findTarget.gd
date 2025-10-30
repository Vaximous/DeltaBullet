extends GOAP_Action

var couldntFind : bool = false
var lastSearchPoint : Vector3

#Will search for a couple seconds
var searchStartTime : int
func _count_requirements() -> int:
	var req : int = 0
	if not blackboard.has("targetLastSeenPosition"):
		req += 10
		return req
	if couldntFind and lastSearchPoint.distance_to(getNavAgent().target_position) < 5.0 and not blackboard.has("targetLastSeenPosition"):
		return 100
	if blackboard.get("currentItem") == null:
		req += 1
	var target = getTargetEnemy()
	if !target:
		req += 1
	return req

func _enter() -> void:
	#Notifications.send_notification("Hunting...")
	couldntFind = false
	searchStartTime = Time.get_ticks_msec()
	var nav := getNavAgent()
	nav.target_position = NavigationServer3D.map_get_closest_point(nav.get_navigation_map(), blackboard["targetLastSeenPosition"])
	lastSearchPoint = nav.target_position
	aiComponent.stopLookingAt()
	return

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
	#Hunt for the target using the last known position
	var nav := getNavAgent()
	var target := getTargetEnemy()
	if target:
		var cansee = isSightToTargetBlocked()
		if !cansee:
			goal_request_repath = true
			return

	if lastSearchPoint.distance_to(getNavAgent().target_position) < 3.0:
		aiComponent.switchToSprint()
	else:
		aiComponent.switchToWalk()

	if nav.is_navigation_finished():
		couldntFind = true
		blackboard.erase("targetLastSeenPosition")
		goal_request_repath = true
		return
	return



func _refresh() -> void:
	super()
	couldntFind = false
