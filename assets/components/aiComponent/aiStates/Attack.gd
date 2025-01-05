extends StateMachineState
@export_category("Attack State")
@export var aiOwner : AIComponent
var shootAt : bool = false
var tgtDistance : float
var maxDistance : float = 5.0
var minDistance : float = 2.0
var targetPosition : Vector3 = Vector3.ZERO:
	set(value):
		if !aiOwner.pathingToPosition and is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
			targetPosition = value
			if is_current_state():
				var rand : Array = [true,false]
				if tgtDistance>=maxDistance or isSightToTargetBlocked():
					aiOwner.pathPoint = 0
					aiOwner.currentPath.clear()
					aiOwner.goToPosition(targetPosition, rand.pick_random())
				elif tgtDistance<=minDistance:
					aiOwner.pathPoint = 0
					aiOwner.currentPath.clear()
					aiOwner.goToPosition(-targetPosition, rand.pick_random())
@onready var attackTimer : Timer = $attackTimer
@onready var moveTimer : Timer = $moveTimer

func on_exit():
	attackTimer.stop()
	shootAt = false
	aiOwner.stopLookingAt()
	aiOwner.pawnOwner.freeAim = false
	aiOwner.pathingToPosition = false
	aiOwner.currentPath.clear()
	if aiOwner.pawnOwner.currentItem != null and aiOwner.pawnOwner.currentItem.canReloadWeapon and !aiOwner.pawnOwner.currentItem.isReloading:
			aiOwner.pawnOwner.currentItem.reloadWeapon()

			if aiOwner.pawnOwner.currentItem.isAiming:
				aiOwner.pawnOwner.currentItem.isAiming = false


func on_enter()->void:
	aiOwner.pathingToPosition = false
	aiOwner.currentPath.clear()
	if !attackTimer.timeout.is_connected(toggleShooting):
		attackTimer.timeout.connect(toggleShooting)
	attackTimer.wait_time = randf_range(0.05,0.2)
	moveTimer.wait_time = randf_range(1,5)
	attackTimer.start()

func isSightToTargetBlocked()->bool:
	var result = aiOwner.rayTest(Vector3(aiOwner.pawnOwner.global_position.x,aiOwner.pawnOwner.global_position.y + 1,aiOwner.pawnOwner.global_position.z),aiOwner.targetedPawn.upperChestBone.global_position)
	if result:
		return true
	else:
		return false

func on_ai_process(phys_delta : float, ai_delta : float):
	if aiOwner.targetedPawn != null and aiOwner.pawnOwner.currentItem != null and !aiOwner.targetedPawn.isPawnDead and is_instance_valid(aiOwner.targetedPawn) and aiOwner.is_ai_processing():
		#aiOwner.targetedPawn.turnAmount = -aiOwner.aimCast.rotation.x
		tgtDistance = Vector3(aiOwner.pawnOwner.global_position.x,0,aiOwner.pawnOwner.global_position.z).distance_to(Vector3(aiOwner.targetedPawn.global_position.x,0,aiOwner.targetedPawn.global_position.z))


		if tgtDistance >= maxDistance or isSightToTargetBlocked() or tgtDistance<=minDistance:
			if !aiOwner.pathingToPosition:
				aiOwner.pathPoint = 0
				targetPosition = Vector3(aiOwner.targetedPawn.global_position.x,aiOwner.targetedPawn.global_position.y+0.05,aiOwner.targetedPawn.global_position.z)
		#else:
			#if aiOwner.pathingToPosition:
				#aiOwner.pathingToPosition = false

		if !aiOwner.pawnOwner.currentItem.isAiming:
			if !isSightToTargetBlocked():
				aiOwner.pawnOwner.currentItem.isAiming = true
			else:
				aiOwner.pawnOwner.currentItem.isAiming = false
			#aiOwner.pawnOwner.freeAim = true

		aiOwner.pawnOwner.movementController.onSetCamRot(aiOwner.pawnOwner.meshRotation)
		aiOwner.lookAtPosition(aiOwner.targetedPawn.upperChestBone.global_position + aiOwner.targetedPawn.velocity * 0.1 )

		if shootAt and !isSightToTargetBlocked():
			aiOwner.pawnOwner.currentItem.fire()

		if aiOwner.pawnOwner.currentItem.currentAmmo <= 0 and !aiOwner.pawnOwner.currentItem.isFiring and aiOwner.pawnOwner.currentItem.canReloadWeapon and !aiOwner.pawnOwner.currentItem.isReloading :
			aiOwner.pawnOwner.currentItem.reloadWeapon()
	else:
		aiOwner.pawnFSM.change_state("Wander")


func toggleShooting()->void:
	if shootAt:
		shootAt = false
	else:
		shootAt = true
