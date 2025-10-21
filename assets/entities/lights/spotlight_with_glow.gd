@tool
extends Node3D

@export_group("Spotlight", "spotlight_")
@export var spotlight_light_range: float = 5.0:
	set(value):
		$spotLight3d.spot_range = value
		$omniLight3d.omni_range = value
		spotlight_light_range = value
@export var spotlight_light_attenuation: float = 1.0:
	set(value):
		$spotLight3d.spot_attenuation = value
		spotlight_light_attenuation = value
@export var spotlight_light_angle: float = 60.0:
	set(value):
		$spotLight3d.spot_angle = value
		spotlight_light_angle = value
@export var spotlight_light_color: Color = Color.WHITE:
	set(value):
		$spotLight3d.light_color = value
		$omniLight3d.light_color = value
		spotlight_light_color = value
@export var spotlight_light_energy: float = 1.0:
	set(value):
		$spotLight3d.light_energy = value
		$omniLight3d.light_energy = value * omnilight_power_scale
		spotlight_light_energy = value
@export_exp_easing("attenuation") var spotlight_light_angle_attenuation: float = 1.0:
	set(value):
		$spotLight3d.spot_angle_attenuation = value
		spotlight_light_angle_attenuation = value
@export var spotlight_cast_shadow: bool = false:
	set(value):
		$spotLight3d.shadow_enabled = value
		spotlight_cast_shadow = value
@export_group("Omnilight", "omnilight_")
@export_range(0.0, 1.0, 0.01) var omnilight_power_scale: float = 0.3:
	set(value):
		$omniLight3d.light_energy = value * omnilight_power_scale
		omnilight_power_scale = value
