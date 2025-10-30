class_name GOAP_Action
extends Node

enum ActionState {
	AVAILABLE,
	BUSY,
	FAILED,
}

#Might be dependent on other nodes
##Try these if this one is missing its requirement.
@export var requirements: Array[GOAP_Action]
##If branch fails, fall back on these.
@export var fallbacks: Array[GOAP_Action]

var aiComponent: AIComponent
var blackboard: Dictionary
#AVAILABLE 	- The action can be taken
#BUSY 		- The action is currently busy, don't change.
#FAILED 	- This branch, pick a different branch.
var state: ActionState = ActionState.AVAILABLE
var goal_request_repath: bool = false

var current_path: Array[GOAP_Action] = []
var distance_sum: int = 1


@warning_ignore("unused_parameter")
func _process_action(delta: float) -> void:
	pass


func calculate_distance_sum() -> int:
	distance_sum = 1 + count_requirements()
	#print("%s SUM = %s" % [name, distance_sum])
	return distance_sum


func has_requirement() -> bool:
	return distance_sum <= 1


func count_requirements() -> int:
	return _count_requirements()


func process_action(delta: float) -> void:
	state = ActionState.BUSY
	_process_action(delta)
	return


func get_state() -> ActionState:
	if current_path.size() > 0:
		return current_path.front().state
	return state


func get_shortest_action_path(recalculating: bool = false) -> Array[GOAP_Action]:
	#Skip heavy processing here
	if not recalculating and !current_path.is_empty():
		#Don't recalculate path, just get best one
		current_path.sort_custom(_sort_action)
		for i in current_path:
			i.get_shortest_action_path(false)
		return current_path
	#Recursive process
	var path: Array[GOAP_Action] = []
	var next_choices: Array[GOAP_Action]
	if not has_requirement():
		#If I can't do it, check requirements / dependencies.
		for req in requirements:
			req.calculate_distance_sum()
			next_choices.append(req)
	#Sort next_choices by our calculated distance
	next_choices.sort_custom(_sort_action)
	#Pick the one with the least distance, continue
	for idx in next_choices.size():
		var choice: GOAP_Action = next_choices[idx]
		if choice.state != ActionState.FAILED:
			#Given that this ones successful and the shortest calculated distance, get its path.
			path.append_array(choice.get_shortest_action_path(recalculating))
			break
		if idx == next_choices.size() - 1:
			#Use fallbacks
			var fallback = get_fallback_action()
			if fallback == null:
				fail_me()
				break
			path.append_array(fallback.get_shortest_action_path(recalculating))
			break
	path.append(self)
	current_path = path
	goal_request_repath = false
	return path


func get_fallback_action() -> GOAP_Action:
	for f_idx in fallbacks.size():
		var fallback = fallbacks[f_idx]
		if fallback.state != ActionState.FAILED or f_idx == fallbacks.size() - 1:
			return fallback
	return null


func fail_me() -> void:
	goal_request_repath = true
	state = ActionState.FAILED


#Refresh State for goal changes
func refresh() -> void:
	for r in requirements:
		r.refresh()
	for f in fallbacks:
		f.refresh()
	_refresh()


func set_blackboard(_blackboard: Dictionary) -> void:
	blackboard = _blackboard
	for i in requirements:
		if i.blackboard != _blackboard:
			i.set_blackboard(_blackboard)
	for i in fallbacks:
		if i.blackboard != _blackboard:
			i.set_blackboard(_blackboard)


func is_available() -> bool:
	return state == ActionState.AVAILABLE


func is_busy() -> bool:
	return state == ActionState.BUSY


func is_failed() -> bool:
	return state == ActionState.FAILED


func exit() -> void:
	blackboard["action_time"] = 0.0
	_exit()


func enter() -> void:
	blackboard["action_time"] = 0.0
	_enter()


#region helper functions
func getTargetEnemy() -> BasePawn:
	var result = blackboard.get_or_add("target", blackboard.get("closestPawn", null))
	if result != null:
		return result
	else:
		return null


func getCurrentPawn() -> BasePawn:
	return blackboard.get("pawn")


func getNavAgent() -> NavigationAgent3D:
	return blackboard.get("navAgent")

#endregion


##Requirements are tallied and represented as a single number. Larger number = more important,
##ie- you cant shoot without a gun.
func _count_requirements() -> int:
	return 1


func _sort_action(a: GOAP_Action, b: GOAP_Action) -> bool:
	return a.distance_sum < b.distance_sum


func _refresh() -> void:
	state = ActionState.AVAILABLE


func _exit() -> void:
	print("%s exited..." % name)
	return


func _enter() -> void:
	print("%s entered..." % name)
	return
