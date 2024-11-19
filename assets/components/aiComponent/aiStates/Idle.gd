extends StateMachineState
@export_category("Idle State")
@export var aiOwner : AIComponent


func on_ai_process()->void:
	if aiOwner.hasTarget():
		if aiOwner.getTarget() != null:
			if aiOwner.getTarget() is BasePawn:
				change_state("Search")
