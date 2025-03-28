extends Component
class_name InputComponent
#Variables
##Enables the movement keys to be emitted
var movementEnabled:bool = true
##Enables the mouse action buttons to be emitted
var mouseActionsEnabled:bool = true
var mouseButtonInput:InputEventMouseButton = InputEventMouseButton.new()
var inputDir : Vector3 = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
var controllingPawn : BasePawn

func _ready()->void:
	InputMap.action_set_deadzone("gLookUp",gameManager.deadzone)
	InputMap.action_set_deadzone("gLookDown",gameManager.deadzone)
	InputMap.action_set_deadzone("gLookLeft",gameManager.deadzone)
	InputMap.action_set_deadzone("gLookRight",gameManager.deadzone)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta:float)->void:
		if is_instance_valid(controllingPawn) and gameManager.isMouseHidden():
			if Input.is_action_pressed("gThrowThrowable"):
				if is_instance_valid(controllingPawn) and controllingPawn.throwableAmount > 0:
					if !controllingPawn.freeAim:
						controllingPawn.freeAim = true
					if !controllingPawn.isArmingThrowable and !controllingPawn.isThrowing and !is_instance_valid(controllingPawn.heldThrowable):
						controllingPawn.meshRotation = controllingPawn.attachedCam.camRot
						controllingPawn.armThrowable()

			if Input.is_action_just_released("gThrowThrowable"):
				if is_instance_valid(controllingPawn) and is_instance_valid(controllingPawn.heldThrowable):
					controllingPawn.freeAimTimer.start()
					controllingPawn.throwThrowable()

			if Input.is_action_pressed("gRightClick"):
				if !controllingPawn == null:
					if !controllingPawn.isPawnDead:
						if is_instance_valid(controllingPawn.attachedCam):
							if is_instance_valid(controllingPawn.currentItem):
									if controllingPawn.currentItem.isAiming != true:
										controllingPawn.currentItem.isAiming = true
							controllingPawn.turnAmount = -controllingPawn.attachedCam.vertical.rotation.x
							controllingPawn.freeAim = false
							controllingPawn.freeAimTimer.stop()
							if !controllingPawn.meshLookAt:
								controllingPawn.meshLookAt = true
								if !is_instance_valid(controllingPawn.attachedCam):
									if controllingPawn.meshRotation:
										controllingPawn.meshRotation = controllingPawn.attachedCam.camRot
							controllingPawn.canRun = false
			if Input.is_action_just_released("gRightClick"):
				if controllingPawn:
					if controllingPawn.currentItem:
						if controllingPawn.currentItem.isAiming != false:
							controllingPawn.currentItem.isAiming = false
					if !controllingPawn.isArmingThrowable:
						controllingPawn.meshLookAt = false
					controllingPawn.canRun = true
					if !controllingPawn.freeAim and !controllingPawn.isArmingThrowable:
						controllingPawn.freeAim = false

			if Input.is_action_pressed("gLeftClick"):
				if controllingPawn:
					if !controllingPawn.currentItem == null:
						if !Input.is_action_pressed("gRightClick"):
							if !controllingPawn.freeAim:
								controllingPawn.freeAim = true
						controllingPawn.currentItem.fire()
						controllingPawn.freeAimTimer.start()

			if is_instance_valid(controllingPawn.attachedCam):
				if controllingPawn.freeAim:
					controllingPawn.turnAmount = -controllingPawn.attachedCam.vertical.rotation.x

func getInputDir()->Vector3:
	if gameManager.isMouseHidden():
		inputDir = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
		return inputDir
	else:
		return Vector3.ZERO

func _input(event: InputEvent) -> void:
	if gameManager.isMouseHidden() and is_instance_valid(controllingPawn):
		if mouseActionsEnabled:
			if event.is_action_pressed("gMwheelUp"):
				#emit_signal("mouseButtonPressed", event.button_index)
				if controllingPawn:
					if !controllingPawn.healthComponent == null:
						if !controllingPawn.healthComponent.isDead:
							if !controllingPawn.currentItemIndex == controllingPawn.itemInventory.size()-1:
								controllingPawn.currentItemIndex = controllingPawn.currentItemIndex+1

			if event.is_action_pressed("gMwheelDown"):
				#emit_signal("actionPressed", str(event.button_index))
				if controllingPawn:
					if !controllingPawn.healthComponent == null:
						if !controllingPawn.healthComponent.isDead:
							controllingPawn.currentItemIndex = controllingPawn.currentItemIndex-1

		if event.is_action_pressed("gCrouch"):
			if controllingPawn.isCrouching:
				controllingPawn.isCrouching = false
			else:
				controllingPawn.isCrouching = true

		if event.is_action_pressed("gSafehouseEditor"):
			if gameManager.world.worldData.worldEditable:
				gameManager.initializeSafehouseEditor()

		if event.is_action_pressed("gJump"):
			#emit_signal("actionPressed", str(event.keycode))
			if controllingPawn:
				if controllingPawn.canJump:
					controllingPawn.jump()

		if event.is_action_pressed("gBulletTimeToggle"):
			#emit_signal("actionPressed", str(event.keycode))
			if controllingPawn:
				controllingPawn.toggleBulletTime()

		if event.is_action_pressed("gReloadWeapon"):
			#emit_signal("actionPressed", str(event.keycode))
			if is_instance_valid(controllingPawn.currentItem):
				if controllingPawn.currentItem.canReloadWeapon:
					controllingPawn.currentItem.reloadWeapon()

		if event.is_action_pressed("gUse"):
			#emit_signal("actionPressed", str(event.keycode))
			if controllingPawn:
				var interactObj = controllingPawn.getInteractionObject()
				if is_instance_valid(interactObj):
					if interactObj is BasePawn:
						interactObj.inputComponent.interactSpeakTrigger.emit()
					elif interactObj is InteractiveObject:
						if interactObj.canBeUsed:
							interactObj.objectUsed.emit(controllingPawn)
		if event.is_action_pressed("dKill"):
			#emit_signal("actionPressed", str(event.keycode))
			if controllingPawn:
				controllingPawn.healthComponent.setHealth(0)
				if controllingPawn.attachedCam:
					controllingPawn.attachedCam.fireVignette(0.8,Color.DARK_RED)
					gameManager.notifyFade("You've died! Press F6 to restart!", 4, 5)

		##Movement Code
		if gameManager.isMouseHidden():
			if !event is InputEventMouseMotion and !event is InputEventMouseButton:
				if movementEnabled:
					controllingPawn.direction.x = getInputDir().x
					controllingPawn.direction.z = getInputDir().z
					if controllingPawn.isCurrentlyMoving():
						if Input.is_action_pressed("gSprint"):
							controllingPawn.setMovementState.emit(controllingPawn.movementStates["sprint"])
							controllingPawn.isCrouching = false
						else:
							if !controllingPawn.isCrouching:
								controllingPawn.setMovementState.emit(controllingPawn.movementStates["walk"])
							else:
								controllingPawn.setMovementState.emit(controllingPawn.movementStates["crouchWalk"])
					else:
						if !controllingPawn.isCrouching:
							controllingPawn.setMovementState.emit(controllingPawn.movementStates["standing"])
						else:
							controllingPawn.setMovementState.emit(controllingPawn.movementStates["crouch"])
