extends Node3D
class_name BulletHole
signal bulletHoleEmitted
@export_category("Bullet Hole")
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

	#Play the sounds
	for sounds in soundArray:
		gameManager.setSoundVariables(sounds)
		sounds.volume_db = audioVolume
		sounds.play()

	#Emit the particles
	for particles in particleArray:
		if !normal.dot(Vector3.UP) > 0.001:
			particles.look_at(colPoint + normal, Vector3.UP)
			particles.rotate(normal,randf_range(0, 180)/PI)

		#Forces the position of the particles to be set to the collision point (Wont be used much, is an old thing)
		if forceGlobalPosition:
			particles.global_position = colPoint

		particles.emitting = true


func setDecalScale()->void:
	decal.scale = Vector3(decalSize,decalSize,decalSize)
