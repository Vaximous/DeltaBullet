extends Node


const HELP_DICT := {
	"world":"The current World, which is the root of the level.",
	"hit":"The collider the camera ray is colliding with, is null if none is found.",
	"hitPos":"The point the camera ray is colliding, is null if none is found.",
	"userDir":"Globalized user:// directory.",
	"customParams":"A list of custom parameters. See _s() and _g()",
	"echo(var)":"Displays the variable input on the console.",
	"load(path)":"Loads the resource at the given filepath.",
	"spawnPawn(position)":"Spawns a pawn at the given position. If none is given, defaults to hitPos.",
	"spawnNode(node, parent)":"Adds the node as a child of parent. If no parent is given, it defaults to world.",
	"setTimescale(value)":"Sets the timescale or speed of the engine. 0.5 is half speed, 2.0 is double speed. Capped to 10.",
	"clear()":"Clears the console output.",
	"quit()":"Quits the game.",
	"openDir(dir)":"Opens the specified directory in the system file explorer.",
	"_s(key, value)":"Stores a custom param in customParam dict as a key-value pair.",
	"_g(key, default)":"Gets a custom param in customParam dict with the given key, defaults to default, which is null when none is specified.",
	"loadFromFile(filename)":"Loads data from a file saved in 'userData/console_out'. WARNING: Loads objects, meaning code can be executed. Don't load files from untrusted sources.",
	"saveToFile(filename, data)":"Saves file as specified filename in 'userData/console_out/', stores data as a var with objects encoded."
}

var config = UserConfig
var _gameManager = gameManager
var _questManager = questManager
var userDir = ProjectSettings.globalize_path("user://")
var help:
	get:
		Console.add_console_message("-- Help Menu --", Color.DIM_GRAY)
		Console.add_console_message("-- Available vars --", Color.LIGHT_CORAL)
		for key in HELP_DICT:
			if (key as String).contains("("):
				continue
			Console.add_rich_console_message("[color=light_coral]%s[/color]: %s" % [key, HELP_DICT[key]])
		Console.add_console_message("-- Available methods --", Color.LIGHT_SKY_BLUE)
		for key in HELP_DICT:
			if !(key as String).contains("("):
				continue
			Console.add_rich_console_message("[color=light_sky_blue]%s[/color]: %s" % [key, HELP_DICT[key]])
		Console.add_console_message("For detailed help on a specific method, type _help(\"method\")", Color.DIM_GRAY)
var world:
	get:
		return gameManager.world
var hit:
	get:
		if gameManager.activeCamera.camCast.is_colliding:
			return gameManager.activeCamera.camCast.get_collider()
		return null
var hitPos:
	get:
		if gameManager.activeCamera.camCast.is_colliding:
			return gameManager.activeCamera.camCast.get_collision_point()
		return null
var customParams : Dictionary = {}


func echo(variable):
	Console.add_console_message(":: "+str(variable), Color.GRAY)
	return variable


func setGravity(value:float)->void:
	ProjectSettings.set_setting("physics/3d/default_gravity", value)


func load(path : String):
	var res = load(path)
	if res == null:
		Console.add_console_message("Failed to load %s" % path, Color.RED)
		return res
	Console.add_console_message("Loaded %s" % path, Color.GREEN)
	return res

func posess():
	var cast : RayCast3D = gameManager.activeCamera.debugCast
	if cast:
		if cast.is_colliding():
			if cast.get_collider().is_in_group("Posessable"):
				freecam()
				gameManager.notify_warn("Posessing..", 2, 5)
				gameManager.activeCamera.posessObject(cast.get_collider(),cast.get_collider().followNode)
			else:
				gameManager.notify_warn("Cannot posess %s, Its not possessable" %cast.get_collider(), 2, 5)
				Console.add_console_message("Cannot posess %s, Its not possessable" %cast.get_collider())
	else:
		gameManager.notify_warn("You can't posess nothing dipshit. Look at a pawn.", 2, 5)
		Console.add_console_message("You can't posess nothing dipshit. Look at a pawn.")
func freecam():
	gameManager.notify_warn("Freecam Enabled", 2, 5)
	gameManager.activeCamera.unposessObject(true)

func spawnPawn(walk:bool = false,position : Vector3 = Vector3.INF) -> void:
	var cast : RayCast3D = gameManager.activeCamera.camCast
	if cast.is_colliding() and !position.is_finite():
		var pawn = load("res://assets/entities/pawnEntity/pawnEntity.tscn").instantiate()
		var aiControllerComponent = load("res://assets/components/aiComponent/aiComponent.tscn")
		gameManager.world.worldPawns.add_child(pawn)
		pawn.rotation.y = randf_range(0,360)
		pawn.global_position = cast.get_collision_point()
		pawn.fallDamageEnabled = true
		pawn.global_position.y = pawn.global_position.y + 1
		if walk:
			var controller : AIComponent = aiControllerComponent.instantiate()
			pawn.componentHolder.add_child(controller)
			pawn.inputComponent = controller
			pawn.checkComponents()
			controller.aiType = 1
		pawn.fixRot()
		if gameManager.debugEnabled:
			Console.add_console_message("spawned %s at %s" % [pawn, pawn.global_position])
			gameManager.notifyFade("Spawned %s at %s"% [pawn, pawn.global_position], 1, 3)
	else:
		if gameManager.debugEnabled:
			gameManager.notify_warn("Unable to spawn pawn, Cannot find position.", 2, 10)



func spawnNode(node : Node, parent : Node = null) -> Node:
	if parent == null:
		parent = world
	parent.add_child(node)
	return node


