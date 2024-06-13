extends GOAP_Action

@export var moveToMarker : Marker3D
@export var navAgent : NavigationAgent3D
@export var navPointGrabber : Area3D
@export var aiComponent: AIComponent

func _execute_action()->void:
	super()
	if !navAgent.target_reached.is_connected(finish_action):
		navAgent.target_reached.connect(finish_action)
	if !goal.goal_entered.is_connected(getPosToWaypoint):
		goal.goal_entered.connect(getPosToWaypoint)
	if !action_completed.is_connected(getPosToWaypoint):
		action_completed.connect(getPosToWaypoint)
	#finish_action()

func setTargetLocation() -> void:
	if navAgent != null:
		navAgent.set_target_position(moveToMarker.global_position)
		await get_tree().process_frame
		aiComponent.reachedTarget = false
		if navAgent.is_target_reachable():
			#Console.add_console_message("updating ai location on " + get_owner().pawnOwner.name)
			#navAgent.target_desired_distance = randf_range(0.5,3)
			aiComponent.pawnOwner.isRunning = false

func getNavPoints(getRandomPoint:bool=false):
	if getRandomPoint == false:
		for navPoints in navPointGrabber.get_overlapping_bodies():
			if navPoints is Marker3D:
				return navPoints
	else:
		var navPointArray
		if gameManager.world:
			if gameManager.world.worldWaypoints:
				if gameManager.world.worldWaypoints.get_children() != null:
					navPointArray = gameManager.world.worldWaypoints.get_children()
		if navPointArray:
			for navPoint in navPointArray:
				if navPoint != null:
					var randomPoint = navPointArray.pick_random()
					print(randomPoint.global_position)
					return randomPoint
func getPosToWaypoint():
	var navPos = getNavPoints(true).global_position
	if navPos != null:
		moveToMarker.global_position = navPos
		setTargetLocation()
	else:
		cancel_action()

	if navAgent.is_target_reachable():
		finish_action()
	else:
		navPos = getNavPoints(true).global_position
		if navPos != null:
			moveToMarker.global_position = navPos
			setTargetLocation()
