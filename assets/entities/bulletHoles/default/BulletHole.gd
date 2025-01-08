extends Node3D
class_name BulletHole
signal bulletHoleEmitted
@export_category("Bullet Hole")
var bulletVelocity : Vector3
@export var forceGlobalPosition : bool = false
@export var bulletTextures : Array[Texture2D]
@export var decal : Decal
@export var particleArray : Array[GPUParticles3D]
@export var soundArray : Array[AudioStreamPlayer3D]
@export_range(0.0,1.0) var decalSize : float = 0.15:
	set(value):
		decalSize = value
		if decal!=null:
			decal.scale = Vector3(decalSize,decalSize,decalSize)
@export_range(-80.00,80.00) var audioVolume : float = 0.15
const defaultTweenSpeed : float = 35
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var holeTween : Tween
var normal : Vector3
var colPoint : Vector3
var rot : float

func _ready()->void:
	initializeBulletHole()


func deleteHole()->void:
	if holeTween:
		holeTween.kill()
	holeTween = create_tween().set_ease(defaultEaseType).set_trans(defaultTransitionType)
	await holeTween.tween_property(decal,"modulate",Color.TRANSPARENT,0.25).finished
	queue_free()


func initializeBulletHole()->void:
	#Play the sounds
	for sounds in soundArray:
		sounds.max_db = audioVolume
		sounds.volume_db = audioVolume
		sounds.reparent(gameManager.world.worldMisc)
		gameManager.setSoundVariables(sounds)
		#print(sounds.volume_db)
		sounds.finished.connect(sounds.queue_free)
		sounds.play()

	#Make particle emitters face the direction of the normal
	global_transform = gameManager.create_surface_transform(colPoint,bulletVelocity,normal)

	#Set Decal Scale
	setDecalScale()

	#Emit the signal
	bulletHoleEmitted.emit()
	#Set Global Position to the collision point.
	#global_position = colPoint

	#Create the timer for the hole to fade
	var timer = get_tree().create_timer(UserConfig.game_decal_remove_time)
	timer.timeout.connect(deleteHole)

	#Assign Bullet Hole Textures
	if bulletTextures.size() > 0:
		var chosenTexture = bulletTextures.pick_random()
		decal.texture_albedo = chosenTexture


	#Emit the particles
	for particles in particleArray:
		#Forces the position of the particles to be set to the collision point (Wont be used much, is an old thing)
		if forceGlobalPosition:
			particles.global_transform.origin = colPoint

		#Reparent to particles in world
		particles.reparent(gameManager.world.worldParticles)

		#Connect finished to queue_free()
		if !particles.finished.is_connected(queue_free):
			particles.finished.connect(particles.queue_free)

		#Turns the particle on
		particles.emitting = true


func setDecalScale()->void:
	#scale = Vector3.ONE
	decal.scale = Vector3(decalSize,decalSize,decalSize)
