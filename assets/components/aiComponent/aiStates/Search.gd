extends StateMachineState
@export_category("Search State")
var timer = Timer.new()
@export var aiOwner : AIComponent
@export var detectionAmount : int = 0.0:
	set(value):
		detectionAmount = value
		if detectionAmount <= 0:
			detectionAmount = 0
@export var detectionWeight : float = 1.0
@export var detectionMaxThreshold = 50
@export var detectionSpeed = 0.6

func on_enter()->void:
	add_child(timer)
	timer.wait_time = detectionSpeed
	timer.start()
	timer.timeout.connect(detectionIncrement)


func on_ai_process(delta)->void:
	if detectionAmount > 35:
		aiOwner.walkToPosition(aiOwner.getTargetPosition())
	if detectionAmount > 1:
		aiOwner.lookAtPosition(aiOwner.getTargetPosition())

	if detectionAmount >= detectionMaxThreshold:
		detectionAmount = 0
		timer.stop()
		change_state("Attack")


func detectionIncrement()->void:
	timer.start()
	if aiOwner.hasTarget() and aiOwner.isTargetInSight():
		detectionWeight = 1.0 + aiOwner.getTargetDistance()
		detectionAmount += 1 * int(detectionWeight)
	else:
		detectionAmount -= 1 * int(detectionWeight)
	#print(detectionAmount)
