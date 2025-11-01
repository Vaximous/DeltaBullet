class_name InputComponent
extends Component

#Variables
##Enables the movement keys to be emitted
var movementEnabled: bool = true:
	set(value):
		movementEnabled = value
		if !movementEnabled:
			inputDir = Vector3.ZERO
##Enables the mouse action buttons to be emitted
var mouseActionsEnabled: bool = true
var mouseButtonInput: InputEventMouseButton = InputEventMouseButton.new()
var inputDir: Vector3 = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
var controllingPawn: BasePawn


func _ready() -> void:
	InputMap.action_set_deadzone("gLookUp", gameManager.deadzone)
	InputMap.action_set_deadzone("gLookDown", gameManager.deadzone)
	InputMap.action_set_deadzone("gLookLeft", gameManager.deadzone)
	InputMap.action_set_deadzone("gLookRight", gameManager.deadzone)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !is_instance_valid(controllingPawn) or controllingPawn.isPawnDead or !mouseActionsEnabled or !gameManager.isMouseHidden():
		return

	#Distance based pawn node enabling, only works if the input component is attached.
	#This is just for the logic as this would likely be implemented in a better way down the line
	for i in gameManager.allPawns:
		if !i == controllingPawn:
			var enableDist = 20
			var distance = controllingPawn.global_position.distance_to(i.global_position)

			if distance <= enableDist:
				gameManager.enable_pawn(i)
			else:
				gameManager.disable_pawn(i)




	var cam := controllingPawn.attachedCam
	var item := controllingPawn.currentItem
	var rightClick := Input.is_action_pressed("gRightClick")
	var leftClick := Input.is_action_pressed("gLeftClick")
	var throwPressed := Input.is_action_pressed("gThrowThrowable")
	var throwReleased := Input.is_action_just_released("gThrowThrowable")

	if throwPressed:
		_handleThrowPressed(controllingPawn)
	if throwReleased:
		_handleThrowReleased(controllingPawn)
	if rightClick:
		_handleAim(controllingPawn, cam, item)

	if leftClick:
		_handleFire(controllingPawn)

func _input(event: InputEvent) -> void:
	if !is_instance_valid(controllingPawn) or controllingPawn.isPawnDead or !gameManager.isMouseHidden():
		return

	if !mouseActionsEnabled:
		return

	# Mouse wheel inventory cycling
	if event.is_action_pressed("gMwheelUp"):
		_cycleItem(controllingPawn, + 1)
	elif event.is_action_pressed("gMwheelDown"):
		_cycleItem(controllingPawn, -1)

	# One-shot actions
	if event.is_action_pressed("gFlashlight"):
		controllingPawn.toggleFlashlight()

	if event.is_action_pressed("gCrouch"):
		controllingPawn.isCrouching = !controllingPawn.isCrouching

	if event.is_action_pressed("gSafehouseEditor"):
		if gameManager.world.worldData.worldEditable:
			gameManager.initializeSafehouseEditor()

	if event.is_action_pressed("gCover"):
		if controllingPawn.canUseCover:
			controllingPawn.toggleCover()

	if event.is_action_pressed("gToggleCamera"):
		if is_instance_valid(controllingPawn.attachedCam):
			controllingPawn.attachedCam.mirroredCamera = !controllingPawn.attachedCam.mirroredCamera

	if event.is_action_pressed("gJump"):
		if controllingPawn.canJump and !controllingPawn.isUsingPhone:
			controllingPawn.jump()

	if event.is_action_pressed("gBulletTimeToggle"):
		if !controllingPawn.isUsingPhone:
			controllingPawn.toggleBulletTime()

	if event.is_action_pressed("gReloadWeapon"):
		if is_instance_valid(controllingPawn.currentItem) and !controllingPawn.isUsingPhone and controllingPawn.currentItem.canReloadWeapon:
			controllingPawn.currentItem.reloadWeapon()

	if event.is_action_pressed("gUse"):
		_handleUse(controllingPawn)

	if event.is_action_pressed("dKill"):
		_killPlayer(controllingPawn)

	if event.is_action_pressed("gTabMenu"):
		_handleTabMenu(controllingPawn)

	if event.is_action_released("gRightClick"):
		_handleStopAim(controllingPawn)

	# Movement — only update when keyboard event is movement
	if movementEnabled and event is InputEventKey:
		controllingPawn.direction = getInputDir()
		_updateMovementState(controllingPawn)


func getInputDir() -> Vector3:
	if !gameManager.isMouseHidden():
		return Vector3.ZERO
	return Vector3(
		Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"),
		0,
		Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward")
	)


