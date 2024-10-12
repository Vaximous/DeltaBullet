extends Node
signal freeOrphans
## Global Game Manager Start
var menuScenes = [preload("res://assets/scenes/menu/menuScenes/menuscene1.tscn"),preload("res://assets/scenes/menu/menuScenes/menuScene2.tscn"),preload("res://assets/scenes/menu/menuScenes/menuScene3.tscn")]

#Global Sound Player
var soundPlayer = AudioStreamPlayer.new()
var sounds : Dictionary = {"healSound" = preload("res://assets/sounds/ui/rareItemFound.wav"),
			"alertSound" = preload("res://assets/sounds/ui/uialert.wav")
			}

#Misc
var richPresenceEnabled:bool = false
var activeCamera = null
var debugEnabled:bool = false
var pawnDebug : bool = false

#Settings
var userDir = DirAccess.open("user://")

#Ingame
var playerPosition : Vector3 = Vector3.ZERO
var playerPawns : Array[BasePawn] = []
var controllerSens : float = 0.015
var mouseSens : float = 0.0020
var deadzone : float = 0.1
var defaultFOV : int = 90

#World

var tempImages : Array = ["res://assets/scenes/ui/saveloadmenu/save1.png","res://assets/scenes/ui/saveloadmenu/save2.png","res://assets/scenes/ui/saveloadmenu/save3.png","res://assets/scenes/ui/saveloadmenu/save4.png","res://assets/misc/db7.png"]
var saveOverwrite : String
var currentSave : String
var dialogueCamLerpSpeed:float = 5.0
var world : WorldScene
var pauseMenu : PauseMenu
var bloodDecal = preload("res://assets/entities/bloodSplat/bloodSplat1.tscn")

#Multiplayer
var isMultiplayerGame:bool = false

const dialogue_cam : PackedScene = preload("res://assets/entities/camera/DialogueCamera.tscn")

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	initializeSteam()
	if !userDir.dir_exists("saves"):
		userDir.make_dir("saves")
	process_mode = Node.PROCESS_MODE_ALWAYS
	soundPlayer.bus = "Sounds"
	if richPresenceEnabled:
		pass


