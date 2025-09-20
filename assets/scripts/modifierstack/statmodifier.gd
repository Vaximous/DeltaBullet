extends Node
class_name StatModifier


@export var stat_to_modify : StringName
@export_multiline var stat_mod_expression : String
@export var order : int = 0


var expression : Expression


func _ready() -> void:
	expression = Expression.new()
	expression.parse(stat_mod_expression, ["stat"])


func _modify_stat(value : Array) -> void:
	if value.size() != 1:
		assert(false, "array.size() != 1: Stat modifier expects array of size 1.")
		return
	var stat = value[0]
	value[0] = expression.execute([stat], self, true, false)
	return
