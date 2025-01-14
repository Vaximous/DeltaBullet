extends Node
class_name GOAP_Goal

var aiComponent : AIComponent
var blackboard : Dictionary
var current_path : Array[GOAP_Action]
var last_action : GOAP_Action:
	set(value):
		if value != last_action:
			if last_action != null:
				last_action._exit()
			if value != null:
				value._enter()
		last_action = value
@export var primary_action : GOAP_Action


func score_goal() -> float:
	#This should be scored by, first, priority (node order), and second, if the goal can be completed.
	#If the goal can't be completed, it returns 0.
	var score : float = 0.0
	score += _score_goal()
	if not has_valid_paths():
		score = 0.0
		return score
	return score-get_index()


func _score_goal() -> float:
	return 0.0


func refresh_actions() -> void:
	primary_action.refresh()


func renew_action_path() -> void:
	primary_action.calculate_distance_sum()
	current_path = primary_action.get_shortest_action_path(true)


func get_current_action() -> GOAP_Action:
	if current_path.is_empty():
		renew_action_path()
	last_action = current_path.front()
	return current_path.front()


func execute_plan() -> bool:
	var tries : int = 0
	#If current state failed, renew the path.
	while get_current_action().get_state() == GOAP_Action.ActionState.FAILED and tries < 5:
		renew_action_path()
		tries += 1
	#If after 5 tries the paths are all failing, we probably failed to complete this goal.
	if get_current_action().get_state() == GOAP_Action.ActionState.FAILED:
		printerr("Failed! Couldn't process this goal. Pick a different one.")
		return false
	#Otherwise, if the selected path simply doesn't have the requirement, get a new path.
	if !get_current_action().has_requirement() or get_current_action().goal_request_repath:
		renew_action_path()
	#Process the action.
	get_current_action().process_action()
	return true


#Determines if this has a path that it can take. TODO
func has_valid_paths() -> bool:
	if current_path.size() > 0:
		if current_path[0].get_state() == GOAP_Action.ActionState.FAILED:
			renew_action_path()
		if current_path[0].get_state() == GOAP_Action.ActionState.FAILED:
			return false
	return true


func set_blackboard(_blackboard : Dictionary) -> void:
	blackboard = _blackboard
	primary_action.set_blackboard(_blackboard)
