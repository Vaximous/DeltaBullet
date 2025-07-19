extends Node
## Global Game Manager Start
var bloodSpurts : Array[StandardMaterial3D] = [preload("res://assets/materials/blood/spurts/bloodSpurt.tres"),preload("res://assets/materials/blood/spurts/bloodSpurt2.tres"),preload("res://assets/materials/blood/spurts/bloodSpurt3.tres"),preload("res://assets/materials/blood/spurts/bloodSpurt4.tres"),preload("res://assets/materials/blood/spurts/bloodSpurt5.tres"),preload("res://assets/materials/blood/spurts/bloodSpurt6.tres"),preload("res://assets/materials/blood/spurts/bloodSpurt7.tres")]
var pawnScene = preload("res://assets/entities/pawnEntity/pawnEntity.tscn").duplicate()
var menuScenes = [preload("res://assets/scenes/menu/menuScenes/menuscene1.tscn"),preload("res://assets/scenes/menu/menuScenes/menuScene2.tscn"),preload("res://assets/scenes/menu/menuScenes/menuScene3.tscn")]

signal freeOrphans
#Global Sound Player
var soundPlayer = AudioStreamPlayer.new()
var sounds : Dictionary = {"healSound" = preload("res://assets/sounds/ui/rareItemFound.wav"),
			"alertSound" = preload("res://assets/sounds/ui/uialert.wav"),
			"startGame" = preload("res://assets/sounds/ui/menu/Button start.wav")
			}



#Misc
var lastConsolePosition : Vector2 = Vector2(25,62)
const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var worldMapUI : PackedScene = preload("res://assets/scenes/ui/mapOverview/mapScreen.tscn")
var customizationUI : PackedScene = preload("res://assets/scenes/ui/customization/customizationUI.tscn")
var orphanedData := []
var richPresenceEnabled:bool = false
var activeCamera : PlayerCamera = null
var debugEnabled:bool = false
var pawnDebug : bool = false

#Settings
var userDir = DirAccess.open("user://")

#Ingame
var purchasedPlacables : Array[PackedScene] = [load("res://assets/entities/props/radio.tscn"),load("res://assets/entities/props/hospitalCozyChair.tscn")]
var deathTween : Tween
var bulletTime : bool = false
var canBulletTime : bool = true
var temporaryPawnInfo : Array
var playerPosition : Vector3 = Vector3.ZERO
var playerPawns : Array[BasePawn] = []
var controllerSens : float = 0.015
var deadzone : float = 0.1
var defaultFOV : int = 90

#World
var targetedEnemies : Array[AIComponent]
var loadScene = null
var allPawns : Array[BasePawn]
const bloodPool : PackedScene = preload("res://assets/entities/bloodPool/bloodPool.tscn")
const tempImages : Array = ["res://assets/scenes/ui/saveloadmenu/save1.png","res://assets/scenes/ui/saveloadmenu/save2.png","res://assets/scenes/ui/saveloadmenu/save3.png","res://assets/scenes/ui/saveloadmenu/save4.png","res://assets/misc/db7.png"]
var saveOverwrite : String
var currentSave : String
var dialogueCamLerpSpeed:float = 5.0
var world : WorldScene
var pauseMenu : PauseMenu
const bloodDecal = preload("res://assets/entities/bloodSplat/bloodSplat1.tscn")
const bloodDrop = preload("res://assets/entities/emitters/bloodDroplet/bloodDrop.tscn")

#Multiplayer
var isMultiplayerGame:bool = false

const dialogue_cam : PackedScene = preload("res://assets/entities/camera/DialogueCamera.tscn")



# Called when the node enters the scene tree for the first time.
func _ready()->void:
	add_child(soundPlayer)
	initializeSteam()
	DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))
	soundPlayer.name = "globalSoundPlayer"
	if !userDir.dir_exists("saves"):
		userDir.make_dir("saves")
	process_mode = Node.PROCESS_MODE_ALWAYS
	soundPlayer.bus = "Sounds"
	if richPresenceEnabled:
		pass

func cleanupWorld()->void:
	physEntityCheck()
	await decalAmountCheck()
	#worldCleanup.emit()



func _process(delta: float) -> void:
	#Set audio pitch to match timescale
	AudioServer.playback_speed_scale = Engine.time_scale
	#physEntityCheck()
	#DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))

