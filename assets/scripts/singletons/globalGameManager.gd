extends Node
## Global Game Manager Start

#region Signals
# Signals
signal exitedWorldMap
signal freeOrphans
signal worldLoaded
#endregion

#region Pooling
#BloodDroplet Pooling
const MAX_DROPLETS = 64
var droplet_pool: Array[BloodDroplet] = []
var droplet_index := 0

#endregion

#region Constants
# Constants
const defaultTweenSpeed: float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
const bloodPool: PackedScene = preload("res://assets/entities/bloodPool/bloodPool.tscn")
const bloodDecal = preload("res://assets/entities/bloodSplat/bloodSplat1.tscn")
const bloodDrop = preload("res://assets/entities/emitters/bloodDroplet/bloodDrop.tscn")
const tempImages: Array = [
	"res://assets/scenes/ui/saveloadmenu/save1.png",
	"res://assets/scenes/ui/saveloadmenu/save2.png",
	"res://assets/scenes/ui/saveloadmenu/save3.png",
	"res://assets/scenes/ui/saveloadmenu/save4.png",
	"res://assets/misc/db7.png"
]
const dialogue_cam: PackedScene = preload("res://assets/entities/camera/DialogueCamera.tscn")
#endregion

#region Scenes and resources
# Scenes and resources
var phoneUI: PackedScene = preload("res://assets/scenes/ui/phoneUI/phoneUI.tscn")
var bloodSpurts: Array[StandardMaterial3D] = [
	preload("res://assets/materials/blood/spurts/bloodSpurt.tres"),
	preload("res://assets/materials/blood/spurts/bloodSpurt2.tres"),
	preload("res://assets/materials/blood/spurts/bloodSpurt3.tres"),
	preload("res://assets/materials/blood/spurts/bloodSpurt4.tres"),
	preload("res://assets/materials/blood/spurts/bloodSpurt5.tres"),
	preload("res://assets/materials/blood/spurts/bloodSpurt6.tres"),
	preload("res://assets/materials/blood/spurts/bloodSpurt7.tres")
]
var pawnScene = preload("res://assets/entities/pawnEntity/pawnEntity.tscn").duplicate()
var menuScenes = [
	preload("res://assets/scenes/menu/menuScenes/menuscene1.tscn"),
	preload("res://assets/scenes/menu/menuScenes/menuScene2.tscn"),
	preload("res://assets/scenes/menu/menuScenes/menuScene3.tscn")
]
var defaultPawnTreeRoot = load("res://assets/entities/pawnEntity/pawnEntityTree.tres")
var worldMapUI: PackedScene = preload("res://assets/scenes/ui/mapOverview/mapScreen.tscn")
var customizationUI: PackedScene = preload("res://assets/scenes/ui/customization/customizationUI.tscn")
#endregion

#region Global Sound Player
# Global Sound Player
var soundPlayer = AudioStreamPlayer.new()
var sounds: Dictionary = {
	"healSound" = preload("res://assets/sounds/ui/rareItemFound.wav"),
	"alertSound" = preload("res://assets/sounds/ui/uialert.wav"),
	"startGame" = preload("res://assets/sounds/ui/menu/Button start.wav")
}
#endregion

#region Misc
# Misc
var ragdolls: Array
var physEntities: Array
var decals : Array
var lastConsolePosition: Vector2 = Vector2(25, 62)
var orphanedData := []
var richPresenceEnabled: bool = false
var activeCamera: PlayerCamera = null
var debugEnabled: bool = false
var pawnDebug: bool = false
#endregion

#region Settings
# Settings
var userDir = DirAccess.open("user://")
#endregion

#region Ingame
# Ingame
var purchasedPlacables: Array[PackedScene] = [
	load("res://assets/entities/props/radio.tscn"),
	load("res://assets/entities/props/hospitalCozyChair.tscn")
]
var deathTween: Tween
var bulletTime: bool = false
var canBulletTime: bool = true
var temporaryPawnInfo: Array
var playerPosition: Vector3 = Vector3.ZERO
var playerPawns: Array[BasePawn] = []
var controllerSens: float = 0.015
var deadzone: float = 0.1
var defaultFOV: int = 90
#endregion

#region World
# World
var targetedEnemies: Array[AIComponent]
var loadScene = null
var allPawns: Array[BasePawn]
var saveOverwrite: String
var currentSave: String
var dialogueCamLerpSpeed: float = 5.0
var world: WorldScene
var pauseMenu: PauseMenu
#endregion

#region Multiplayer
# Multiplayer
var isMultiplayerGame: bool = false
#endregion

#region Lifecycle
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SmackneckClient.masterserver_connected.connect(sm_PushGame)
	worldLoaded.connect(initDropletPool)
	worldLoaded.connect(giveModifierToPlayers)
	UserConfig.configs_updated.connect(cleanupChecker)
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
	await get_tree().process_frame
	SmackneckClient.connect_to_masterserver()

func sm_PushGame()->void:
	SmackneckClient.put_message("MESSAGE",{"msg":"set_game", "game": "Delta Bullet"})

func cleanupChecker()->void:
	if decals.size() >= UserConfig.game_max_decals:
		for i in decals:
			if is_instance_valid(i):
				if i.has_method("deleteSplat"):
					i.call_deferred("deleteSplat")
				elif i.has_method("deletePool"):
					i.call_deferred("deletePool")
				elif i.has_method("deleteHole"):
					i.call_deferred("deleteHole")
			else:
				decals.erase(i)
		decals.clear()

	if physEntities.size() >= UserConfig.game_max_physics_entities:
		for i in physEntities:
			if is_instance_valid(i):
				i.queue_free()
			else:
				decals.erase(i)
		physEntities.clear()


