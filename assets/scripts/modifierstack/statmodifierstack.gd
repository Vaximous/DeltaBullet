extends Node
class_name StatModifierStack


func get_modifiers() -> Array[StatModifier]:
	var arr : Array[StatModifier]
	arr.assign(get_children())
	return arr


func get_modified_stat(stat : StringName, base_value : Variant) -> Variant:
	var mods = get_modifiers()
	mods = mods.filter(filter_mods.bind(stat))
	mods.sort_custom(sort_mods)
	var v = [base_value]
	for m in mods:
		m._modify_stat(v)
	return v[0]


func sort_mods(a : StatModifier, b : StatModifier) -> bool:
	if a.order == b.order:
		return a.get_index() < b.get_index()
	return a.order < b.order


func filter_mods(element : StatModifier, expected : StringName) -> bool:
	return element.stat_to_modify == expected
