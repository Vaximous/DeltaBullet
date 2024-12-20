extends Node


var ai_process_counter : int = 0


func _physics_process(_delta: float) -> void:
	#Update the AI
	if AIComponent.instances.size() > 0:
		ai_process_counter += 1
		var component = AIComponent.instances[ai_process_counter % AIComponent.instances.size()]
		#Skip over non-processing AI nodes.
		if !component.is_processing():
			ai_process_counter += 1
			component = AIComponent.instances[ai_process_counter % AIComponent.instances.size()]
		#If the next one over still isn't processing, just skip this iteration.
		if !component.is_processing():
			return

		component._ai_process(_delta)