func burnTarget(node:Node3D,burnTime:float=10,burnDamage:float=3.5):
	if node.has_method("hit") or node.has_meta("isFlammable") and node.get_meta("isFlammable") == true and !node.get_meta("isBurning"):
		node.set_meta("isBurning", true)
		var burner = preload("res://assets/entities/emitters/burnEffect/burnEffect.tscn").instantiate()
		node.add_child(burner)
		burner.burnTime = burnTime
		burner.burnTarget = node
		burner.burnDamage = burnDamage
		burner.global_rotation = Vector3.ZERO

func freeOrphanNodes():
	var keep := []
	for node in orphanedData:
		if is_instance_valid(node):
			if !node.is_inside_tree() and not node.is_queued_for_deletion():
				print("Deleted : %s"%node)
				orphanedData.erase(node)
				node.queue_free()
			#else:
				#keep.append(node)

	#print("Kept : %s"%keep)
	#orphanedData = keep
	freeOrphans.emit()


func doKillEffect(pawn:BasePawn,deathDealer:BasePawn)->void:
	if deathDealer != null and !deathDealer.isPawnDead and is_instance_valid(deathDealer) and is_instance_valid(pawn):
		if deathDealer.currentItem != null:
			if deathDealer.currentItem.weaponResource.headDismember:
				pawn.healthComponent.killedWithDismemberingWeapon.emit()
		if !pawn.healthComponent.killerSignalEmitted:
			if pawn.healthComponent.componentOwner is BasePawn:
				deathDealer.killedPawn.emit()
				pawn.healthComponent.killerSignalEmitted = true

		if deathDealer.healthComponent.health < deathDealer.healthComponent.defaultHP and !deathDealer.healthComponent.isDead and deathDealer.isPlayerPawn():
			deathDealer.healthComponent.setHealth(deathDealer.healthComponent.health+35)

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


func onPlayerDeath()->void:
	var deathScreen = load("res://assets/scenes/ui/deathScreen/deathScreen.tscn")
	gameManager.activeCamera.hud.disableHud()
	await get_tree().create_timer(0.7).timeout
	add_child(deathScreen.instantiate())

func modify_persistent_data(key : String, value : Variant) -> void:
	var data = get_persistent_data()
	data[key] = value
	write_persistent_data(data)


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

func removeAllDeathScreens()->void:
	for i in get_children():
		if i.is_in_group(&"DeathScreen"):
			i.fadeOut()


func _input(_event)->void:
	if Input.is_action_just_pressed("aFullscreen"):
		pass

	if Input.is_action_just_pressed("dReloadGame"):
		restartGame()

	if Input.is_action_just_pressed("dRestartScene"):
		if get_tree().paused == false:
			await Fade.fade_out(0.3).finished
			loadWorld(get_tree().current_scene.scene_file_path)
			musicManager.fade_all_audioplayers_out(0.5)

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

func getCurrentPawn()->BasePawn:
	if activeCamera.followingEntity is BasePawn:
		return activeCamera.followingEntity
	else: return null

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
	var curr = get_tree().current_scene.scene_file_path
	playerPawns.clear()
	targetedEnemies.clear()
	allPawns.clear()
	musicManager.fade_all_audioplayers_out(0.5)
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

func notifyCheck(text : String, position : NOTIF_POSITION = 2, fade_time : float = -1, texture : Texture = Notifications.checkmarkTexture,sound:bool = true):
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


func createDroplet(position:Vector3, velocity : Vector3 = Vector3.ZERO, amount : int = 1):
	if is_instance_valid(world):
		for i in amount:
			var flipVel = [true,false].pick_random()
			var droplet : BloodDroplet = bloodDrop.instantiate()
			world.worldParticles.add_child(droplet)
			droplet.global_position = position
			if !flipVel:
				droplet.velocity += velocity
			else:
				droplet.velocity += -velocity



func getEventSignal(event : StringName) -> Signal:
	event = &"__gameEventSignals__" + str(event)
	if !has_user_signal(event):
		add_user_signal(event)
	return Signal(self, event)

func showMouse()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hideMouse()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func isMouseHidden()->bool:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		return true
	else:
		return false

func playSound(stream,volume:float = 2.0,bus:StringName = &"UI")->void:
	soundPlayer.stream = stream
	#print(soundPlayer.stream)
	soundPlayer.bus = bus
	soundPlayer.volume_db = volume
	soundPlayer.playing = true
	soundPlayer.play()

	if soundPlayer.playing:
		var dupePlayer : AudioStreamPlayer = soundPlayer.duplicate()
		add_child(dupePlayer)
		dupePlayer.finished.connect(dupePlayer.queue_free)
		dupePlayer.stream = stream
		#print(soundPlayer.stream)
		dupePlayer.bus = bus
		dupePlayer.volume_db = volume
		dupePlayer.playing = true
		dupePlayer.play()

