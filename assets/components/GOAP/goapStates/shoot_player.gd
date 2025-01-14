extends GOAP_Action
var iter : int = 0
#Requires line-of-sight
func count_requirements() -> int:
	var req : int = 0
	if blackboard.get("currentItem") == null:
		#Doesn't have a weapon, need to equip...
		req += 10
	var target := getTargetEnemy()
	if target:
		var cansee = isSightToTargetBlocked()
		if !cansee:
			blackboard["targetLastSeenPosition"] = target.global_position
		else:
			req += 10
	else:
		#No target, 2 requirements (target + sight) missing
		req += 2
	return req


func process_action() -> void:
	#Shoot at the target
	var target := getTargetEnemy()
	if target:
		var cansee = isSightToTargetBlocked()
		if !cansee:
			blackboard["targetLastSeenPosition"] = target.global_position
		else:
			goal_request_repath = true
			return
	#blackboard["look_target"] = get_target_enemy().global_position + (get_target_enemy().velocity * get_physics_process_delta_time())

	if !isSightToTargetBlocked():
		if target != null:
			if target is BasePawn:
				aiComponent.lookAtPosition(target.upperChestBone.global_position + target.velocity * 0.1)
			else:
				aiComponent.lookAtPosition(target.global_position)

			if blackboard.get("currentItem") != null:
				blackboard.get("currentItem").fire()

			##If AI needs to reload
			if blackboard["currentItem"].currentAmmo <= 0 and !blackboard["currentItem"].isFiring and blackboard["currentItem"].canReloadWeapon and !blackboard["currentItem"].isReloading:
				blackboard["currentItem"].reloadWeapon()

			#Set Rotation
			blackboard["pawn"].movementController.onSetCamRot(blackboard["pawn"].meshRotation)

		else:
			aiComponent.stopLookingAt()
	else:
		aiComponent.stopLookingAt()

	if getNavAgent().is_navigation_finished() or randi()%64 == 0:
		if getTargetEnemy() != null:
			getNavAgent().target_position = getTargetEnemy().global_position
	return


func _enter() -> void:
	iter += 1
	#Notifications.send_notification("Target spotted.")


func isSightToTargetBlocked()->bool:
	if getTargetEnemy() != null:
		var result
		if getTargetEnemy() is BasePawn:
			result = aiComponent.rayTest(Vector3(getCurrentPawn().global_position.x,getCurrentPawn().global_position.y + 1,getCurrentPawn().global_position.z),getTargetEnemy().upperChestBone.global_position)
		else:
			result = aiComponent.rayTest(Vector3(getCurrentPawn().global_position.x,getCurrentPawn().global_position.y + 1,getCurrentPawn().global_position.z),getTargetEnemy().global_position)
		if result:
			return true
		else:
			return false
	else:
		return false

func _exit() -> void:
	#Track after a second
	var iterbefore : int = iter
	var known_pos : Vector3
	if getTargetEnemy() is BasePawn and getTargetEnemy() != null:
		known_pos  = getTargetEnemy().upperChestBone.global_position

	if getTargetEnemy() != null:
		while getTargetEnemy().global_position.distance_to(known_pos) < 8.0 and getTargetEnemy() != null:
			await get_tree().create_timer(1.0).timeout
			if iterbefore == iter:
				#Notifications.send_notification("I still know where you are...")
				if getTargetEnemy() != null:
					blackboard["targetLastSeenPosition"] = getTargetEnemy().global_position
				getNavAgent().target_position = blackboard["targetLastSeenPosition"]
