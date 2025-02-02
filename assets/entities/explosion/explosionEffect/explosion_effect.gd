@tool
extends Node3D
var lightTween : Tween
var rippleTween : Tween
@onready var rippleMesh : MeshInstance3D = $rippleMesh
@onready var explosionLight : OmniLight3D = $explosionLight
@export_tool_button("Play Effect") var previewEffect = explosionEffectPlay

func doRipple(rippleAmount:float=1.0)->void:
	rippleMesh.scale = Vector3.ZERO
	rippleMesh.transparency = 0
	if rippleTween:
		rippleTween.kill()
	rippleTween = create_tween()
	rippleTween.tween_property(rippleMesh,"scale",Vector3(rippleAmount,rippleAmount,rippleAmount),0.25).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	rippleTween.parallel().tween_property(rippleMesh,"transparency",1.0,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

func explosionEffectPlay()->void:
	#doRipple(10)
	explosionLight.light_energy = 5.0
	if lightTween:
		lightTween.kill()
	lightTween = create_tween()
	lightTween.tween_property(explosionLight,"light_energy",0,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

	for i in get_children():
		if i is GPUParticles3D:
			i.restart()
