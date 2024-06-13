@tool
extends Node
class_name GOAP_Action


##Action was completed.
signal action_completed
##Cancelled by external factors.
signal action_cancelled
##Failed, it couldn't be completed.
signal action_failed
var action_busy : bool
##Wait this amount of time after finishing before emitting finished.
@export var finish_delay : float = 0.0
##Wait this amount of time after cancelling before emitting cancellation.
@export var cancel_delay : float = 0.0
@onready var goal : GOAP_Goal = get_parent()
@export var weight_expression : GOAP_Expression
@export var test_expression : bool = false:
	set(value):
		if value:
			print(calculate_weight())
##Re-executes the action more than once if not busy but still current. If an action is still the best action, it will be repeated.
@export var repeatable : bool = true
@export var renew_cooldown_on_finish : bool = true
var last_execute_time : int = 0

var is_cancelling : bool = false
var is_finishing : bool = false


func _ready() -> void:
	set_physics_process(false)
	set_process(false)


##To be extended per-action.
func _execute_action() -> void:
	action_busy = true
	set_physics_process(true)
	set_physics_process(true)
	last_execute_time = Time.get_ticks_msec()
	pass


##Calculates the weight or importance of this action.
func calculate_weight() -> float:
	if weight_expression == null:
		return 0.0
	var calc = Expression.new()
	calc.parse(weight_expression.expression, weight_expression.input_names)
	if calc.get_error_text() != "":
		printerr("%s Parse Error : \n%" % [get_path(), calc.get_error_text()])
		return 0.0
	var result = calc.execute(weight_expression.variants, goal.root_node, true, false)
	if calc.get_error_text() != "":
		printerr("%s Execute Error : \n%" % [get_path(), calc.get_error_text()])
		return 0.0
	return result


##Overridable function to determine the % the action is completed (0 to 1)
func _get_action_completion() -> float:
	return 0.0


##The action is finished.
func finish_action() -> void:
	if is_finishing:
		return
	is_finishing = true
	if finish_delay > 0.0:
		await get_tree().create_timer(finish_delay).timeout
	action_busy = false
	set_physics_process(false)
	set_process(false)
	if renew_cooldown_on_finish:
		goal.action_pick_cooldown = 0.0
	is_finishing = false


##Cancel or interrupt the action early.
func cancel_action() -> void:
	if is_cancelling:
		return
	is_cancelling = true
	if cancel_delay > 0.0:
		await get_tree().create_timer(cancel_delay).timeout
	action_busy = false
	set_physics_process(false)
	set_process(false)
	action_cancelled.emit()
	is_cancelling = false