func _process(delta: float) -> void:
		#physEntities = Engine.get_main_loop().get_nodes_in_group(&"physicsEntity")
		#decals = Engine.get_main_loop().get_nodes_in_group(&"decal")

	#Set audio pitch to match timescale
	AudioServer.playback_speed_scale = Engine.time_scale
	#physEntityCheck()
	#DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))
#endregion

#region Gameplay Effects
func pawnKillSlowMo()->void:
	if gameManager.getCurrentPawn() and !gameManager.bulletTime:
		gameManager.bulletTime = false
		Engine.time_scale = 0.3
		var tween = gameManager.world.create_tween()
		tween.tween_property(Engine,"time_scale",1,1)

func burnTarget(node: Node3D, burnTime: float = 10, burnDamage: float = 3.5):
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
#endregion

#region Pooling Funcs
func initDropletPool()->void:
	droplet_pool.clear()
	for i in MAX_DROPLETS:
		var d : BloodDroplet = preload("res://assets/entities/emitters/bloodDroplet/bloodDrop.tscn").instantiate()
		d.hide()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			droplet_pool.append(d)

#endregion

#region Phone Calls
func queuePhoneCall(dialogue: ActorDialogue) -> void:
	if getCurrentPawn():
		getCurrentPawn().queuedPhoneCall = dialogue
		#getCurrentPawn().playPhoneCall()

func queueAndPlayPhoneCall(dialogue: ActorDialogue) -> void:
	if getCurrentPawn():
		getCurrentPawn().queuedPhoneCall = dialogue
		getCurrentPawn().playPhoneCall()

func stopPhoneCall() -> void:
	if world:
		for i in get_tree().get_nodes_in_group(&"phonecall"):
			i.queue_free()

func removeDialogue2D()->void:
	for i in get_tree().get_nodes_in_group(&"phonecall"):
		i.queue_free()

func playDialogue2D(dialogue: ActorDialogue) -> AudioStreamPlayer:
	if world:
		var audioPlayer = AudioStreamPlayer.new()
		audioPlayer.add_to_group(&"phonecall")
		world.worldMisc.add_child(audioPlayer)
		audioPlayer.bus = &"VO"
		await get_tree().process_frame
		audioPlayer.volume_db = AudioServer.get_bus_volume_db(5)
		#print(dialogue.actorAudios.size())
		if audioPlayer and is_instance_valid(dialogue):
			for i in dialogue.actorAudios.size():
				var subtitle
				audioPlayer.bus = &"VO"
				audioPlayer.volume_db = AudioServer.get_bus_volume_db(5)
				#print(i)
				if i == dialogue.actorAudios.size() - 1:
					audioPlayer.finished.connect(audioPlayer.queue_free)
				if getCurrentPawn():
					subtitle = getCurrentPawn().attachedCam.createSubtitle(dialogue.actorAudios[i].audioResource)
				audioPlayer.stream = dialogue.actorAudios[i].audioResource.audioStream
				audioPlayer.stream_paused = false
				audioPlayer.play()
				await audioPlayer.finished
				if subtitle:
					subtitle.queue_free()
				await get_tree().create_timer(dialogue.actorAudios[i].timeBetweenAudio, false)
		return audioPlayer
	else:
		return null
#endregion

#region Modifiers
func giveModifierToPlayers()->void:
	if world:
		await get_tree().process_frame
		for players in playerPawns:
			var p = players
			for i in gameState.getPawnSkills():
				give_stat_modifier(p,i["name"])

func getModifierFromName(modName: String):
	for i in DirAccess.get_files_at("res://assets/entities/modifiers/"):
		if i == modName + ".tscn":
			return "res://assets/entities/modifiers/%s"%i

func hasModifier(modName: String)->bool:
	var result : bool = false
	for i in gameState.getGameState()["skills"]:
		if i["name"] == modName:
			result = true
	return result

func give_stat_modifier(parent: Node, mod: String):
	if parent.has_node(^"statModifierStack"):
		var stack = parent.get_node(^"statModifierStack")
		var modifier = load(getModifierFromName(mod))
		if modifier:
			if !stack.has_node(mod):
				stack.add_child(modifier.instantiate())
				if !hasModifier(mod):
					gameState.addToSkills(mod)
				if debugEnabled:
					notify_warn("Added stat modifier '%s' to '%s'" % [mod, parent.name], 2, 2)
			else:
				if debugEnabled:
					notify_warn("Stat modifier '%s' already exists on '%s'" % [mod, parent.name], 2, 2)


func get_modified_stat(node: Node, stat: StringName) -> float:
	var base = node.get(stat)
	if base == null:
		return 0.0
	var stack = get_modifier_stack(node)
	return stack.get_modified_stat(stat, base)


func get_modifier_stack(node: Node) -> StatModifierStack:
	if node.has_node(^"statModifierStack"):
		return node.get_node(^"statModifierStack")
	var new = StatModifierStack.new()
	node.add_child(new)
	return new
#endregion

