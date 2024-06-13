extends GOAP_Action

@export var aiComponent : AIComponent
@export var moveToMarker : Marker3D
@export var navAgent : NavigationAgent3D
@export var navPointGrabber : Area3D


func _execute_action()->void:
	super()
	#Console.add_console_message("Getting last known pawn pos..")
	#print(aiComponent.pawnOwner.global_position.distance_to(aiComponent.overlappingObjectPosition))
	if aiComponent.pawnHasTarget and !aiComponent.withinAttackRange:
		if aiComponent.overlappingObjectPosition != null:
			moveToMarker.global_position = aiComponent.overlappingObjectPosition
			aiComponent.pawnOwner.isRunning = true
			setTargetLocation()
	else:
		navAgent.velocity = Vector3.ZERO
		cancel_action()

func setTargetLocation() -> void:
	if navAgent != null:
		navAgent.set_target_position(moveToMarker.global_position)
		navAgent.target_desired_distance = randf_range(0.5,3)
		finish_action()
		gameManager.getEventSignal("calculatedPath").emit()