func setTimescale(value : float = 1.0) -> void:
	Engine.time_scale = clamp(value, 0.0, 10.0)
	Console.add_console_message("Set timescale to %s (%s%%)" % [Engine.time_scale, 100 * Engine.time_scale], Color.DIM_GRAY)


func clear() -> void:
	Console.clear()


func quit() -> void:
	get_tree().quit()


func openDir(dir : String) -> void:
	OS.shell_open(dir)


func _s(key, value):
	customParams[key] = value
	Console.add_console_message("stored {%s:%s}" % [key, value], Color.DIM_GRAY)
	return value


func _g(key, default = null):
	var got = customParams.get(key, default)
	Console.add_console_message("got {%s:%s}" % [key, got], Color.DIM_GRAY)
	return got

func setFirstperson():
	gameManager.activeCamera.followingEntity.setFirstperson()

func setThirdperson():
	gameManager.activeCamera.followingEntity.setThirdperson()

func loadFromFile(filename : String):
	var dir = (userDir + "/console_out/").simplify_path()
	if !DirAccess.dir_exists_absolute(dir):
		Console.add_console_message("Directory 'console_out' does not exist in user://", Color.RED)
		return
	dir += "/"+filename
	var fa = FileAccess.open(dir, FileAccess.READ)
	if fa == null:
		Console.add_console_message("Failed to open file %s" % [dir], Color.RED)
		return
	Console.add_console_message("Load success!", Color.GREEN)
	var data = fa.get_var(true)
	Console.add_console_message("Data: %s" % [data], Color.GRAY)
	return data


func saveToFile(filename : String, data) -> void:
	var dir = (userDir + "/console_out/").simplify_path()
	if !DirAccess.dir_exists_absolute(dir):
		if DirAccess.make_dir_absolute(dir) != OK:
			Console.add_console_message("Failed to create directory 'console_out' in user://", Color.RED)
			Console.add_console_message("Try openUserDir() and adding a 'console_out' folder to the folder opened.", Color.RED)
			return
	var fa = FileAccess.open("user://console_out/"+filename, FileAccess.WRITE)
	if fa == null:
		Console.add_console_message("Failed to open file %s" % [filename], Color.RED)
		return
	fa.store_var(data, true)
	fa.close()
	Console.add_console_message("Save success!", Color.GREEN)
	Console.add_console_message("Path: %s" % [dir], Color.GRAY)
	Console.add_console_message("Data: %s" % [data], Color.GRAY)
	return


func _help(method : String = "") -> void:
	match method:
		"spawnNode":
			Console.add_rich_console_message("[color=light_coral]func [/color][color=light_sky_blue]spawnNode[/color](node : [color=medium_spring_green]Node[/color], parent : [color=medium_spring_green]Node[/color]) -> [color=medium_spring_green]Node[/color]:")
			Console.add_console_message("Calls 'add_child' on the 'parent' node, passing in the 'node'.\nIf no 'parent' node is provided, it defaults to 'world'.\nReturns the provided 'node'.", Color.GRAY)
			return
		"":
			Console.add_console_message("Please provide a method. Example : help(\"spawnNode\")", Color.RED)
			return
	#Detailed help wasn't provided for this.
	Console.add_console_message("Detailed help for this method not found, or the method doesn't exist.", Color.RED)


func debugDraw(mode : Viewport.DebugDraw) -> void:
	Console.add_console_message("Set debug_draw to %s" % mode, Color.DIM_GRAY)
	get_tree().get_root().get_viewport().debug_draw = mode

func spawnPlayer(pos:Vector3 = Vector3.ZERO):
	var playerPawn = load("res://assets/entities/pawnEntity/pawnEntity.tscn").instantiate()
	var controller = load("res://assets/components/inputComponent/inputComponent.tscn").instantiate()
	gameManager.world.playerPawns.add_child(playerPawn)
	playerPawn.componentHolder.add_child(controller)
	playerPawn.inputComponent = controller
	playerPawn.checkComponents()

func setTimeOfDay(time:float):
	if gameManager.world:
		gameManager.world.worldSky.timeOfDay = time

func progressTime(value:bool):
	if gameManager.world:
		gameManager.world.worldSky.simulateTime = value

func pawnDebug(value:bool):
	if gameManager.world:
		gameManager.pawnDebug = value
		if value:
			gameManager.getEventSignal("debugEnabled").emit()
			gameManager.notify_warn("Pawn Debugger info will appear above NPC pawns' heads.", 2, 10)
		else:
			gameManager.getEventSignal("debugDisabled").emit()
			gameManager.notify_warn("Pawn Debugger info will no longer appear above NPC pawns' heads.", 2, 10)

func debugToggle():
	if gameManager.debugEnabled:
		gameManager.notify_warn("Debug controls are disabled.", 2, 10)
		gameManager.debugEnabled = false
		Console.add_console_message("Debug controls are now disabled.")
	else:
		gameManager.notify_warn("Debug controls are enabled.", 2, 10)
		gameManager.debugEnabled = true
		Console.add_console_message("Debug controls are now enabled.")

func loadMap(map):
	var worldsPath = "res://assets/scenes/worlds/"
	var dir : DirAccess
	if map is String:
		if map != "" or " ":
			gameManager.loadWorld(str("%s.tscn"%map))

func maps():
	for m in get_tree().get_nodes_in_group(&"maplist"):
		m.queue_free()

	var maplist = load("res://assets/scenes/ui/mapslist/maplist.tscn")
	var mapInst = maplist.instantiate()
	get_tree().current_scene.add_child(mapInst)
