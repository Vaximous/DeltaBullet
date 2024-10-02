extends StateMachineState
@export_category("Wander State")
var targetPosition : Vector3 = Vector3.ZERO:
	set(value):
		targetPosition = value
		if is_current_state():
			aiOwner.navAgent.set_target_position(targetPosition)
@export var aiOwner : AIComponent:
	set(value):
		aiOwner = value
		if is_current_state():
			targetPosition = getRandomNavPoints().global_position
			aiOwner.navAgent.target_reached.connect(finishedPath)

func on_enter()->void:
	targetPosition = getRandomNavPoints().global_position
	aiOwner.navAgent.target_reached.connect(finishedPath)

func on_physics_process(delta)->void:
	super(delta)
	if aiOwner != null:
		var currentLocation = aiOwner.pawnOwner.global_transform.origin
		var nextLocation = aiOwner.navAgent.get_next_path_position()
		var newVelocity = (nextLocation-currentLocation).normalized()
		aiOwner.navAgent.velocity = newVelocity

func getRandomNavPoints()->Marker3D:
	if gameManager.world:
		return gameManager.world.worldWaypoints.get_children().pick_random()
	else:
		return null

func progressPath(details:Dictionary)->void:
	aiOwner.walkToPosition(aiOwner.navAgent.get_next_path_position())

func finishedPath()->void:
	#print("path finished")
	aiOwner.pawnOwner.direction = Vector3.ZERO
	aiOwner.navAgent.set_velocity(Vector3.ZERO)
	await get_tree().create_timer(randf_range(0.5,5)).timeout
	targetPosition = getRandomNavPoints().global_position


func _on_force_target_reset_timeout() -> void:
	if is_current_state():
		targetPosition = getRandomNavPoints().global_position
