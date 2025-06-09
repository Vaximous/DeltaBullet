extends StateMachineState
@export_category("Search State")
var detectionAmount : float = 0.0
var nearestTarget : BasePawn
var targetPosition : Vector3 = Vector3.ZERO:
	set(value):
		if is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
			targetPosition = value
			if aiOwner.targetPosition != targetPosition:
				aiOwner.targetPosition = targetPosition
@export var aiOwner : AIComponent

func on_ai_process(_delta,delta)->void:
	pass

func on_physics_process(_delta):
	if aiOwner.pawnOwner.isPawnDead: return

	if !is_current_state() or aiOwner.pawnsCanSee.is_empty():
		returnToPreviousState()

	if !aiOwner.pawnsCanSee.is_empty():
		for i in aiOwner.pawnsCanSee:
			if !is_instance_valid(i) or i.isPawnDead:
				if nearestTarget == i:
					nearestTarget = null

				returnToPreviousState()
				return

			if not nearestTarget and !i.isPawnDead:
				nearestTarget = i
			else:
				if nearestTarget.global_position.distance_to(aiOwner.pawnOwner.global_position) > i.global_position.distance_to(aiOwner.pawnOwner.global_position):
					nearestTarget = i

	if !nearestTarget: return

	if aiOwner.canSeeObject(nearestTarget) and nearestTarget and aiOwner.pawnOwner.global_position.distance_to(nearestTarget.global_position) < aiOwner.maxDetectionRange:
		detectionAmount += 0.02 * nearestTarget.global_position.distance_to(aiOwner.pawnOwner.global_position) + int(is_instance_valid(nearestTarget.currentItem)) + int(is_instance_valid(nearestTarget.freeAim))
		aiOwner.lookAtPosition(nearestTarget.global_position)
	else:
		detectionAmount -= 0.05
	#print(detectionAmount)

	if detectionAmount >=70:
		targetPosition = nearestTarget.global_position
	else:
		aiOwner.stopMoving()

	if detectionAmount >=50:
		aiOwner.pawnOwner.freeAim = true
	else:
		aiOwner.pawnOwner.freeAim = false

	if detectionAmount >= 100:
		setToAttackState(nearestTarget)
	elif detectionAmount <= 0:
		returnToPreviousState()

func setToAttackState(dealer:BasePawn)->void:
	if !aiOwner.targetedPawns.has(dealer):
		aiOwner.targetedPawns.append(dealer)

	#print("%s is Changing to attack" %pawnOwner.name)
	aiOwner.stateMachine.change_state("Attack")

func returnToPreviousState()->void:
	aiOwner.stopMoving()
	aiOwner.setPawnType()

	if aiOwner.pawnOwner.meshLookAt:
		aiOwner.pawnOwner.meshLookAt = false

	if aiOwner.pawnOwner.freeAim:
		aiOwner.pawnOwner.freeAim = false