func get_persistent_data() -> Dictionary:
	if !userDir.file_exists("persistence"):
		var fa = FileAccess.open(userDir.get_current_dir() + "persistence", FileAccess.WRITE)
		fa.flush()
	var file = FileAccess.open_compressed(userDir.get_current_dir() + "persistence", FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return {}
	var data = file.get_var(true)
	if data is Dictionary:
		return data
	return {}


func write_persistent_data(data : Dictionary) -> void:
	var file = FileAccess.open_compressed(userDir.get_current_dir() + "persistence", FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	file.store_var(data)
	file.flush()


func create_dialogue_camera() -> CutsceneCamera:
	var new_cam = dialogue_cam.instantiate()
	return new_cam


func getColliderPhysicsMaterial(collider : Object) -> DB_PhysicsMaterial:
	var phys_mat : DB_PhysicsMaterial = collider.get(&"physics_material_override")
	if collider.has_meta(&"physics_material_override"):
		#print("Using meta for physics mat")
		phys_mat = collider.get_meta(&"physics_material_override")
	if phys_mat == null and !collider.has_meta(&"no_bhole"):
		#print("No physics mat found, using generic...")
		phys_mat = preload("res://assets/resources/PhysicsMaterials/generic_physics_material.tres")
	return phys_mat


func _input(_event)->void:
	if Input.is_action_just_pressed("aFullscreen"):
		pass

	if Input.is_action_just_pressed("dReloadGame"):
		restartGame()

	if Input.is_action_just_pressed("dRestartScene"):
		if get_tree().paused == false:
			await Fade.fade_out(0.3).finished
			loadWorld(get_tree().current_scene.scene_file_path)
			musicManager.change_song_to(null,0.5)

	if debugEnabled:
		if Input.is_action_pressed("dFreecam"):
			gameManager.activeCamera.unposessObject(true)

		if Input.is_action_pressed("dPosess"):
			var cast : RayCast3D = gameManager.activeCamera.debugCast
			if cast:
				if cast.is_colliding():
					if cast.get_collider().is_in_group("Posessable"):
						gameManager.activeCamera.unposessObject(true)
						gameManager.activeCamera.posessObject(cast.get_collider(),cast.get_collider().followNode)
					else:
						Console.add_console_message("Cannot posess %s, Its not possessable" %cast.get_collider())
			else:
				Console.add_console_message("You can't posess nothing dipshit. Look at a pawn.")



func takeScreenshot(path:String = "user://screenshots",screenshotName:String = "") -> String:
	print("Initializing screenshot!")
	var screenshot_count = 0
	var screenshot = get_viewport().get_texture().get_image()

	var savedfilepath
	if userDir.dir_exists(path):
		var _screenshot_dir = DirAccess.open(path)
		print(_screenshot_dir.get_current_dir())
		screenshot_count = _screenshot_dir.get_files().size() + 1
		if screenshotName == "" or " ":
			screenshot.save_png("%s/screenshot_" + str(screenshot_count) + ".png")
			savedfilepath = "%s/screenshot_" + str(screenshot_count) + ".png"
			screenshot_count = screenshot_count + 1
		else:
			screenshot.save_png("%s/%s.png"%[path,screenshotName])
			savedfilepath = "%s/%s.png"%[path,screenshotName]
	else:
		userDir.make_dir(path)
		var _screenshot_dir = DirAccess.open(path)
		if screenshotName == "" or " ":
			screenshot.save_png("%s/screenshot_" + str(screenshot_count) + ".png")
			savedfilepath = "%s/screenshot_" + str(screenshot_count) + ".png"
			screenshot_count = screenshot_count + 1
		else:
			screenshot.save_png("%s/%s.png"%[path,screenshotName])
			savedfilepath = "%s/%s.png"%[path,screenshotName]
	print("Saved screenshot at %s/%s.png"%[path,screenshotName])
	return savedfilepath

func restartScene()->void:
	musicManager.change_song_to(null,0.35)
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	get_tree().reload_current_scene()

func restartGame()->void:
	get_tree().unload_current_scene()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://assets/scenes/menu/logo.tscn")


func strip_bbcode(bbcode_text : String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[(.+?)\\]")
	return regex.sub(bbcode_text, "", true)

enum NOTIF_POSITION{topleft, topcenter, topright, bottomleft, bottomcenter, bottomright}
func notifyFade(text : String, position : NOTIF_POSITION = 2, fade_time : float = 3.0):
	var new_notif
	var container = Notifications.hudPositions[position]

	new_notif = Notifications.notif_fade.instantiate()
	container.add_child(new_notif)
	set_notif_flags(new_notif, position)

	new_notif.set_text(text)
	if fade_time > 0:
		new_notif.timer.start(fade_time)
	return new_notif

func notifyCheck(text : String, position : NOTIF_POSITION = 2, fade_time : float = -1, texture : Texture = Notifications.checkmarkTexture):
	var new_notif
	var container = Notifications.hudPositions[position]

	new_notif = Notifications.notifCheck.instantiate()
	container.add_child(new_notif)
	set_notif_flags(new_notif, position)

	new_notif.set_text(text)
	new_notif.set_warn_params.call(texture, fade_time)
	if fade_time > 0:
		new_notif.timer.start(fade_time)
	return new_notif

func notify_warn(text : String, position : NOTIF_POSITION = 2, fade_time : float = -1, texture : Texture = Notifications.warning_texture):
	var new_notif
	var container = Notifications.hudPositions[position]

	new_notif = Notifications.notif_warn.instantiate()
	container.add_child(new_notif)
	set_notif_flags(new_notif, position)

	new_notif.set_text(text)
	new_notif.set_warn_params.call(texture, fade_time)
	if fade_time > 0:
		new_notif.timer.start(fade_time)
	return new_notif


func notify_click(text : String, call_on_click : Callable, position : NOTIF_POSITION = 2, fade_time : float = -1, binds : Array = []):
	var new_notif : Control
	var container = Notifications.hudPositions[position]

	new_notif = Notifications.notif_click.instantiate()
	container.add_child(new_notif)
	set_notif_flags(new_notif, position)

	new_notif.set_text(text)
	new_notif.set_click_params.call(call_on_click, binds, fade_time)
	if fade_time > 0:
		new_notif.timer.start(fade_time)
	return new_notif


func set_notif_flags(new_notif, position) -> void:
	match position % 3:
		0:
			new_notif.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		1:
			new_notif.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		2:
			new_notif.size_flags_horizontal = Control.SIZE_SHRINK_END


func notify_custom(node : Control, position : NOTIF_POSITION) -> Control:
	var container = Notifications.hudPositions[position]
	container.add_child(node)
	set_notif_flags(node, position)
	return node

func castRay(cam : Camera3D, range : float = 50000, mask := 0b10111, exceptions : Array[RID] = [], hit_areas : bool = false) -> Dictionary:
	var state = cam.get_world_3d().direct_space_state
	var transform = cam.global_transform
	var params := PhysicsRayQueryParameters3D.create(transform.origin, transform.origin - (transform.basis.z * range), 23, exceptions)
	params.collide_with_areas = hit_areas
	return state.intersect_ray(params)


func getEventSignal(event : StringName) -> Signal:
	event = &"__gameEventSignals__" + str(event)
	if !has_user_signal(event):
		add_user_signal(event)
	return Signal(self, event)

func showMouse()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hideMouse()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func playSound(stream)->void:
	soundPlayer.stream = stream
	soundPlayer.play()

func getGlobalSound(soundname: String):
	if sounds.get(soundname) != null:
		return sounds.get(soundname)

func initializeSteam()->void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)

	if initialize_response['status'] > 0:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		#get_tree().quit()

func disablePlayer()->void:
	if activeCamera != null:
		if activeCamera.followingEntity.inputComponent != null:
			activeCamera.followingEntity.direction = Vector3.ZERO
			activeCamera.followingEntity.inputComponent.movementEnabled = false
			activeCamera.followingEntity.inputComponent.mouseActionsEnabled = false

func enablePlayer()->void:
	if activeCamera != null:
		if activeCamera.followingEntity.inputComponent != null:
			activeCamera.followingEntity.inputComponent.movementEnabled = true
			activeCamera.followingEntity.inputComponent.mouseActionsEnabled = true

func loadWorld(worldscene:String, fadein:bool = false)->void:
	musicManager.change_song_to(null)
	var loader = load("res://assets/scenes/menu/loadingscreen/loadingScreen.tscn")
	var inst = loader.instantiate()
	if fadein:
		await Fade.fade_in(0.5).finished
		get_tree().current_scene.queue_free()
		#get_tree().change_scene_to_packed(loader)
	else:
		get_tree().current_scene.queue_free()
		#get_tree().change_scene_to_packed(loader)
	get_tree().root.add_child(inst)
	inst.sceneToLoad = worldscene

func freeOrphanNodes():
	freeOrphans.emit()

func saveGame(saveName:String = "Save1"):
	if world != null:
		var saveDir = DirAccess.open("user://saves")
		saveDir.make_dir(saveName)
		var saveFile = FileAccess.open("user://saves/%s/%s.pwnSave"%[saveName,saveName],FileAccess.WRITE)
		currentSave = "user://saves/%s/%s.pwnSave"%[saveName,saveName]
		var screenshot = get_viewport().get_texture().get_image()
		screenshot.save_png("user://saves/%s/%s.png"%[saveName,saveName])
		print("user://saves/%s/%s.png"%[saveName,saveName])
		var pawnFile = playerPawns[0].savePawnFile("user://saves/%s/%s"%[saveName,saveName])
		var saveDict : Dictionary = {
			"saveName" : saveName,
			"saveLocation" : gameManager.world.worldData.worldName,
			"scene" : get_tree().current_scene.get_scene_file_path(),
			"timestamp" : Time.get_unix_time_from_system(),
			"dateDict" : Time.get_date_dict_from_system(),
			"pawnToLoad" : pawnFile,
			"saveScreenie" : "user://saves/%s/%s.png"%[saveName,saveName],
			"playerPosition": playerPawns[0].global_position
		}
		var stringy = JSON.stringify(saveDict)
		saveFile.store_line(stringy)
		Console.add_rich_console_message("[color=green] Saved game '%s' sucessfully!"%saveName)
		return saveFile

func loadGame(save:String)->void:
	if save != "" or save != null:
		var saveFile = FileAccess.open(save,FileAccess.READ)
		if saveFile != null:
			Engine.time_scale = 1.0
			get_tree().paused = false
			while saveFile.get_position() < saveFile.get_length():
				var string = saveFile.get_line()
				var json = JSON.new()
				var result = json.parse(string)
				if not result == OK:
					Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%string)
					return
				var nodeData = json.get_data()
				currentSave = save
				loadWorld(nodeData["scene"])
		else:
			Console.add_rich_console_message("[color=red]Unable to find that save![/color]")

func scan_for_scenes(dirpath : String, max_depth : int = -1, _depth = 0) -> PackedStringArray:
	if _depth == 0:
		Console.add_rich_console_message("[color=orange]Scanning scenes at %s...[/color]" % dirpath)
	if max_depth >= 0:
		if _depth > max_depth:
			return []

	var dir = DirAccess.open(dirpath)
	var found_scenes : PackedStringArray = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".tscn") or file_name.ends_with(".scn"):
					found_scenes.append((dirpath +"/"+ file_name).simplify_path())
				elif file_name.ends_with(".tscn.remap") or file_name.ends_with(".scn.remap"):
					var remapfile = "%s/%s"%[dirpath,file_name]
					var cfg = ConfigFile.new()
					cfg.load(remapfile)
					#Console.add_rich_console_message("[color=purple]%s[/color]"%cfg.get_value("remap", "path"))
					found_scenes.append(cfg.get_value("remap", "path"))
					file_name = dir.get_next()
					continue
			else:
				#is a directory
				found_scenes.append_array(scan_for_scenes((dirpath +"/"+ file_name +"/").simplify_path(), max_depth, _depth + 1))
			file_name = dir.get_next()
	else:
		Console.add_rich_console_message("[color=red]An error occurred when trying to access the path.[/color]")
		print("An error occurred when trying to access the path.")

	return found_scenes

