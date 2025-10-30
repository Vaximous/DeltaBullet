class_name GOAP_Goal
extends Node

@export var primary_action: GOAP_Action

var aiComponent: AIComponent
var blackboard: Dictionary
var current_path: Array[GOAP_Action]
var current_action: GOAP_Action:
	set(value):
		if value != current_action:
			if current_action != null:
				current_action._exit()
			if value != null:
				value._enter()
		current_action = value


func score_goal() -> float:
	#This should be scored by, first, priority (node order), and second, if the goal can be completed.
	#If the goal can't be completed, it returns 0.
	var score: float = 0.0
	score += _score_goal()
	if not has_valid_paths():
		score = 0.0
		return score
	return score - get_index()


func evaluate_action_repath() -> void:
	#Check for a better action path
	var tries: int = 0
	while get_current_action().is_failed() and tries < 10:
		renew_action_path()
		if current_path.is_empty():
			#Don't bother, there's nothing to do.
			return
		tries += 1

	#The chosen action is failed. Do nothing.
	if get_current_action().is_failed():
		#printerr("Failed! Couldn't process this goal. Pick a different one.")
		return

	#The chosen action lacks requirements, or is requesting a repath.
	if !get_current_action().has_requirement() or is_repath_requested():
		renew_action_path()


func refresh_actions() -> void:
	primary_action.refresh()


func renew_action_path() -> void:
	primary_action.calculate_distance_sum()
	current_path = primary_action.get_shortest_action_path(true)


func get_current_action() -> GOAP_Action:
	if current_path.is_empty():
		return null
	return current_path.front()


##Executes the current plan by doing the current action- or picking a new one if the current action failed.
func execute_plan(delta : float) -> void:
	#Process the action chosen.
	get_current_action().process_action(delta)
	blackboard_add_if_not_has("action_time", 0.0)
	blackboard["action_time"] += delta


func is_repath_requested() -> bool:
	return get_current_action().goal_request_repath


#Determines if this has a path that it can take.
func has_valid_paths() -> bool:
	if current_path.size() > 0:
		if current_path[0].get_state() == GOAP_Action.ActionState.FAILED:
			renew_action_path()
		if current_path[0].get_state() == GOAP_Action.ActionState.FAILED:
			return false
	return true


func set_blackboard(_blackboard: Dictionary) -> void:
	blackboard = _blackboard
	primary_action.set_blackboard(_blackboard)


func blackboard_add_if_not_has(key : String, value : Variant) -> void:
	if not blackboard.has(key):
		blackboard[key] = value


func _score_goal() -> float:
	return 0.0
