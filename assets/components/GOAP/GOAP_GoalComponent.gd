@tool
extends Node
class_name GOAP_Goal


@export var root_node : Node
@export var action_pick_interval : float = 1.0
var action_pick_cooldown : float = 0.0
##Action to fallback to when it is null. By default this is the 0th indexed child.
@export var fallback_action : GOAP_Action
@export var weight_expression : GOAP_Expression
@export var goal_meet_expression : GOAP_Expression
@export var test_expression : bool = false:
	set(value):
		if value:
			print("Weight : %s" % calculate_weight())
			print("Goal met : %s" % calculate_goal_met())
var actions : Array[GOAP_Action]
var current_action : GOAP_Action


signal goal_entered
signal goal_exited
signal goal_met


func _ready() -> void:
	var goap_actions : Array[GOAP_Action] = []
	goap_actions.assign(get_children())
	actions = goap_actions


func tick(delta : float) -> void:
	action_pick_cooldown -= delta
	if is_interruptable():
		if calculate_goal_met():
			goal_met.emit()
	if action_pick_cooldown < 0.0:
		action_pick_cooldown = action_pick_interval
		pick_best_action()


func enter_goal() -> void:
	action_pick_cooldown = action_pick_interval
	pick_best_action()
	goal_entered.emit()


func exit_goal() -> void:
	if current_action != null:
		current_action.cancel_action()
		current_action = null
	goal_exited.emit()


func pick_best_action() -> void:
	var best = calculate_best_action()
	if current_action != null:
		if current_action.is_cancelling or current_action.is_finishing:
			#print("Stalling action picking, current action is exiting...")
			return
		if current_action == best:
			if !current_action.action_busy and current_action.repeatable:
				#print("Repeating current action.")
				current_action._execute_action()
				return
			#print("Current action is best, returning.")
			return
		if current_action.action_busy:
			if current_action.get_index() > best.get_index():
				#best has higher priority, cancel current
				#print("Overriding current action with higher priority action.")
				var current_safe = current_action
				await current_action.cancel_action()
				if current_action != current_safe:
					#It was somehow changed in this timeframe, best option is to abort here.
					push_warning("%s GOAP current_action was changed while cancelling- aborted switch for safety.")
					return
				set_next_action(best)
			return
		#print("Current action isn't busy, overriding.")
		set_next_action(best)
		return
	#print("Current action is null, overriding.")
	set_next_action(best)


func set_next_action(next_action : GOAP_Action) -> void:
	#print("Picking next action: %s -> %s" % [current_action, next_action])
	current_action = next_action
	next_action._execute_action()


func set_next_action_by_name(action_name : NodePath) -> void:
	var node = get_node_or_null(action_name)
	if node is GOAP_Action:
		current_action = node
		node._execute_action()


func clear_action() -> void:
	set_next_action(fallback_action if fallback_action != null else get_child(0))


func get_actions_by_weight() -> Array[GOAP_Action]:
	var sorted_action_array : Array[GOAP_Action] = []
	sorted_action_array.assign(actions)
	for action in sorted_action_array:
		action.set_meta(&"last_weight_calculation", action.calculate_weight())
	sorted_action_array.sort_custom(func(a : GOAP_Action, b : GOAP_Action):
		if a.get_meta(&"last_weight_calculation") == b.get_meta(&"last_weight_calculation"):
			return a.get_index() < b.get_index()
		return a.get_meta(&"last_weight_calculation") > b.get_meta(&"last_weight_calculation")
		)
	return sorted_action_array


func calculate_best_action() -> GOAP_Action:
	return get_actions_by_weight().pop_front()


##Calculates the weight or importance of this goal.
func calculate_weight() -> float:
	if weight_expression == null:
		return 0.0
	var calc = Expression.new()
	calc.parse(weight_expression.expression, weight_expression.input_names)
	if calc.get_error_text() != "":
		printerr("%s Parse Error : \n%" % [get_path(), calc.get_error_text()])
		return 0.0
	var result = calc.execute(weight_expression.variants, root_node, true, false)
	if calc.get_error_text() != "":
		printerr("%s Execute Error : \n%" % [get_path(), calc.get_error_text()])
		return 0.0
	return result


func calculate_goal_met() -> bool:
	if goal_meet_expression == null:
		return false
	var calc = Expression.new()
	calc.parse(goal_meet_expression.expression, goal_meet_expression.input_names)
	if calc.get_error_text() != "":
		printerr("%s Parse Error : \n%" % [get_path(), calc.get_error_text()])
		return false
	var result = calc.execute(goal_meet_expression.variants, root_node, true, false)
	if calc.get_error_text() != "":
		printerr("%s Execute Error : \n%" % [get_path(), calc.get_error_text()])
		return false
	return bool(result)


func is_interruptable() -> bool:
	if current_action == null: return true
	return not current_action.is_cancelling and not current_action.is_finishing


#NOTES
#Specialized functions probably make sense
#Try : A more rigid switching procedure
#example : _exit_action, _exit_goal, _enter_action, _enter_goal

