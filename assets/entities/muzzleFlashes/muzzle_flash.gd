@tool
extends Node3D
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var lightTween : Tween
var spriteTween : Tween
var meshTween : Tween
@export_category("Muzzle Flash")
@export var lightIntensity : float = 5.0
@export var lightTime : float = 0.15
@export var spriteTime : float = 0.2
@export var meshTime : float = 0.1
@export var animatedSprites : Array[AnimatedSprite3D]
@export var muzzleEmitters : Array[GPUParticles3D]
@export var muzzleLights : Array[OmniLight3D]
@export_subgroup("Meshes")
@export var muzzleMeshes : Array[MeshInstance3D]
@export var randomRotX : bool = false
@export var randomRotY : bool = false
@export var randomRotZ : bool = false


@export_tool_button("Play Muzzle Flash")
var c : Callable = func():
	playFlash()

func playFlash()->void:
	#Flash light
	for lights in muzzleLights:
		if is_instance_valid(lights):
			#if lightTween:
				#lightTween.kill()
			lightTween = create_tween()
			lightTween.set_trans(defaultTransitionType)
			lightTween.set_ease(defaultEaseType)
			lightTween.finished.connect(lights.queue_free)
			lights.light_energy = lightIntensity
			lights.shadow_enabled = false
			lightTween.parallel().tween_property(lights,"light_energy",0,lightTime)


	## Emit all of the emitters
	for emitter in muzzleEmitters:
		emitter.finished.connect(emitter.queue_free)
		emitter.restart()

	##Play all of the animatedSprites
	for sprites in animatedSprites:
		if is_instance_valid(sprites):
			if spriteTween:
				spriteTween.kill()
			spriteTween = create_tween()
			sprites.modulate = Color.WHITE
			sprites.play()
			spriteTween.parallel().tween_property(sprites,"modulate",Color.TRANSPARENT,spriteTime).set_trans(defaultTransitionType).set_ease(defaultEaseType).finished

			#sprites.queue_free()

	##Tween & Rotate meshes
	for meshes in muzzleMeshes:
		if is_instance_valid(meshes):
			#if meshTween:
				#meshTween.kill()
			meshTween = create_tween()
			var size = meshes.scale
			#meshes.scale = Vector3.ZERO
			if randomRotX:
				meshes.rotation.x = randf_range(-PI, PI)
			if randomRotY:
				meshes.rotation.y = randf_range(-PI, PI)
			if randomRotZ:
				meshes.rotation.z = randf_range(-PI, PI)
			meshTween.parallel().tween_property(meshes,"scale",Vector3.ZERO,meshTime).set_trans(defaultTransitionType).set_ease(defaultEaseType)
			meshTween.parallel().tween_property(meshes,"transparency",1,meshTime).set_trans(defaultTransitionType).set_ease(defaultEaseType)
	get_tree().create_timer(3).timeout.connect(queue_free)