func getGlobalSound(soundname: String):
	if sounds.get(soundname) != null:
		return sounds.get(soundname)

func initializeSteam()->void:
	return
	#var initialize_response: Dictionary = Steam.steamInitEx()
	#print("Did Steam initialize?: %s " % initialize_response)
#
	#if initialize_response['status'] > 0:
		#print("Failed to initialize Steam, shutting down: %s" % initialize_response)
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


func clearTemporaryPawnInfo()->void:
	temporaryPawnInfo.clear()

func saveTemporaryPawnInfo()->void:
	for p in playerPawns.size():
		if playerPawns[p] !=null:
			clearTemporaryPawnInfo()
			var info = playerPawns[p].savePawnInformation()
			temporaryPawnInfo.insert(p,info)
			#temporaryPawnInfo.append(info)

func showHUD()->void:
	for player in playerPawns:
		if player.attachedCam:
			player.attachedCam.hud.fadeHudIn()

func hideHUD()->void:
	for player in playerPawns:
		if player.attachedCam:
			player.attachedCam.hud.fadeHudOut()


func loadWorld(worldscene:String, fadein:bool = false)->void:
	saveTemporaryPawnInfo()
	targetedEnemies.clear()
	playerPawns.clear()
	get_tree().change_scene_to_file("res://assets/scenes/menu/loadingscreen/emptyLoaderScene.tscn")
	await get_tree().process_frame
	allPawns.clear()
	#freeOrphanNodes()
	musicManager.fade_all_audioplayers_out()
	var loader = load("res://assets/scenes/menu/loadingscreen/loadingScreen.tscn")
	var inst = loader.instantiate()
	if fadein:
		await Fade.fade_in(0.5).finished
	#freeOrphanNodes()
	get_tree().current_scene.add_child(inst)
	inst.sceneToLoad = worldscene

