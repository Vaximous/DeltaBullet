@tool
extends Node3D
var lightTween : Tween
var rippleTween : Tween
var explosionSpeed : float = 0.25
var explosionFadeSpeed : float = 0.25
@onready var rippleMesh : MeshInstance3D = $rippleMesh
@onready var explosionLight : OmniLight3D = $explosionLight
@export_tool_button("Play Effect") var previewEffect = explosionEffectPlay


func is_emitting() -> bool:
	return $explosionSparks.emitting or $explosionSmoke.emitting or $explosion.emitting


func doRipple(rippleAmount:float=10.0, rippleSpeed : float = 0.25, rippleFadeSpeed : float = 0.25)->Tweener:
	rippleMesh.scale = Vector3.ZERO
	rippleMesh.transparency = 0
	if rippleTween:
		rippleTween.kill()
	rippleTween = create_tween()
	var ripple := rippleTween.tween_property(rippleMesh,"scale",Vector3(rippleAmount,rippleAmount,rippleAmount)*2,rippleSpeed)
	rippleTween.parallel().tween_property(rippleMesh,"transparency",1.0,explosionFadeSpeed).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	return ripple

func explosionEffectPlay()->void:
	if Engine.is_editor_hint():
		doRipple(10)
	explosionLight.light_energy = 5.0
	if lightTween:
		lightTween.kill()
	lightTween = create_tween()
	lightTween.tween_property(explosionLight,"light_energy",0,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

	for i in get_children():
		if i is GPUParticles3D:
			i.restart()
