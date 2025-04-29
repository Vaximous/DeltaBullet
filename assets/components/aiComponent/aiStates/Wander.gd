extends StateMachineState
@export_category("Wander State")
var resetCount = 0
var targetPosition : Vector3 = Vector3.ZERO:
	set(value):
		if is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
			targetPosition = value
			aiOwner.targetPosition = value

@export var aiOwner : AIComponent:
	set(value):
		aiOwner = value
		if is_current_state() and is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
			targetPosition = getRandomNavPoints().global_position
			#aiOwner.targetPathReached.connect(finishedPath)

func on_enter()->void:
	if is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
		var navpoint = getRandomNavPoints()
		if navpoint:
			targetPosition = navpoint.global_position


func getRandomNavPoints()->AIMarker:
	if gameManager.world and is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
		return gameManager.world.getWaypoints(0).pick_random()
	else:
		return null

func on_ai_process(_delta,ai_delta):
	super(aiOwner.get_and_update_ai_process_delta(Time.get_ticks_msec()),aiOwner.get_and_update_ai_process_delta(Time.get_ticks_msec()))

	if AiManager.framesSinceRecalc >= AiManager.framesRecalculation and aiOwner.navigationAgent.is_navigation_finished():
		resetCount +=1
		if resetCount >=10:
			var navpoint = getRandomNavPoints()
			await get_tree().create_timer(randf_range(0.5,5)).timeout
			if navpoint:
				targetPosition = navpoint.global_position


func finishedPath()->void:
	if is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
		#print("path finished")
		var navPoint = getRandomNavPoints()
		if is_instance_valid(navPoint):
			aiOwner.pawnOwner.direction = Vector3.ZERO
			await get_tree().create_timer(randf_range(0.5,5)).timeout
			targetPosition = navPoint.global_position


func _on_force_target_reset_timeout() -> void:
	if is_current_state() and is_instance_valid(aiOwner.pawnOwner) and !aiOwner.pawnOwner.isPawnDead and is_instance_valid(gameManager.world) and aiOwner.is_ai_processing():
		var navpoint = getRandomNavPoints()
		if navpoint:
			targetPosition = navpoint.global_position