#region Player Stat Setters
func setBasePlayerBulletResistMod(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().bulletResistanceModifier = value

func setBasePlayerBlastResistMod(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().blastResistanceModifier = value

func setBasePlayerReloadSpeed(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().reloadSpeedModifier = value

func setBasePlayerDamageMod(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().damageModifier = value

func setBasePlayerSpreadMod(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().spreadModifier = value

func setBasePlayerRecoilMod(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().recoilModifier = value

func setBasePlayerFireRateMod(value: float = 1):
	if getCurrentPawn():
		getCurrentPawn().fireRateModifier = value
#endregion

#region Phone Menu
func removePhoneMenu() -> void:
	for i in get_children():
		if i.is_in_group(&"phone"):
			i.queue_free()
			#hideMouse()


func initializePhoneMenu(pawn: BasePawn) -> void:
	gameManager.pauseMenu.canPause = false
	var phoneInst = phoneUI.instantiate()
	var phoneHolder = CanvasLayer.new()
	add_child(phoneHolder)
	phoneHolder.layer = 2
	phoneHolder.add_to_group(&"phone")
	phoneHolder.add_child(phoneInst)
	phoneInst.init(pawn)
	showMouse()
#endregion

#region Death Effects
func doKillEffect(pawn: BasePawn, deathDealer: BasePawn) -> void:
	if deathDealer != null and !deathDealer.isPawnDead and is_instance_valid(deathDealer) and is_instance_valid(pawn):
		if deathDealer.currentItem != null:
			if deathDealer.currentItem.weaponResource.headDismember:
				pawn.healthComponent.killedWithDismemberingWeapon.emit()
		if !pawn.healthComponent.killerSignalEmitted:
			if pawn.healthComponent.componentOwner is BasePawn:
				deathDealer.killedPawn.emit()
				pawn.healthComponent.killerSignalEmitted = true

		if deathDealer.healthComponent.health < deathDealer.healthComponent.defaultHP and !deathDealer.healthComponent.isDead and deathDealer.isPlayerPawn():
			deathDealer.healthComponent.setHealth(deathDealer.healthComponent.health + 35)


func onPlayerDeath() -> void:
	var deathScreen = load("res://assets/scenes/ui/deathScreen/deathScreen.tscn")
	gameManager.activeCamera.hud.disableHud()
	await get_tree().create_timer(0.7).timeout
	add_child(deathScreen.instantiate())
#endregion

#region Camera
func create_dialogue_camera() -> CutsceneCamera:
	var new_cam = dialogue_cam.instantiate()
	return new_cam
#endregion

#region Physics Materials
func getColliderPhysicsMaterial(collider: Object) -> DB_PhysicsMaterial:
	var phys_mat: DB_PhysicsMaterial = collider.get(&"physics_material_override")
	if collider.has_meta(&"physics_material_override"):
		#print("Using meta for physics mat")
		phys_mat = collider.get_meta(&"physics_material_override")
	if phys_mat == null and !collider.has_meta(&"no_bhole"):
		#print("No physics mat found, using generic...")
		phys_mat = preload("res://assets/resources/PhysicsMaterials/generic_physics_material.tres")
	return phys_mat
#endregion

#region Death Screen
func removeAllDeathScreens() -> void:
	for i in get_children():
		if i.is_in_group(&"DeathScreen"):
			i.fadeOut()
#endregion

#region Input
func _input(_event) -> void:
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
			var cast: RayCast3D = gameManager.activeCamera.debugCast
			if cast:
				if cast.is_colliding():
					if cast.get_collider().is_in_group("Posessable"):
						gameManager.activeCamera.unposessObject(true)
						gameManager.activeCamera.posessObject(cast.get_collider(), cast.get_collider().followNode)
					else:
						Console.add_console_message("Cannot posess %s, Its not possessable"%cast.get_collider())
			else:
				Console.add_console_message("You can't posess nothing dipshit. Look at a pawn.")
#endregion

#region Pawn/Player
func getCurrentPawn() -> BasePawn:
	if activeCamera.followingEntity is BasePawn:
		return activeCamera.followingEntity
	else: return null
#endregion

#region Screenshot
func takeScreenshot(path: String = "user://screenshots", screenshotName: String = "") -> String:
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
			screenshot.save_png("%s/%s.png" % [path, screenshotName])
			savedfilepath = "%s/%s.png" % [path, screenshotName]
	else:
		userDir.make_dir(path)
		var _screenshot_dir = DirAccess.open(path)
		if screenshotName == "" or " ":
			screenshot.save_png("%s/screenshot_" + str(screenshot_count) + ".png")
			savedfilepath = "%s/screenshot_" + str(screenshot_count) + ".png"
			screenshot_count = screenshot_count + 1
		else:
			screenshot.save_png("%s/%s.png" % [path, screenshotName])
			savedfilepath = "%s/%s.png" % [path, screenshotName]
	print("Saved screenshot at %s/%s.png" % [path, screenshotName])
	return savedfilepath
#endregion

#region Sound Play
func playSound2D(sound:String,bus = &"UI")->AudioStreamPlayer:
	var _sound : AudioStream = load(sound)
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = _sound
	player.finished.connect(player.queue_free)
	player.play()
	return player
#region Scene Management
func restartScene() -> void:
	#var curr = get_tree().current_scene.scene_file_path
	playerPawns.clear()
	targetedEnemies.clear()
	allPawns.clear()
	musicManager.fade_all_audioplayers_out(0.5)
	await Fade.fade_out(0.3, Color(0, 0, 0, 1), "GradientVertical", false, true).finished
	get_tree().reload_current_scene()

func restartGame() -> void:
	get_tree().unload_current_scene()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://assets/scenes/menu/logo.tscn")
#endregion

#region BBCode
func strip_bbcode(bbcode_text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[(.+?)\\]")
	return regex.sub(bbcode_text, "", true)
#endregion

#region Notifications
enum NOTIF_POSITION {topleft, topcenter, topright, bottomleft, bottomcenter, bottomright}
func notifyFade(text: String, position: NOTIF_POSITION = 2, fade_time: float = 3.0):
	var new_notif
	var container = Notifications.hudPositions[position]

	new_notif = Notifications.notif_fade.instantiate()
	container.add_child(new_notif)
	set_notif_flags(new_notif, position)

	new_notif.set_text(text)
	if fade_time > 0:
		new_notif.timer.start(fade_time)
	return new_notif

func notifyCheck(text: String, position: NOTIF_POSITION = 2, fade_time: float = -1, texture: Texture = Notifications.checkmarkTexture, sound: bool = true):
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

func notify_warn(text: String, position: NOTIF_POSITION = 2, fade_time: float = -1, texture: Texture = Notifications.warning_texture):
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


func notify_click(text: String, call_on_click: Callable, position: NOTIF_POSITION = 2, fade_time: float = -1, binds: Array = []):
	var new_notif: Control
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


func notify_custom(node: Control, position: NOTIF_POSITION) -> Control:
	var container = Notifications.hudPositions[position]
	container.add_child(node)
	set_notif_flags(node, position)
	return node
#endregion

#region Raycasting
func castRay(cam: Camera3D, range: float = 50000, mask := 0b10111, exceptions: Array[RID] = [], hit_areas: bool = false) -> Dictionary:
	var state = cam.get_world_3d().direct_space_state
	var transform = cam.global_transform
	var params := PhysicsRayQueryParameters3D.create(transform.origin, transform.origin - (transform.basis.z * range), 23, exceptions)
	params.collide_with_areas = hit_areas
	return state.intersect_ray(params)
#endregion

#region Update World Environment
func updateGraphics(env:WorldEnvironment)->void:
	env.get_environment().ssil_enabled = UserConfig.graphics_Ssil
	env.get_environment().ssr_enabled = UserConfig.graphics_Ssr
	env.get_environment().sdfgi_enabled = UserConfig.graphics_Sdfgi
	env.get_environment().ssao_enabled = UserConfig.graphics_Ssao
#endregion

#region Blood Effects
func createDroplet(position: Vector3, velocity: Vector3 = Vector3.ONE, amount: int = 1, normal: Vector3 = Vector3.UP, allowRandomFlip: bool = true):
	if is_instance_valid(world):
		var d = droplet_pool[droplet_index]
		droplet_index = (droplet_index + 1) % MAX_DROPLETS
		if allowRandomFlip:
			var flipVel = [true, false].pick_random()
			if !flipVel:
				d.reset(position, Vector3(velocity.x * randf_range(-1, 2), velocity.y * randf_range(-1, 2), velocity.z * randf_range(-1, 2)), normal)
			else:
				d.reset(position, -Vector3(velocity.x * randf_range(-1, 2), velocity.y * randf_range(-1, 2), velocity.z * randf_range(-1, 2)), normal)
		else:
			d.reset(position, velocity, normal)
		d.show()
		#OLD CODE
		#for i in amount:
			##var flipVel = [true,false].pick_random()
			#var droplet: BloodDroplet = bloodDrop.instantiate()
			#droplet.norm = normal
			#world.worldParticles.add_child(droplet)
			#droplet.global_position = position
			#if allowRandomFlip:
				#var flipVel = [true, false].pick_random()
				#if !flipVel:
					#droplet.velocity += Vector3(velocity.x * randf_range(-1, 2), velocity.y * randf_range(-1, 2), velocity.z * randf_range(-1, 2))
				#else:
					#droplet.velocity += -Vector3(velocity.x * randf_range(-1, 2), velocity.y * randf_range(-1, 2), velocity.z * randf_range(-1, 2))
			#else:
				#droplet.velocity += Vector3(velocity.x * randf_range(1, 3), velocity.y * randf_range(1, 3), velocity.z * randf_range(1, 3))
#endregion

#region Event Signals
func getEventSignal(event: StringName) -> Signal:
	event = StringName("__gameEventSignals__" + str(event))
	if !has_user_signal(event):
		add_user_signal(event)
	return Signal(self, event)
#endregion

#region Mouse
func showMouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hideMouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func isMouseHidden() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN
#endregion

#region Sound
func playSound(stream, volume: float = 2.0, bus: StringName = &"UI") -> void:
	soundPlayer.stream = stream
	soundPlayer.bus = bus
	soundPlayer.volume_db = volume
	soundPlayer.playing = true
	soundPlayer.play()
	if soundPlayer.playing:
		var dupePlayer: AudioStreamPlayer = soundPlayer.duplicate()
		add_child(dupePlayer)
		dupePlayer.finished.connect(dupePlayer.queue_free)
		dupePlayer.stream = stream
		dupePlayer.bus = bus
		dupePlayer.volume_db = volume
		dupePlayer.playing = true
		dupePlayer.play()


func getGlobalSound(soundname: String):
	if sounds.get(soundname) != null:
		return sounds.get(soundname)
#endregion

#region Steam
func initializeSteam() -> void:
	return
	#var initialize_response: Dictionary = Steam.steamInitEx()
	#print("Did Steam initialize?: %s " % initialize_response)
#
	#if initialize_response['status'] > 0:
		#print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		#get_tree().quit()
#endregion

#region Player Enable/Disable
func disablePlayer() -> void:
	if activeCamera != null:
		if activeCamera.followingEntity.inputComponent != null:
			activeCamera.followingEntity.direction = Vector3.ZERO
			activeCamera.followingEntity.inputComponent.movementEnabled = false
			activeCamera.followingEntity.inputComponent.mouseActionsEnabled = false

func enablePlayer() -> void:
	if activeCamera != null:
		if activeCamera.followingEntity.inputComponent != null:
			activeCamera.followingEntity.inputComponent.movementEnabled = true
			activeCamera.followingEntity.inputComponent.mouseActionsEnabled = true
#endregion

#region Mesh Surfaces
func getMeshSurfaces(mesh: Mesh) -> Array:
	var arr: Array = []
	for i in mesh.get_surface_count():
		arr.append(mesh.surface_get_material(i))
	return arr

func createOverrideFromSurfaceMaterial(meshInstance: MeshInstance3D, mesh: Mesh, id: int):
	var surface = getMeshSurfaces(mesh)[id].duplicate()
	meshInstance.set_surface_override_material(id, surface)
	return surface

func clearTemporaryPawnInfo() -> void:
	temporaryPawnInfo.clear()

func getMeshSurfaceOverrides(mesh: MeshInstance3D) -> Array:
	var arr: Array = []
	for i in mesh.get_surface_override_material_count():
		arr.append(mesh.get_surface_override_material(i))
	return arr

func saveTemporaryPawnInfo() -> void:
	for p in playerPawns.size():
		if playerPawns[p] != null:
			clearTemporaryPawnInfo()
			var info = playerPawns[p].savePawnInformation()
			temporaryPawnInfo.insert(p, info)
			#temporaryPawnInfo.append(info)
#endregion

#region HUD
func showHUD() -> void:
	for player in playerPawns:
		if player.attachedCam:
			player.attachedCam.hud.fadeHudIn()

func hideHUD() -> void:
	for player in playerPawns:
		if player.attachedCam:
			player.attachedCam.hud.fadeHudOut()
#endregion

#region Pause Menu
func getPauseMenu() -> Control:
	var menu
	if world:
		menu = world.pauseControl
	return menu
#endregion

#region World Loading
func loadWorld(worldscene: String, fadein: bool = false) -> void:
	saveTemporaryPawnInfo()
	stopPhoneCall()
	targetedEnemies.clear()
	playerPawns.clear()
	decals.clear()
	physEntities.clear()
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
#endregion

#region Scene Scanning
func scan_for_scenes(dirpath: String, max_depth: int = -1, _depth = 0) -> PackedStringArray:
	if _depth == 0:
		Console.add_rich_console_message("[color=orange]Scanning scenes at %s...[/color]" % dirpath)
	if max_depth >= 0:
		if _depth > max_depth:
			return []

	var dir = DirAccess.open(dirpath)
	var found_scenes: PackedStringArray = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".tscn") or file_name.ends_with(".scn"):
					found_scenes.append((dirpath + "/" + file_name).simplify_path())
				elif file_name.ends_with(".tscn.remap") or file_name.ends_with(".scn.remap"):
					var remapfile = "%s/%s" % [dirpath, file_name]
					var cfg = ConfigFile.new()
					cfg.load(remapfile)
					#Console.add_rich_console_message("[color=purple]%s[/color]"%cfg.get_value("remap", "path"))
					found_scenes.append(cfg.get_value("remap", "path"))
					file_name = dir.get_next()
					continue
			else:
				#is a directory
				found_scenes.append_array(scan_for_scenes((dirpath + "/" + file_name + "/").simplify_path(), max_depth, _depth + 1))
			file_name = dir.get_next()
	else:
		Console.add_rich_console_message("[color=red]An error occurred when trying to access the path.[/color]")
		print("An error occurred when trying to access the path.")

	return found_scenes

func scanForSaves(dirpath: String, max_depth: int = -1, _depth = 0) -> PackedStringArray:
	if _depth == 0:
		print("Scanning saves at %s..." % dirpath)
	if max_depth >= 0:
		if _depth > max_depth:
			return []

	var dir = DirAccess.open(dirpath)
	var foundSaves: PackedStringArray = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with("pwnSave"):
					print(file_name)
					foundSaves.append((dirpath + "/" + file_name).simplify_path())
			else:
				#is a directory
				foundSaves.append_array(scanForSaves((dirpath + "/" + file_name + "/").simplify_path(), max_depth, _depth + 1))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return foundSaves
#endregion

#region UI Initialization
func initWorldMap() -> void:
	removeShop()
	removeCustomization()
	gameManager.pauseMenu.canPause = false
	for i in playerPawns:
		if is_instance_valid(i):
			i.inputComponent.movementEnabled = false
			i.inputComponent.mouseActionsEnabled = false
	await Fade.fade_out(0.25,Color.DARK_RED).finished
	var _WorldMapUI = worldMapUI.instantiate()
	_WorldMapUI.add_to_group(&"worldMap")
	add_child(_WorldMapUI)
	Fade.fade_in(0.25,Color.DARK_RED)

func removeMapPurchasePopups()->void:
	for i in get_tree().get_nodes_in_group(&"purchaseMapAreaPopup"):
		i.close()

func initCustomization(pawn: BasePawn) -> void:
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

func removeWorldMap() -> void:
	for i in playerPawns:
		if is_instance_valid(i):
			i.inputComponent.movementEnabled = true
			i.inputComponent.mouseActionsEnabled = true
	for i in get_children():
		if i.is_in_group(&"worldMap"):
			i.queue_free()
			exitedWorldMap.emit()


func removeCustomization() -> void:
	for i in get_children():
		if i.is_in_group(&"customizationUI"):
			i.queue_free()
	#gameManager.pauseMenu.canPause = true


func initShop(pawn: BasePawn, shopData: ShopData) -> void:
	removeShop()
	removeCustomization()
	var shopUI: PackedScene = load("res://assets/scenes/ui/shopui/shopUI.tscn")
	var _shop = shopUI.instantiate()
	_shop.add_to_group(&"shop")
	_shop.shopResource = shopData
	add_child(_shop)
	hideAllPlayers()
	_shop.initializeShop()

func removeShop() -> void:
	for i in get_children():
		if i.is_in_group(&"shop"):
			i.queue_free()
	#gameManager.pauseMenu.canPause = true

func removeSafehouseEditor() -> void:
	await Fade.fade_out(0.5).finished
	for i in get_children():
		if i.is_in_group(&"safehouseEditor"):
			i.queue_free()
	showAllPlayers()
	gameManager.activeCamera.posessObject(playerPawns[0], playerPawns[0].followNode)
	Fade.fade_in(0.5)
	gameManager.activeCamera.hud.enableHud()
#endregion

#region Mouse Ray
func get_from_mouse(length: float = 1000, worldObject: Node3D = gameManager.world.worldMisc, camera: Camera3D = gameManager.activeCamera.camera, exclude: Array[RID] = []) -> Dictionary:
	var RAY_LENGTH = length
	var space_state = worldObject.get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = camera.project_ray_origin(mousepos)
	var end = origin + camera.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = exclude
	query.collide_with_areas = false

	var result = space_state.intersect_ray(query)
	return result
#endregion

#region Motion Blur
func setMotionBlur(camera: Camera3D) -> void:
	if !UserConfig.configs_updated.is_connected(setMotionBlur):
		UserConfig.configs_updated.connect(setMotionBlur.bind(camera))

	if camera.compositor is MotionBlurCompositor:
		camera.compositor.compositor_effects[0].set("enabled", UserConfig.graphics_motion_blur)
		camera.compositor.compositor_effects[1].set("enabled", UserConfig.graphics_motion_blur)
#endregion

#region Death Effect
func doDeathEffect() -> void:
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	if deathTween:
		deathTween.kill()
	deathTween = create_tween()
	if UserConfig.game_slow_motion_death:
		Engine.time_scale = 0.25
	deathTween.tween_property(Engine, "time_scale", 1, 1.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)
#endregion

#region Blood Splat
func createSplat(gposition: Vector3 = Vector3.ONE, normal: Vector3 = Vector3.ONE, parent: Node3D = world.worldMisc) -> Node3D:
	if is_instance_valid(parent):
		var _b = bloodDecal.instantiate()
		parent.add_child(_b)
		if parent.has_node(_b.get_path()) and _b.is_inside_tree():
			_b.global_transform.origin = gposition
			_b.look_at(_b.global_transform.origin + normal, Vector3.ONE)
			return _b
		else:
			_b.queue_free()
			return null
	return null

func sprayBlood(position: Vector3, amount: int, _maxDistance: int, distanceMultiplier: float = 1) -> void:
	if is_instance_valid(world):
		for rays in amount:
			var directSpace: PhysicsDirectSpaceState3D = world.worldMisc.get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.new()
			var result: Dictionary
			ray = ray.create(position, position + Vector3(randi_range(-_maxDistance, _maxDistance), randi_range(-_maxDistance, _maxDistance), randi_range(-_maxDistance, _maxDistance) * distanceMultiplier), 1)
			result = directSpace.intersect_ray(ray)
			if result:
				createSplat(result.position, result.normal)
				if debugEnabled:
					var meshInstance: MeshInstance3D = MeshInstance3D.new()
					var mesh = ImmediateMesh.new()
					var meshMat: StandardMaterial3D = StandardMaterial3D.new()
					meshMat.albedo_color = Color.BLUE
					world.worldMisc.add_child(meshInstance)
					meshInstance.mesh = mesh
					mesh.surface_begin(Mesh.PRIMITIVE_LINES)
					mesh.surface_add_vertex(position)
					mesh.surface_add_vertex(result.position)
					mesh.surface_end()
					meshInstance.material_override = meshMat
#endregion

#region Safehouse Editor
func initializeSafehouseEditor() -> void:
	gameManager.pauseMenu.canPause = false
	removeWorldMap()
	removeShop()
	removeCustomization()
	await Fade.fade_out(0.3).finished
	var editorUI: PackedScene = load("res://assets/scenes/ui/safehouseEditor/safehouseEditor.tscn")
	var safehouseEditor = editorUI.instantiate()
	safehouseEditor.add_to_group(&"safehouseEditor")
	add_child(safehouseEditor)
	hideAllPlayers()
	safehouseEditor.initEditor()
	Fade.fade_in(0.5)
#endregion

#region Blood Pool
func createBloodPool(position: Vector3, size: float = 0.5) -> void:
	if world != null:
		var directSpace: PhysicsDirectSpaceState3D = world.worldMisc.get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.new()
		var result: Dictionary
		ray = ray.create(position, position + Vector3.DOWN, 1)
		result = directSpace.intersect_ray(ray)
		if result:
			var _bloodPool = bloodPool.instantiate()
			world.worldMisc.add_child(_bloodPool)
			_bloodPool.global_position = result.position
			_bloodPool.startPool(size)
#endregion

#region Tween Angle
func getShortTweenAngle(currentAngle: float, targetAngle: float) -> float:
	return currentAngle + wrapf(targetAngle - currentAngle, -PI, PI)
#endregion

#region Bullet Time
func disableBulletTime() -> void:
	if activeCamera:
		activeCamera.hud.triggerRadialBlur(Vector2(0.5, 0.5), 0.5, 0.5)
		activeCamera.hud.flashColor(Color.WHITE)
		activeCamera.hud.bulletTimeOff.play()
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	if deathTween:
		deathTween.kill()
	deathTween = create_tween()
	deathTween.parallel().tween_property(Engine, "time_scale", 1, 2).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	bulletTime = false
	setBasePlayerRecoilMod(1)
	setBasePlayerSpreadMod(1)
	setBasePlayerBulletResistMod(1)

func enableBulletTime() -> void:
	if activeCamera:
		activeCamera.hud.triggerRadialBlur(Vector2(0.5, 0.5), 0.5, 60)
		activeCamera.hud.flashColor(Color.WHITE)
		activeCamera.hud.bulletTimeOn.play()
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	if deathTween:
		deathTween.kill()
	deathTween = create_tween()
	deathTween.parallel().tween_property(Engine, "time_scale", 0.55, 1.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	bulletTime = true
	setBasePlayerRecoilMod(2)
	setBasePlayerSpreadMod(2)
	setBasePlayerBulletResistMod(1.5)
#endregion

#region Sound Variables
func setSoundVariables(sound: AudioStreamPlayer3D, bus: StringName = &"Sounds") -> void:
	#Set the sound's variables to sound correctly and not muffled as well as assigning it to a bus if its not already.
	sound.max_polyphony = 2
	sound.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	#sound.max_db = 15
	sound.max_distance = 0
	sound.unit_size = 10
	sound.bus = bus
	sound.attenuation_filter_db = 0
	sound.attenuation_filter_cutoff_hz = 3000
#endregion

#region Surface Transform
func create_surface_transform(origin: Vector3, incoming_vector: Vector3, surface_normal: Vector3) -> Transform3D:
	var y = surface_normal
	var z = incoming_vector.cross(surface_normal)
	var x = surface_normal.cross(z)
	var tf := Transform3D(x.normalized(), y.normalized(), z.normalized(), origin).rotated_local(Vector3.UP, PI / 2)
	return tf
#endregion

#region Gibs
func createGib(position: Vector3, velocity: Vector3 = Vector3.ONE) -> FakePhysicsEntity:
	var gib = [preload("res://assets/entities/gore/dismemberGib.tscn"), preload("res://assets/entities/gore/dismemberGib2.tscn")].pick_random()
	var inst = gib.instantiate()
	inst.velocity.y = velocity.y * randf_range(5, 16)
	inst.velocity.x = velocity.x * randf_range(-2, 2)
	inst.velocity.z = velocity.z * randf_range(-2, 2)
	gameManager.world.add_child(inst)
	inst.global_position = position
	return inst
#endregion

#region Player Visibility
func hideAllPlayers() -> void:
	for players in playerPawns:
		players.hide()
		if players.currentItem:
			players.currentItem.hide()


func showAllPlayers() -> void:
	for players in playerPawns:
		players.show()
		if players.currentItem:
			players.currentItem.show()
#endregion

#region Sound At Position
func createSoundAtPosition(stream: AudioStream, position: Vector3):
	var aud = AudioStreamPlayer3D.new()
	if world:
		world.worldMisc.add_child(aud)
		setSoundVariables(aud)
		aud.stream = stream
		aud.finished.connect(aud.queue_free)
		aud.play()
#endregion

#region Decal Amount
func decalAmountCheck() -> void:
	#decals = Engine.get_main_loop().get_nodes_in_group(&"decal")
	#print(decals)
	while get_tree().get_nodes_in_group(&"decal").size() > UserConfig.game_max_decals:
		if is_instance_valid(get_tree().get_nodes_in_group(&"decal")[0]):
			if get_tree().get_nodes_in_group(&"decal")[0].has_method("deleteSplat"):
				get_tree().get_nodes_in_group(&"decal")[0].call_deferred("deleteSplat")
			elif get_tree().get_nodes_in_group(&"decal")[0].has_method("deletePool"):
				get_tree().get_nodes_in_group(&"decal")[0].call_deferred("deletePool")
			elif get_tree().get_nodes_in_group(&"decal")[0].has_method("deleteHole"):
				get_tree().get_nodes_in_group(&"decal")[0].call_deferred("deleteHole")
			get_tree().get_nodes_in_group(&"decal").remove_at(0)
			await get_tree().process_frame
			#Engine.get_main_loop().get_nodes_in_group(&"decal").remove_at(0)
	return
#endregion

#region Blood Puff
func createBloodPuff(bPosition: Vector3 = Vector3.ZERO, minAmount: int = 2, maxAmount: int = 10) -> void:
		var bloodSpurt: GPUParticles3D = load("res://assets/particles/bloodSpurt/bloodSpurt.tscn").instantiate()
		gameManager.world.worldMisc.add_child(bloodSpurt)
		bloodSpurt.global_position = bPosition
		bloodSpurt.minParticles = minAmount
		bloodSpurt.maxParticles = maxAmount
		bloodSpurt.emitting = true
#endregion

#region Pulverize Sound
func createPulverizeSound(pPosition: Vector3 = Vector3.ZERO) -> void:
	var pulverizeSound: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	pulverizeSound.stream = load("res://assets/misc/obliterateStream.tres")
	pulverizeSound.bus = &"Sounds"
	#pulverizeSound.attenuation_filter_db = 0
	pulverizeSound.attenuation_filter_cutoff_hz = 20500
	pulverizeSound.volume_db = -5
	pulverizeSound.max_distance = 10
	gameManager.world.worldMisc.add_child(pulverizeSound)
	pulverizeSound.global_position = pPosition
	pulverizeSound.finished.connect(pulverizeSound.queue_free)
	pulverizeSound.play()
#endregion

func registerDecal(decal:Node3D)->void:
	decal.tree_exited.connect(removeFromArrayOnExitTree.bind(decal,decals))
	for i in decals:
		if !is_instance_valid(i):
			decals.erase(i)

	decals.append(decal)

	if decals.size() > UserConfig.game_max_decals:
		var oldest = decals.pop_front()
		if is_instance_valid(oldest):
			if oldest.has_method("deleteSplat"):
				oldest.call_deferred("deleteSplat")
			elif oldest.has_method("deletePool"):
				oldest.call_deferred("deletePool")
			elif oldest.has_method("deleteHole"):
				oldest.call_deferred("deleteHole")

func removeFromArrayOnExitTree(node:Node3D,array:Array):
	if array.has(node):
		array.erase(node)

func registerRagdoll(ragdoll:PawnRagdoll)->void:
	ragdoll.tree_exited.connect(removeFromArrayOnExitTree.bind(ragdoll,ragdolls))
	for i in ragdolls:
		if !is_instance_valid(i):
			physEntities.erase(i)

	ragdolls.append(ragdoll)
	if ragdolls.size() > UserConfig.game_max_ragdolls:
		var oldest = ragdolls.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

func registerPhysicsEntity(entity:Node3D)->void:
	entity.tree_exited.connect(removeFromArrayOnExitTree.bind(entity,physEntities))
	for i in physEntities:
		if !is_instance_valid(i):
			physEntities.erase(i)

	physEntities.append(entity)
	if physEntities.size() > UserConfig.game_max_physics_entities:
		var oldest = physEntities.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

#region Physics Entity Check
func physEntityCheck() -> void:
	while get_tree().get_nodes_in_group(&"physicsEntity").size() > UserConfig.game_max_physics_entities:
		if is_instance_valid(get_tree().get_nodes_in_group(&"physicsEntity")[0]):
			get_tree().get_nodes_in_group(&"physicsEntity")[0].call_deferred("queue_free")
			get_tree().get_nodes_in_group(&"physicsEntity").remove_at(0)
			await get_tree().process_frame
	return
#endregion

#region God Mode
func godPawn(pawn: BasePawn) -> void:
	if pawn.healthComponent.has_meta(&"god"):
		if pawn.healthComponent.get_meta(&"god"):
			pawn.healthComponent.set_meta(&"god", false)
		else:
			pawn.healthComponent.set_meta(&"god", true)
		notify_warn("God Mode is %s for %s" % [pawn.healthComponent.get_meta(&"god"), pawn.name], 2, 1)
	else:
		pawn.healthComponent.set_meta(&"god", true)
		notify_warn("God Mode is %s for %s" % [pawn.healthComponent.get_meta(&"god"), pawn.name], 2, 1)


func infiniteAmmo() -> void:
	for i in playerPawns:
		if i.has_meta(&"infiniteAmmo"):
			if i.get_meta(&"infiniteAmmo"):
				i.set_meta(&"infiniteAmmo", false)
			else:
				i.set_meta(&"infiniteAmmo", true)
			notify_warn("Infinite Ammo is %s"%i.get_meta(&"infiniteAmmo"), 2, 1)
		else:
			i.set_meta(&"infiniteAmmo", true)
			notify_warn("Infinite Ammo is %s"%i.get_meta(&"infiniteAmmo"), 2, 1)


func godmode() -> void:
	for i in playerPawns:
		if i.healthComponent.has_meta(&"god"):
			if i.healthComponent.get_meta(&"god"):
				i.healthComponent.set_meta(&"god", false)
			else:
				i.healthComponent.set_meta(&"god", true)
			notify_warn("God Mode is %s"%i.healthComponent.get_meta(&"god"), 2, 1)
		else:
			i.healthComponent.set_meta(&"god", true)
			notify_warn("God Mode is %s"%i.healthComponent.get_meta(&"god"), 2, 1)
#endregion

#region Persistent Data
#Persistent data- To do with stuff that isn't specific to any save.
##Gets the persistent data file
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


##Writes to the persistent data file
func write_persistent_data(data: Dictionary) -> void:
	var file = FileAccess.open_compressed(userDir.get_current_dir() + "persistence", FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	file.store_var(data)
	file.flush()


##Changes a key/value in the persistent data file, and writes it
func modify_persistent_data(key: String, value: Variant) -> void:
	var data = get_persistent_data()
	data[key] = value
	write_persistent_data(data)
#endregion
