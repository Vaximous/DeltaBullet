extends Node

#Check if file exists
func doesFileExist(filePath : String)->bool:
	if FileAccess.file_exists(filePath):
		print("File exists at: " + filePath)
		return true
	else:
		print("File does not exist at: " + filePath)
		return false

#Remove directory
func rmdir(directory: String) -> void:
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	for dir in DirAccess.get_directories_at(directory):
		rmdir(directory.path_join(dir))
	DirAccess.remove_absolute(directory)

# Create a popup to display info
func createGamePopup(popup:PopupInfobank)->CanvasLayer:
	gameManager.getPauseMenu().canPause = false
	var infopop = load("res://assets/scenes/ui/infopopup/infoPopup.tscn").instantiate()
	var clayer = create_canvas_layer(3)
	infopop.informationBank = popup
	clayer.add_child(infopop)
	infopop.tree_exited.connect(clayer.queue_free)
	infopop.tree_exited.connect(gameManager.hideMouse)
	infopop.tree_exited.connect(func():gameManager.getPauseMenu().canPause = true)
	gameManager.showMouse()
	return clayer

##Get node and kill its children
func queueFreeNodeChildren(node : Node) -> void:
	for ch in node.get_children():
		ch.queue_free()

func display_message_simple(text : String, duration : float = 5.0, abort_if_displaying : bool = false, parent : Node = null) -> Control:
	var script := preload("res://assets/scenes/ui/popup_message.gd")
	return script.display_text(text, duration, abort_if_displaying, parent)

func getPawnAnimationTree(pawn:BasePawn)->AnimationTree:
	return pawn.animationTree

func getPawnCurrentWeaponAnimationTree(pawn:BasePawn)->AnimationTree:
	if is_instance_valid(pawn):
		if is_instance_valid(pawn.currentItem):
			return pawn.currentItem.animationTree
	return null

func getPawnWeaponState(pawn:BasePawn)->AnimationNodeStateMachinePlayback:
	if is_instance_valid(pawn):
		var atree : AnimationTree = getPawnCurrentWeaponAnimationTree(pawn)
		return atree.get("parameters/weaponState/playback")
	return null

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
