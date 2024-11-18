class_name PEMainLoop
extends SceneTree
var time_elapsed_ai_process : float = 0
var time_elapsed_ai_physics_process : float = 0

func _process(delta: float):
	time_elapsed_ai_process += delta
	#print("Process Time: %s" %time_elapsed_ai_process)
	if time_elapsed_ai_process >= 4:
		_ai_process(delta)
		time_elapsed_ai_process = 0

func _physics_process(delta: float):
	time_elapsed_ai_physics_process += delta
	#print("Physics Process Time: %s" %time_elapsed_ai_physics_process)
	if time_elapsed_ai_physics_process >= 4:
		_ai_physics_process(delta)
		time_elapsed_ai_physics_process = 0

func _ai_process(delta:float):
	pass

func _ai_physics_process(delta:float):
	pass
