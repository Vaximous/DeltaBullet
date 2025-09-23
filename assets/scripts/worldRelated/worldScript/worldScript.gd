@tool
extends Node
class_name WorldScene
#signal worldLoaded


@onready var worldSpawns : Node = $Spawns
@onready var playerWorldSpawns : Node = $Spawns/playerSpawns
@onready var pawnWorldSpawns : Node = $Spawns/pawnSpawns
@onready var worldEnvironment : Node = $Environment
@onready var worldGeometry : Node3D = $Geometry
@onready var worldPawns : Node3D = $Pawns
@onready var worldProps : Node3D = $Props
@onready var worldMisc : Node3D = $Misc
@onready var worldParticles : Node3D = $Misc/Particles
@onready var worldWaypoints : Node3D = $Misc/WaypointNodes
@onready var worldSky : WorldEnvironment = $Environment/worldEnvironment
@onready var playerPawns : Node3D = $Pawns/Players
@onready var pauseControl : Control = $GamePauseMenu
##Set the name for this specific scene
@export_category("World Identity")
@export var worldData : WorldData:
	set(value):
		worldData = value



func _enter_tree()->void:
	if !Engine.is_editor_hint():
		gameManager.world = self
		#gameManager.freeOrphanNodes()


func _ready()->void:
	if !Engine.is_editor_hint():
		#gameManager.freeOrphanNodes()
		gameManager.pauseMenu = pauseControl
		gameManager.worldLoaded.emit()
		gameManager.getEventSignal("contractRefresh").emit()
		setupWorld()

		##Spawn pawns at their respective points.
		if worldData != null:
			if worldData.spawnPawnsOnLoad == true:
				getPlayerSpawnPoints().spawnPawn()
				for pawn in pawnWorldSpawns.get_children():
					if pawn != null:
						if pawn is PawnSpawn:
							if not pawn.ignore_spawn_on_load:
								pawn.spawnPawn()

		if !gameManager.isMultiplayerGame:
			pass
			#gameManager.add_player(getPlayerSpawnPoints(Vector3.ZERO,true).global_position)
		else:
			if worldData != null:
				worldData.spawnPawnsOnLoad = false
	else:
		if worldData:
			if worldData.skyTexture:
				worldSky.environment.sky.sky_material = worldData.skyTexture.duplicate()




func orphanDelete()->void:
	for i in get_children():
		remove_child(i)
	queue_free()


func getSpawnPoints(_offset:Vector3 = Vector3(0,0,0), pickRandom:bool = true, _spawn_idx:int = 0):
	if pickRandom:
		var spawnZone = pawnWorldSpawns.get_children().pick_random()
		if spawnZone is PawnSpawn:
			if spawnZone.pawnType == 1:
				return spawnZone
	else:
		pass


func getWaypoints(waypointType:int = 0)->Array:
	var waypointArray : Array
	for i in worldWaypoints.get_children():
		if i is AIMarker:
			if i.markerType == waypointType:
				waypointArray.append(i)
	return waypointArray

func getPlayerSpawnPoints(_offset:Vector3 = Vector3(0,0,0), pickRandom:bool = true, _spawn_idx:int = 0):
	if pickRandom:
		var spawnZone = playerWorldSpawns.get_children().pick_random()
		if spawnZone is PawnSpawn and !null:
			if spawnZone.pawnType == 0:
				return spawnZone
		else:
			return null


func playSoundscape()->void:
	if worldData.soundScape:
		var audioStreamPlayer : AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(audioStreamPlayer)
		audioStreamPlayer.bus = &'Ambience'
		audioStreamPlayer.stream = worldData.soundScape
		audioStreamPlayer.play()
		audioStreamPlayer.finished.connect(playSoundscape)
		audioStreamPlayer.finished.connect(audioStreamPlayer.queue_free)


func setupWorld()-> void:
	#gameManager.freeOrphanNodes()
	if worldData != null:
		name = worldData.worldName
		#Set the sky texture
		var env = load("res://assets/envs/default_environment.tres").duplicate()
		worldSky.environment = env
		if worldData.skyTexture:
			worldSky.environment.sky.sky_material = worldData.skyTexture.duplicate()
		##Soundscape
		if worldData.playOnStart:
			if !worldData.soundScape == null:
				musicManager.change_song_to(worldData.soundScape)
			else:
				print_rich("[color=red]The soundscape.. Its null retard.[/color]")
	else:
		print_rich("[color=red]Set the world data for this world!!![/color]")
