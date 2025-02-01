@tool
extends Node3D
var lightTween : Tween
@onready var explosionLight : OmniLight3D = $explosionLight
@export_tool_button("Play Effect") var previewEffect = explosionEffectPlay

func explosionEffectPlay()->void:
	explosionLight.light_energy = 5.0
	if lightTween:
		lightTween.kill()
	lightTween = create_tween()
	lightTween.tween_property(explosionLight,"light_energy",0,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

	for i in get_children():
		if i is GPUParticles3D:
			i.restart()
