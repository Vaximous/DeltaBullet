extends Node

## This will control how often the AI is calculates per frame. Default is 20, so every 20 frames the AI will be recalculated
const framesRecalculation: int = 30
#How many AI are processed per tick.
const ai_processed_per_tick: int = 5

var framesSinceRecalc: int = 0

var ai_process_counter: int = 0


func _physics_process(_delta: float) -> void:
	if framesSinceRecalc >= framesRecalculation:
		updateAI(_delta)
		framesSinceRecalc = 0
	else:
		framesSinceRecalc += 1


func updateAI(delta: float) -> void:
	#Update the AI
	for i in ai_processed_per_tick:
		if AIComponent.instances.size() > 0:
			ai_process_counter += 1
			var component = AIComponent.instances[ai_process_counter % AIComponent.instances.size()]
			#Skip over non-processing AI nodes.
			if !component.is_ai_processing():
				ai_process_counter += 1
				component = AIComponent.instances[ai_process_counter % AIComponent.instances.size()]
				component.set_ai_processing(false)
			#If the next one over still isn't processing, just skip this iteration.
			if !component.is_ai_processing():
				return
			component._ai_process(delta)
			component.set_ai_processing(true)