func scanForSaves(dirpath : String, max_depth : int = -1, _depth = 0) -> PackedStringArray:
	if _depth == 0:
		print("Scanning saves at %s..." % dirpath)
	if max_depth >= 0:
		if _depth > max_depth:
			return []

	var dir = DirAccess.open(dirpath)
	var foundSaves : PackedStringArray = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with("pwnSave"):
					print(file_name)
					foundSaves.append((dirpath +"/"+ file_name).simplify_path())
			else:
				#is a directory
				foundSaves.append_array(scanForSaves((dirpath +"/"+ file_name +"/").simplify_path(), max_depth, _depth + 1))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return foundSaves

func initShop(shopData:ShopData)->void:
	removeShop()
	var shopUI : PackedScene = load("res://assets/scenes/ui/shopui/shopUI.tscn")
	var _shop = shopUI.instantiate()
	_shop.add_to_group(&"shop")
	_shop.shopResource = shopData
	add_child(_shop)
	_shop.initializeShop()

func removeShop()->void:
	for i in get_children():
		if i.is_in_group(&"shop"):
			i.queue_free()

func createSplat(gposition:Vector3 = Vector3.ZERO,normal:Vector3 = Vector3.ZERO,colPoint:Vector3 = Vector3.ZERO)->void:
	if gameManager.world != null:
		#print("col")
		var _b = bloodDecal.instantiate()
		gameManager.world.worldMisc.add_child(_b)
		_b.rotate(normal,randf_range(0, 180)/PI)
		_b.position = gposition
		_b.look_at(colPoint + normal, Vector3.UP)
		#queue_free()

func sprayBlood(position:Vector3,amount:int,_maxDistance:int,distanceMultiplier:float = 1)->void:
	randomize()
	if world != null:
		for rays in amount:
			var directSpace : PhysicsDirectSpaceState3D = world.worldMisc.get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.new()
			var result : Dictionary
			ray = ray.create(position,position + Vector3(randi_range(-_maxDistance,_maxDistance),randi_range(-_maxDistance,_maxDistance),randi_range(-_maxDistance,_maxDistance)*distanceMultiplier),1)
			result = directSpace.intersect_ray(ray)
			if result:
				createSplat(result.position,result.normal,result.position)

func createBloodPool(position:Vector3,size:float=0.5)->void:
	if world != null:
		var directSpace : PhysicsDirectSpaceState3D = world.worldMisc.get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.new()
		var result : Dictionary
		ray = ray.create(position,position + Vector3.DOWN,1)
		result = directSpace.intersect_ray(ray)
		if result:
			var bloodPool = load("res://assets/entities/bloodPool/bloodPool.tscn")
			var _bloodPool = bloodPool.instantiate()
			world.worldMisc.add_child(_bloodPool)
			_bloodPool.global_position = result.position
			_bloodPool.startPool(size)
