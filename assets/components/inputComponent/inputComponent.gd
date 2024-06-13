extends Component
class_name InputComponent
#Signals
signal movementKeyPressed(key:String)
signal actionPressed(button:InputEventKey)
signal actionHeldDown(action:InputEventKey)
signal mouseButtonPressed(button:InputEventMouseButton)
signal mouseButtonHeld(button:InputEventMouseButton)
signal onMouseMotion(motion:InputEventMouseMotion)

#Variables
##Enables the movement keys to be emitted
var movementEnabled:bool = true
##Enables the mouse action buttons to be emitted
var mouseActionsEnabled:bool = true
var mouseButtonInput:InputEventMouseButton = InputEventMouseButton.new()
var inputDir = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
var controllingPawn

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta)->void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		if mouseActionsEnabled:
			if Dialogic.current_timeline == null:
				if Input.is_action_pressed("gRightClick"):
					if !controllingPawn == null:
						if !controllingPawn.isPawnDead:
							if controllingPawn.attachedCam != null:
								controllingPawn.turnAmount = -controllingPawn.attachedCam.vertical.rotation.x
								controllingPawn.freeAim = false
								controllingPawn.freeAimTimer.stop()
								if !controllingPawn.meshLookAt:
									controllingPawn.meshLookAt = true
									if !controllingPawn.attachedCam == null:
										if controllingPawn.meshRotation:
											controllingPawn.meshRotation = controllingPawn.attachedCam.camRot
								controllingPawn.isRunning = false
								controllingPawn.canRun = false
				else:
					if controllingPawn:
						controllingPawn.meshLookAt = false
						if !controllingPawn.freeAim:
							controllingPawn.canRun = true
							controllingPawn.freeAim = false
				if Dialogic.current_timeline == null:
					if Input.is_action_pressed("gLeftClick"):
						if controllingPawn:
							if !controllingPawn.currentItem == null:
								if !Input.is_action_pressed("gRightClick"):
									if !controllingPawn.freeAim:
										controllingPawn.freeAim = true
										controllingPawn.meshRotation = controllingPawn.attachedCam.camRot
								if Dialogic.current_timeline == null:
									controllingPawn.currentItem.fire()
									controllingPawn.freeAimTimer.start()
					else:
						if controllingPawn:
							if !Input.is_action_pressed("gRightClick"):
								#controllingPawn.canRun = true
								pass

		if !controllingPawn == null:
			if !controllingPawn.attachedCam == null:
				if controllingPawn.freeAim:
					controllingPawn.turnAmount = -controllingPawn.attachedCam.vertical.rotation.x

func getInputDir():
		inputDir = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
		return inputDir

func _unhandled_input(event)->void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		if mouseActionsEnabled:
			if Dialogic.current_timeline == null:
				if event is InputEventMouseMotion:
					emit_signal("onMouseMotion", event)
				elif event is InputEventJoypadMotion:
					pass

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

		if Dialogic.current_timeline == null:
			if event.is_action_pressed("gJump"):
				#emit_signal("actionPressed", str(event.keycode))
				if controllingPawn:
					if controllingPawn.canJump:
						controllingPawn.jump()

			if event.is_action_pressed("gReloadWeapon"):
				#emit_signal("actionPressed", str(event.keycode))
				if controllingPawn:
					if controllingPawn.currentItem != null:
						if controllingPawn.currentItem.canReloadWeapon:
							controllingPawn.currentItem.reloadWeapon()

			if event.is_action_pressed("gUse"):
				#emit_signal("actionPressed", str(event.keycode))
				if controllingPawn:
					var interactObj = controllingPawn.getInteractionObject()
					if interactObj != null:
						if interactObj is BasePawn:
							interactObj.inputComponent.interactSpeakTrigger.emit()
						elif interactObj is InteractiveObject:
							if interactObj.canBeUsed:
								interactObj.objectUsed.emit(controllingPawn)
			if event.is_action_pressed("dKill"):
				#emit_signal("actionPressed", str(event.keycode))
				if controllingPawn:
					controllingPawn.healthComponent.health = 0
					if controllingPawn.attachedCam:
						controllingPawn.attachedCam.fireVignette(0.8,Color.DARK_RED)
						gameManager.notifyFade("You've died! Press F6 to restart!", 4, 5)

##Movement Code
	if movementEnabled:
		if Dialogic.current_timeline == null:
			if Input.get_action_strength("gSprint") >= 1:
				emit_signal("movementKeyPressed","Sprint")
				if controllingPawn:
					if controllingPawn.canRun:
						controllingPawn.isRunning = true
						#controllingPawn.freeAim = false

			else:
				if controllingPawn:
					controllingPawn.isRunning = false
			if event is InputEventKey:
				if Input.get_action_strength("gMoveRight") >= 1:
					emit_signal("movementKeyPressed","Right")

				if Input.get_action_strength("gMoveLeft") >= 1:
					emit_signal("movementKeyPressed","Left")

				if Input.get_action_strength("gMoveForward") >= 1:
					emit_signal("movementKeyPressed","Forward")

				if Input.get_action_strength("gMoveBackward") >= 1:
					emit_signal("movementKeyPressed","Backward")






