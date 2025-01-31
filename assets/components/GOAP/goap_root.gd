extends Node
class_name GOAP_Manager
var aiComponent : AIComponent
#Process the goals
var blackboard : Dictionary:
	set(value):
		blackboard = value
		for goal in goals:
			goal.set_blackboard(value)
var goals : Array[GOAP_Goal] = []
var current_goal : GOAP_Goal:
	set(value):
		if value != current_goal:
			goal_changed.emit()
		current_goal = value
		current_goal.aiComponent = aiComponent

signal goal_changed


func _ready() -> void:
	for goal in get_children():
		if goal is GOAP_Goal:
			goals.append(goal)


func ai_process() -> void:
	var best_goal = get_best_goal()
	if best_goal != current_goal:
		current_goal = best_goal
		current_goal.refresh_actions()
		print("Set goal to %s" % current_goal.name)
	if current_goal.execute_plan() == false:
		get_best_goal()


func get_best_goal() -> GOAP_Goal:
	var best : GOAP_Goal = null
	var best_score : float = -INF
	for goal in goals:
		var score = goal.score_goal()
		if score > best_score:
			best = goal
			best_score = score
	return best
