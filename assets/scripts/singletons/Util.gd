extends Node


##Resizes an array, filling spaces with a given value
func resize_array_and_fill(array : Array, size : int, value : Variant) -> void:
	if array.size() > size:
		array.resize(size)
	while array.size() < size:
		array.append(value)


##Given an array of floats, picks a random index with the floats as the weight for the index
func pick_weighted(weight_array:Array[float]) -> int:
	#Sum all of the odds
	var sum : float = 0.0
	for i in weight_array:
		sum += i
	var random_selector = randf_range(0, sum)
	#Subtract each element until random_selector is 0
	var chosen_index : int = 0
	for idx in weight_array.size():
		random_selector -= weight_array[idx]
		if random_selector <= 0.0:
			chosen_index = idx
			break
	return chosen_index


##Recursively gets all child nodes
func get_children_recursive(of_node : Node) -> Array[Node]:
	var children_array : Array[Node]
	children_array.append_array(of_node.get_children())
	for node in of_node:
		children_array.append_array(get_children_recursive(node))
	return children_array


##Gets health component of a given node
func get_health_component(baseNode: Node) -> HealthComponent:
	var healthNode = baseNode.find_child(^"HealthComponent")
	if healthNode is HealthComponent:
		return healthNode
	return null


##Damages a node using its HealthComponent
func damage_node(baseNode : Node3D, amount : float, dealer : Node3D = null, hitDirection : Vector3 = Vector3.ZERO) -> void:
	var hc := get_health_component(baseNode)
	if hc != null:
		hc.damage(amount, dealer, hitDirection)