func _handleFire(pawn: BasePawn) -> void:
	var item := pawn.currentItem
	if !is_instance_valid(item):
		return

	if !Input.is_action_pressed("gRightClick"):
		if !pawn.freeAim and (!pawn.isInCover or pawn.peekable):
			pawn.freeAim = true
			controllingPawn.turnAmount = -controllingPawn.attachedCam.vertical.rotation.x

	if pawn.isInCover and !pawn.isPeeking:
		await get_tree().create_timer(0.05).timeout

	item.fire()
	pawn.freeAimTimer.start()
	if pawn.freeAim:
		controllingPawn.turnAmount = -controllingPawn.attachedCam.vertical.rotation.x


func _handleStopAim(pawn: BasePawn) -> void:
	if is_instance_valid(pawn.currentItem):
		pawn.currentItem.isAiming = false

	if !pawn.isArmingThrowable:
		pawn.meshLookAt = false

	pawn.canRun = true

	if pawn.isInCover and pawn.isPeeking and !Input.is_action_pressed("gLeftClick"):
		pawn.meshLookAt = false
		pawn.disableCoverTransition()
		pawn.isPeeking = false


func _handleAim(pawn: BasePawn, cam: Node, item: Node) -> void:
	if !is_instance_valid(cam):
		return

	pawn.turnAmount = -cam.vertical.rotation.x
	pawn.canRun = false

	if !pawn.meshLookAt and !pawn.isInCover:
		pawn.meshLookAt = true

	if is_instance_valid(item):
		if !item.isAiming and (!pawn.isInCover or pawn.peekable):
			item.isAiming = true

	pawn.freeAim = false
	pawn.freeAimTimer.stop()

	# Handle cover peeking
	if pawn.isInCover:
		if pawn.peekable and !pawn.isPeeking:
			pawn.meshLookAt = true
			pawn.disableCoverTransition()
			pawn.peekPos = pawn.global_position
			pawn.isPeeking = true
		elif !pawn.peekable and pawn.isPeeking:
			pawn.isPeeking = false
			pawn.enableCoverTransition()
			pawn.meshLookAt = false
			if is_instance_valid(item):
				if item.isAiming:
					item.isAiming = false


func _handleThrowReleased(pawn: BasePawn) -> void:
	if !is_instance_valid(pawn.heldThrowable):
		return
	pawn.freeAimTimer.start()
	pawn.throwThrowable()


func _handleThrowPressed(pawn: BasePawn) -> void:
	if pawn.throwableAmount <= 0:
		return
	if pawn.isArmingThrowable or pawn.isThrowing or is_instance_valid(pawn.heldThrowable):
		return

	pawn.freeAim = true
	pawn.meshRotation = pawn.attachedCam.camRot
	pawn.armThrowable()

func _cycleItem(pawn: BasePawn, direction: int) -> void:
	var max_index = pawn.itemInventory.size() - 1
	if !is_instance_valid(pawn.healthComponent) or pawn.healthComponent.isDead or pawn.isUsingPhone or (pawn.currentItemIndex + direction) > max_index or (pawn.currentItemIndex + direction) < 0 :
		return
	pawn.currentItemIndex = clamp(pawn.currentItemIndex + direction, 0, max_index)


func _handleTabMenu(pawn: BasePawn) -> void:
	if !pawn.queuedPhoneCall:
		pawn.togglePhone()
	elif !pawn.playingCall:
		pawn.playPhoneCall()
	else:
		pawn.endPhoneCall()

func _handleUse(pawn: BasePawn) -> void:
	var interact_obj = pawn.getInteractionObject()

	if interact_obj is BasePawn:
		interact_obj.inputComponent.interactSpeakTrigger.emit()
	elif interact_obj is InteractiveObject and interact_obj.canBeUsed:
		interact_obj.objectUsed.emit(pawn)

func _killPlayer(pawn: BasePawn) -> void:
	pawn.healthComponent.setHealth(0)
	if is_instance_valid(pawn.attachedCam):
		pawn.attachedCam.fireVignette(0.8, Color.DARK_RED)
	gameManager.notifyFade("You've died! Press F6 to restart!", 4, 5)

func _updateMovementState(pawn: BasePawn) -> void:
	if !pawn.isCurrentlyMoving():
		# Idle states
		if pawn.isCrouching:
			pawn.setMovementState.emit(pawn.movementStates["crouch"])
		elif pawn.isInCover:
			pawn.setMovementState.emit(pawn.movementStates["coveridle"])
		else:
			pawn.setMovementState.emit(pawn.movementStates["standing"])
		return

	# Moving
	if Input.is_action_pressed("gSprint") and !pawn.isInCover:
		pawn.setMovementState.emit(pawn.movementStates["sprint"])
		pawn.isCrouching = false
	elif pawn.isCrouching:
		pawn.setMovementState.emit(pawn.movementStates["crouchWalk"])
	elif pawn.isInCover:
		pawn.setMovementState.emit(pawn.movementStates["coverwalk"])
	else:
		pawn.setMovementState.emit(pawn.movementStates["walk"])
