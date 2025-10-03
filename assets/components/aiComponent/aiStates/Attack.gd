extends StateMachineState

@export_category("Attack State")
@export var aiOwner: AIComponent

## The target the enemy will actively attack
var nearestTarget: BasePawn
var lastKnownPosition: Vector3
var lostTarget: bool = false
var targetPosition: Vector3 = Vector3.ZERO:
	set(value):
		if is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
			targetPosition = value
			if aiOwner.targetPosition != targetPosition:
				aiOwner.targetPosition = targetPosition
				lastKnownPosition = Vector3(targetPosition.x, targetPosition.y + 1.25, targetPosition.z)


func on_physics_process(_delta):
	if !is_current_state() or aiOwner.pawnOwner.isPawnDead or aiOwner.pawnOwner.isStaggered: return
	super(_delta)

	#Check if has a target(s)
	if aiOwner.targetedPawns.is_empty():
		aiOwner.setPawnType()
		return

	## Get the nearest pawn(s) if there are any
	for i in aiOwner.targetedPawns:

		if !is_instance_valid(i) or i.isPawnDead:
			if nearestTarget == i:
				nearestTarget = null

			aiOwner.targetedPawns.erase(i)
			aiOwner.pawnOwner.meshLookAt = false
			aiOwner.pawnOwner.freeAim = false
			aiOwner.pawnOwner.isCrouching = false
			aiOwner.pawnOwner.isRunning = false
			aiOwner.setPawnType()
			return

		if not nearestTarget and !i.isPawnDead:
			nearestTarget = i
		else:
			if nearestTarget.global_position.distance_to(aiOwner.pawnOwner.global_position) > i.global_position.distance_to(aiOwner.pawnOwner.global_position):
				nearestTarget = i

		aiOwner.pawnOwner.movementController.onSetCamRot(aiOwner.pawnOwner.meshRotation)
		## Once it has its nearest target, it can begin to aim and attack if its in a range.
		if nearestTarget and !nearestTarget.isPawnDead:

			##Check if its aiming, if not. Make it aim and look towards the enemy.
			if !aiOwner.pawnOwner.freeAim:
				aiOwner.pawnOwner.freeAim = true

			#if aiOwner.getCurrentWeapon():
				#aiOwner.getCurrentWeapon().isAiming = true

			##Look at the target if it can see the target
			if !isSightToTargetBlocked(Vector3(nearestTarget.global_position.x, nearestTarget.global_position.y + 1.5, nearestTarget.global_position.z)):
				if !nearestTarget.global_position.distance_to(aiOwner.pawnOwner.global_position) > aiOwner.maxRange:
					lostTarget = false
					lastKnownPosition = Vector3(nearestTarget.global_position.x, nearestTarget.global_position.y + 1.5, nearestTarget.global_position.z)
					aiOwner.pawnOwner.movementController.onSetCamRot(aiOwner.pawnOwner.meshRotation)
					aiOwner.lookAtPosition(Vector3(nearestTarget.upperChestBone.global_position.x, nearestTarget.upperChestBone.global_position.y, nearestTarget.upperChestBone.global_position.z))
				else:
					aiOwner.lookAtPosition(lastKnownPosition)
			else:
				#print("Cant see target!")
				lostTarget = true
				aiOwner.lookAtPosition(lastKnownPosition)

			##If the target is within the max range, start shooting
			if nearestTarget.global_position.distance_to(aiOwner.pawnOwner.global_position) <= aiOwner.maxAttackRange and aiOwner.canSeeObject(nearestTarget.upperChestBone):
				if aiOwner.getCurrentWeapon() and !aiOwner.pawnOwner.isStaggered and aiOwner.canSeeObject(nearestTarget) and aiOwner.getCurrentWeapon().currentAmmo > 0:
					aiOwner.getCurrentWeapon().weaponCast = aiOwner.aimCast
					aiOwner.getCurrentWeapon().fire()
					#aiOwner.stopMoving()

				##Check if needs to reload
				if aiOwner.getCurrentWeapon() and !aiOwner.pawnOwner.isStaggered and aiOwner.getCurrentWeapon().currentAmmo <= 0 and !aiOwner.getCurrentWeapon().isReloading and !aiOwner.getCurrentWeapon().isFiring and aiOwner.getCurrentWeapon().currentMagSize > 0:
					aiOwner.getCurrentWeapon().reloadWeapon()

			##Pawn seeking, would get closer if out of range
			if nearestTarget.global_position.distance_to(aiOwner.pawnOwner.global_position) > aiOwner.maxRange and !lostTarget:
				targetPosition = nearestTarget.global_position
				aiOwner.pawnOwner.isRunning = false
			#elif lostTarget:
				#if lastKnownPosition != Vector3.ZERO and !aiOwner.pawnOwner.global_position.is_equal_approx(lastKnownPosition):
					#targetPosition = lastKnownPosition
				#else:
					#aiOwner.stopMoving()
					#returnToPreviousState()
			else:
				targetPosition = nearestTarget.global_position
				#aiOwner.pawnOwner.isRunning = true
			#else:
				#aiOwner.stopMoving()

			#aiOwner.aimCast.rotation = aiOwner.aimCast.rotation.direction_to(nearestTarget.global_position)
			#aiOwner.pawnOwner.movementController.onSetCamRot(aiOwner.aimCast.global_transform.basis.get_euler().y)
			#aiOwner.pawnOwner.meshRotation = aiOwner.aimCast.global_transform.basis.get_euler().y


func isSightToTargetBlocked(position: Vector3) -> bool:
	var result = aiOwner.rayTest(aiOwner.pawnOwner.global_position, position)
	if result:
		return true
	else:
		return false


func returnToPreviousState() -> void:
	aiOwner.stopMoving()
	aiOwner.setPawnType()

	if aiOwner.pawnOwner.meshLookAt:
		aiOwner.pawnOwner.meshLookAt = false

	if aiOwner.pawnOwner.freeAim:
		aiOwner.pawnOwner.freeAim = false

	aiOwner.pawnOwner.isRunning = false
