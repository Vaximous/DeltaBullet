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


#Checks if it's capable of preforming the action. IE, can see player, can move, etc.
#Override!
func calculate_distance_sum() -> int:
	distance_sum = 1 + count_requirements()
	#print("%s SUM = %s" % [name, distance_sum])
	return distance_sum


func has_requirement() -> bool:
	return distance_sum <= 1


func count_requirements() -> int:
	return _count_requirements()


func _count_requirements() -> int:
	return 1


func process_action() -> void:
	state = ActionState.BUSY
	return


func get_state() -> ActionState:
	if current_path.size() > 0:
		return current_path.front().state
	return state


func get_shortest_action_path(recalculating: bool = false) -> Array[GOAP_Action]:
	#Skip heavy processing here
	if not recalculating and !current_path.is_empty():
		return current_path
	#Recursive process
	var path: Array[GOAP_Action] = []
	var next_choices: Array[GOAP_Action]
	#Distance = 1 + requirements, so that our algorithm can find the action path with the least requirements.
	if distance_sum > 1:
		#If I can't do it, check requirements.
		for req in requirements:
			req.calculate_distance_sum()
			next_choices.append(req)
	#Sort next_choices by our calculated distance
	next_choices.sort_custom(func(a: GOAP_Action, b: GOAP_Action): return a.distance_sum < b.distance_sum)
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
		i.set_blackboard(_blackboard)
	for i in fallbacks:
		i.set_blackboard(_blackboard)


#region helper functions
func is_available() -> bool:
	return state == ActionState.AVAILABLE


func is_busy() -> bool:
	return state == ActionState.BUSY


func is_failed() -> bool:
	return state == ActionState.FAILED


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


func _refresh() -> void:
	state = ActionState.AVAILABLE


func _exit() -> void:
	print("%s exited..." % name)
	return


func _enter() -> void:
	print("%s entered..." % name)
	return
