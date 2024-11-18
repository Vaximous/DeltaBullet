extends Node
class_name WorldScene
signal worldLoaded

var pawnScene = load("res://assets/entities/pawnEntity/pawnEntity.tscn").duplicate()
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


func _init()->void:
	gameManager.freeOrphans.connect(free_me_orphan)


func _enter_tree()->void:
	gameManager.world = self


func _ready()->void:
	gameManager.pauseMenu = pauseControl
	emit_signal("worldLoaded")
	gameManager.getEventSignal("contractRefresh").emit()
	gameManager.freeOrphanNodes()
	setupWorld()
	##Spawn a player at a point.
	if !gameManager.isMultiplayerGame:
		pass
		#gameManager.add_player(getPlayerSpawnPoints(Vector3.ZERO,true).global_position)
	else:
		if worldData != null:
			worldData.spawnPawnsOnLoad = false

	##Spawn pawns at their respective points.
	if worldData != null:
		if worldData.spawnPawnsOnLoad == true:
			getPlayerSpawnPoints().spawnPawn()
			for pawn in pawnWorldSpawns.get_children():
				if pawn != null:
					if pawn is PawnSpawn:
						pawn.spawnPawn()


func getSpawnPoints(offset:Vector3 = Vector3(0,0,0), pickRandom:bool = true, spawn_idx:int = 0):
	if pickRandom:
		var spawnZone = pawnWorldSpawns.get_children().pick_random()
		if spawnZone is PawnSpawn:
			if spawnZone.pawnType == 1:
				return spawnZone
	else:
		pass


func getPlayerSpawnPoints(offset:Vector3 = Vector3(0,0,0), pickRandom:bool = true, spawn_idx:int = 0):
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
		audioStreamPlayer.bus = 'Ambience'
		audioStreamPlayer.stream = worldData.soundScape
		audioStreamPlayer.play()


func setupWorld()-> void:
	if worldData != null:
		##Soundscape
		if worldData.playOnStart:
			if !worldData.soundScape == null:
				musicManager.change_song_to(worldData.soundScape)
			else:
				print_rich("[color=red]The soundscape.. Its null retard.[/color]")
	else:
		print_rich("[color=red]Set the world data for this world!!![/color]")


func free_me_orphan()->void:
	if not is_inside_tree():
		queue_free()