func saveGame(saveName:String = "Save1"):
	if world != null:
		var saveDir = DirAccess.open("user://saves")
		saveDir.make_dir(saveName)
		var saveFile = FileAccess.open("user://saves/%s/%s.pwnSave"%[saveName,saveName],FileAccess.WRITE)
		currentSave = "user://saves/%s/%s.pwnSave"%[saveName,saveName]
		var screenshot = get_viewport().get_texture().get_image()
		screenshot.save_png("user://saves/%s/%s.png"%[saveName,saveName])
		print("user://saves/%s/%s.png"%[saveName,saveName])
		var pawnFile = playerPawns[0].savePawnFile(playerPawns[0].savePawnInformation(),"user://saves/%s/%s"%[saveName,saveName])
		var saveDict : Dictionary = {
			"saveName" : saveName,
			"prologueComplete" : get_persistent_data()["seen_prologue"],
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
		modify_persistent_data("lastSaveData", saveDict)
		modify_persistent_data("lastSave", currentSave)
		#print(get_persistent_data()["lastSaveData"])
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
				modify_persistent_data("lastSave", save)
				loadWorld(nodeData["scene"])
				modify_persistent_data("lastSaveData", nodeData)
				#print(get_persistent_data()["lastSaveData"])
				#purchasedPlacables = nodeData["purchasePlacables"]
				#temporaryPawnInfo.clear()
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

func initWorldMap()->void:
	removeShop()
	removeCustomization()
	gameManager.pauseMenu.canPause = false
	var _WorldMapUI = worldMapUI.instantiate()
	_WorldMapUI.add_to_group(&"worldMap")
	add_child(_WorldMapUI)


func initCustomization(pawn:BasePawn)->void:
	removeShop()
	removeCustomization()
	removeWorldMap()
	gameManager.pauseMenu.canPause = false
	var _customizationUI = customizationUI.instantiate()
	_customizationUI.add_to_group(&"customizationUI")
	add_child(_customizationUI)
	#hideAllPlayers()
	_customizationUI.clothingPawn = pawn
	_customizationUI.generateClothingOptions(pawn)

func removeWorldMap()->void:
	for i in get_children():
		if i.is_in_group(&"worldMap"):
			i.queue_free()


func removeCustomization()->void:
	for i in get_children():
		if i.is_in_group(&"customizationUI"):
			i.queue_free()
	#gameManager.pauseMenu.canPause = true


func initShop(pawn:BasePawn,shopData:ShopData)->void:
	removeShop()
	removeCustomization()
	var shopUI : PackedScene = load("res://assets/scenes/ui/shopui/shopUI.tscn")
	var _shop = shopUI.instantiate()
	_shop.add_to_group(&"shop")
	_shop.shopResource = shopData
	add_child(_shop)
	hideAllPlayers()
	_shop.initializeShop()

func removeShop()->void:
	for i in get_children():
		if i.is_in_group(&"shop"):
			i.queue_free()
	#gameManager.pauseMenu.canPause = true

func removeSafehouseEditor()->void:
	await Fade.fade_out(0.5).finished
	for i in get_children():
		if i.is_in_group(&"safehouseEditor"):
			i.queue_free()
	showAllPlayers()
	gameManager.activeCamera.posessObject(playerPawns[0],playerPawns[0].followNode)
	Fade.fade_in(0.5)
	gameManager.activeCamera.hud.enableHud()


func setMotionBlur(camera:Camera3D)->void:
	if !UserConfig.configs_updated.is_connected(setMotionBlur.bind(camera)):
		UserConfig.configs_updated.connect(setMotionBlur.bind(camera))
	if UserConfig.graphics_motion_blur:
		if camera.compositor == null:
			var comp = load("res://assets/envs/mBlurCompositor.tres")
			camera.compositor = comp
		else:
			camera.compositor.compositor_effects[0].set("enabled",true)
			camera.compositor.compositor_effects[1].set("enabled",true)
	else:
		var comp = load("res://assets/entities/camera/testComp.tres")
		camera.compositor = comp
			#camera.compositor.compositor_effects[0].set("enabled",false)
			#camera.compositor.compositor_effects[1].set("enabled",false)



func doDeathEffect()->void:
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	if deathTween:
		deathTween.kill()
	deathTween = create_tween()
	if UserConfig.game_slow_motion_death:
		Engine.time_scale = 0.25
	deathTween.tween_property(Engine,"time_scale",1,1.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func createSplat(gposition:Vector3 = Vector3.ONE,normal:Vector3 = Vector3.ONE,parent : Node3D = world.worldMisc)->Node3D:
	if is_instance_valid(parent):
		var _b = bloodDecal.instantiate()
		parent.add_child(_b)
		if parent.has_node(_b.get_path()) and _b.is_inside_tree():
			_b.position = gposition
			if !_b.global_transform.origin == gposition:
				_b.look_at(_b.global_transform.origin + normal.round(), Vector3.UP)
			return _b
		else:
			_b.queue_free()
			return null
	return null

func sprayBlood(position:Vector3,amount:int,_maxDistance:int,distanceMultiplier:float = 1)->void:
	if is_instance_valid(world):
		for rays in amount:
			var directSpace : PhysicsDirectSpaceState3D = world.worldMisc.get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.new()
			var result : Dictionary
			ray = ray.create(position,position + Vector3(randi_range(-_maxDistance,_maxDistance),randi_range(-_maxDistance,_maxDistance),randi_range(-_maxDistance,_maxDistance)*distanceMultiplier),1)
			result = directSpace.intersect_ray(ray)
			if result:
				createSplat(result.position,result.normal)
				if debugEnabled:
					var meshInstance : MeshInstance3D = MeshInstance3D.new()
					var mesh = ImmediateMesh.new()
					var meshMat : StandardMaterial3D = StandardMaterial3D.new()
					meshMat.albedo_color = Color.BLUE
					world.worldMisc.add_child(meshInstance)
					meshInstance.mesh = mesh
					mesh.surface_begin(Mesh.PRIMITIVE_LINES)
					mesh.surface_add_vertex(position)
					mesh.surface_add_vertex(result.position)
					mesh.surface_end()
					meshInstance.material_override = meshMat

func initializeSafehouseEditor()->void:
	gameManager.pauseMenu.canPause = false
	removeWorldMap()
	removeShop()
	removeCustomization()
	await Fade.fade_out(0.3).finished
	var editorUI : PackedScene = load("res://assets/scenes/ui/safehouseEditor/safehouseEditor.tscn")
	var safehouseEditor = editorUI.instantiate()
	safehouseEditor.add_to_group(&"safehouseEditor")
	add_child(safehouseEditor)
	hideAllPlayers()
	safehouseEditor.initEditor()
	Fade.fade_in(0.5)


func createBloodPool(position:Vector3,size:float=0.5)->void:
	if world != null:
		var directSpace : PhysicsDirectSpaceState3D = world.worldMisc.get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.new()
		var result : Dictionary
		ray = ray.create(position,position + Vector3.DOWN,1)
		result = directSpace.intersect_ray(ray)
		if result:
			var _bloodPool = bloodPool.instantiate()
			world.worldMisc.add_child(_bloodPool)
			_bloodPool.global_position = result.position
			_bloodPool.startPool(size)


func getShortTweenAngle(currentAngle:float,targetAngle:float)->float:
	return currentAngle + wrapf(targetAngle-currentAngle,-PI,PI)


func disableBulletTime()->void:
	if activeCamera:
		activeCamera.hud.flashColor(Color.WHITE)
		activeCamera.hud.bulletTimeOff.play()
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	if deathTween:
		deathTween.kill()
	deathTween = create_tween()
	deathTween.parallel().tween_property(Engine,"time_scale",1,2).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	bulletTime = false

func enableBulletTime()->void:
	if activeCamera:
		activeCamera.hud.flashColor(Color.WHITE)
		activeCamera.hud.bulletTimeOn.play()
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	if deathTween:
		deathTween.kill()
	deathTween = create_tween()
	deathTween.parallel().tween_property(Engine,"time_scale",0.55,1.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	bulletTime = true


func setSoundVariables(sound:AudioStreamPlayer3D,bus:StringName = &"Sounds")->void:
	#Set the sound's variables to sound correctly and not muffled as well as assigning it to a bus if its not already.
	sound.max_polyphony = 2
	sound.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	#sound.max_db = 15
	sound.max_distance = 0
	sound.unit_size = 10
	sound.bus = bus
	sound.attenuation_filter_db = 0
	sound.attenuation_filter_cutoff_hz = 3000

func create_surface_transform(origin : Vector3, incoming_vector : Vector3, surface_normal : Vector3) -> Transform3D:
	var y = surface_normal
	var z = incoming_vector.cross(surface_normal)
	var x = surface_normal.cross(z)
	var tf := Transform3D(x.normalized(), y.normalized(), z.normalized(), origin).rotated_local(Vector3.UP, PI/2)
	return tf


func createGib(position:Vector3, velocity : Vector3 = Vector3.ONE)->FakePhysicsEntity:
	var gib = [preload("res://assets/entities/gore/dismemberGib.tscn"),preload("res://assets/entities/gore/dismemberGib2.tscn")].pick_random()
	var inst = gib.instantiate()
	inst.velocity.y = velocity.y * randf_range(5, 16)
	inst.velocity.x = velocity.x * randf_range(-2, 2)
	inst.velocity.z = velocity.z * randf_range(-2, 2)
	gameManager.world.add_child(inst)
	inst.global_position = position
	return inst


func hideAllPlayers()->void:
	for players in playerPawns:
		players.hide()
		if players.currentItem:
			players.currentItem.hide()


func showAllPlayers()->void:
	for players in playerPawns:
		players.show()
		if players.currentItem:
			players.currentItem.show()


func pick_weighted(weightedArray:Array) -> int:
	#Sum all of the odds
	var sum := get_weight_sum(weightedArray)
	var random_selector = randf_range(0, sum)
	#Subtract each element until random_selector is 0
	var chosen_index : int = 0
	for idx in weightedArray.size():
		random_selector -= weightedArray[idx]
		if random_selector <= 0.0:
			chosen_index = idx
			break
	return chosen_index

func createSoundAtPosition(stream:AudioStream,position:Vector3):
	var aud = AudioStreamPlayer3D.new()
	if world:
		world.worldMisc.add_child(aud)
		setSoundVariables(aud)
		aud.stream = stream
		aud.finished.connect(aud.queue_free)
		aud.play()

func get_weight_sum(weightedArray) -> float:
	var sum : float
	for i in weightedArray:
		sum += i
	return sum


func decalAmountCheck()->void:
	var decals = Engine.get_main_loop().get_nodes_in_group(&"decal")
	#print(decals)
	while decals.size() > UserConfig.game_max_decals:
		if is_instance_valid(decals[0]):
			if decals[0].has_method("deleteSplat"):
				decals[0].deleteSplat()
			elif decals[0].has_method("deletePool"):
				decals[0].deletePool()
			elif decals[0].has_method("deleteHole"):
				decals[0].deleteHole()
			decals.remove_at(0)
	return


func physEntityCheck()->void:
	var physEntities : Array = Engine.get_main_loop().get_nodes_in_group(&"physicsEntity")
	#print(physEntities)
	while physEntities.size() > UserConfig.game_max_physics_entities:
		if is_instance_valid(physEntities[0]):
			physEntities[0].queue_free()
			physEntities.remove_at(0)
	return
