extends Node

##Get node and kill its children
func queueFreeNodeChildren(node : Node) -> void:
	for ch in node.get_children():
		ch.queue_free()

func display_message_simple(text : String, duration : float = 5.0, abort_if_displaying : bool = false, parent : Node = null) -> Control:
	var script := preload("res://assets/scenes/ui/popup_message.gd")
	return script.display_text(text, duration, abort_if_displaying, parent)


##Resizes an array, filling spaces with a given value
func resize_array_and_fill(array : Array, size : int, value : Variant) -> void:
	if array.size() > size:
		array.resize(size)
	while array.size() < size:
		array.append(value)

func stripBbcode(bbcodeText : String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[(.+?)\\]")
	return regex.sub(bbcodeText, "", true)

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
	for node in of_node.get_children():
		children_array.append_array(get_children_recursive(node))
	return children_array


##Gets health component of a given node
func get_health_component(baseNode: Node) -> HealthComponent:
	var healthNode = baseNode.find_child(^"HealthComponent")
	if healthNode is HealthComponent:
		return healthNode
	return null


func create_canvas_layer(layer : int, parent : Node = null) -> CanvasLayer:
	if parent == null:
		parent = get_tree().root

	var layer_name = "UtilCanvasLayer%d" % layer

	if parent.has_node(layer_name):
		return parent.get_node(layer_name)

	var canvaslayer := CanvasLayer.new()
	canvaslayer.layer = layer
	canvaslayer.name = layer_name
	parent.add_child(canvaslayer)
	return canvaslayer


##Damages a node using its HealthComponent
func damage_node(baseNode : Node3D, amount : float, dealer : Node3D = null, hitDirection : Vector3 = Vector3.ZERO) -> void:
	var hc := get_health_component(baseNode)
	if hc != null:
		hc.damage(amount, dealer, hitDirection)


func smooth_position2d_array(array : Array[Vector2], iterations : int = 1) -> Array[Vector2]:
	iterations -= 1
	var smoothed_array : Array[Vector2] = []
	#For every position in the array, cubic interp between them
	#Add first
	smoothed_array.append(array.front())
	for idx in array.size():
		#Skip last for smoothing
		if idx + 1 >= array.size():
			continue
		var previous = array[0]
		if idx - 1 > 0:
			previous = array[idx - 1]
		var current = array[idx]
		var next = array[idx + 1]
		var nextnext = next
		if idx + 2 < array.size():
			nextnext = array[idx + 2]
		#Add current to smoothed_array
		smoothed_array.append(current)
		#Get the interpolated position between current and next
		smoothed_array.append(current.cubic_interpolate(next, previous, nextnext, 0.5))
	#Add last
	smoothed_array.append(array.back())
	if iterations > 0:
		smoothed_array = smooth_position2d_array(smoothed_array, iterations)
	return smoothed_array


func smooth_position3d_array(array : Array[Vector3], iterations : int = 1) -> Array[Vector3]:
	iterations -= 1
	var smoothed_array : Array[Vector3] = []
	#For every position in the array, cubic interp between them
	#Add first
	smoothed_array.append(array.front())
	for idx in array.size():
		#Skip last for smoothing
		if idx + 1 >= array.size():
			continue
		var previous = array[0]
		if idx - 1 > 0:
			previous = array[idx - 1]
		var current = array[idx]
		var next = array[idx + 1]
		var nextnext = next
		if idx + 2 < array.size():
			nextnext = array[idx + 2]
		#Add current to smoothed_array
		smoothed_array.append(current)
		#Get the interpolated position between current and next
		smoothed_array.append(current.cubic_interpolate(next, previous, nextnext, 0.5))
	#Add last
	smoothed_array.append(array.back())
	if iterations > 0:
		smoothed_array = smooth_position3d_array(smoothed_array, iterations)
	return smoothed_array


func get_worldenvironment_node(viewport_node : Viewport) -> WorldEnvironment:
	return viewport_node.find_child("WorldEnvironment")


func get_environment(viewport_node : Viewport) -> Environment:
	return viewport_node.world_3d.environment
