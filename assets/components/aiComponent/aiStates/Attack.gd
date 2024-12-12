extends StateMachineState
@export_category("Attack State")
@export var aiOwner : AIComponent
var shootAt : bool = false
@onready var attackTimer : Timer = $attackTimer
@onready var moveTimer : Timer = $moveTimer

func on_exit():
	attackTimer.stop()
	shootAt = false
	aiOwner.stopLookingAt()
	aiOwner.pawnOwner.freeAim = false
	if aiOwner.pawnOwner.currentItem != null and aiOwner.pawnOwner.currentItem.canReloadWeapon and !aiOwner.pawnOwner.currentItem.isReloading:
			aiOwner.pawnOwner.currentItem.reloadWeapon()

func on_enter()->void:
	aiOwner.pathingToPosition = false
	aiOwner.currentPath.clear()
	if !attackTimer.timeout.is_connected(toggleShooting):
		attackTimer.timeout.connect(toggleShooting)
	attackTimer.wait_time = randf_range(0.05,0.6)
	moveTimer.wait_time = randf_range(1,5)
	attackTimer.start()

func on_physics_process(delta):
	if aiOwner.targetedPawn != null and aiOwner.pawnOwner.currentItem != null and !aiOwner.targetedPawn.isPawnDead:
		#aiOwner.targetedPawn.turnAmount = -aiOwner.aimCast.rotation.x
		if !aiOwner.pawnOwner.freeAim:
			aiOwner.pawnOwner.freeAim = true

		aiOwner.pawnOwner.movementController.onSetCamRot(aiOwner.pawnOwner.meshRotation)
		aiOwner.lookAtPosition(aiOwner.targetedPawn.upperChestBone.global_position)

		if shootAt:
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
