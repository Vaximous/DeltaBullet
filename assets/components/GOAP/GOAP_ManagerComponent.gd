extends Node
class_name GOAP_Manager
@export var enabled = true
var goals : Array[GOAP_Goal]
var current_goal : GOAP_Goal:
	set(value):
		if current_goal != value:
			if current_goal != null:
				current_goal.exit_goal()
			current_goal = value
			if value != null:
				value.enter_goal()
			print("Changed goal to %s" % value.name)

##How often the goal will execute
var goal_execute_timer : Timer = Timer.new()
var execute_time = 1.0
##How often it will check if a new goal is needed.
@export var goal_selection_interval : float = 0.5
##The behavior to fallback to when the goal is null.
@export var fallback_goal : GOAP_Goal
var goal_selection_cooldown : float = 0.0


func _ready() -> void:
	add_child(goal_execute_timer)
	goal_execute_timer.timeout.connect(goal_execute_timer.start)
	goal_execute_timer.timeout.connect(process_goal)
	goal_execute_timer.wait_time = execute_time
	goal_execute_timer.one_shot = false
	goal_execute_timer.start()
	var goap_goals : Array[GOAP_Goal] = []
	goap_goals.assign(get_children())
	goals = goap_goals


func _physics_process(delta: float) -> void:
	if enabled:
		process_goal(delta)


func process_goal(delta:float = get_physics_process_delta_time()):
	if current_goal != null:
		current_goal.tick(delta)
	goal_selection_cooldown -= delta
	if goal_selection_cooldown < 0:
		if current_goal != null:
			if !current_goal.is_interruptable():
				return
		goal_selection_cooldown = goal_selection_interval
		set_current_goal(calculate_best_goal())

func set_current_goal(new_goal : GOAP_Goal) -> void:
	current_goal = new_goal


func get_goals_by_weight() -> Array[GOAP_Goal]:
	var sorted_goal_array : Array[GOAP_Goal]
	sorted_goal_array.assign(goals)
	for goal in sorted_goal_array:
		goal.set_meta(&"last_weight_calculation", goal.calculate_weight())
	sorted_goal_array.sort_custom(func(a : GOAP_Goal, b : GOAP_Goal):
		return a.get_meta(&"last_weight_calculation") > b.get_meta(&"last_weight_calculation")
		)
	return sorted_goal_array


func calculate_best_goal() -> GOAP_Goal:
	return get_goals_by_weight().pop_front()
