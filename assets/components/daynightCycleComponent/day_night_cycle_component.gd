@tool
extends Node

@export var day_length_seconds : float = 600.0
@export var world_env_node : WorldEnvironment
@export var sun : DirectionalLight3D
@export_subgroup("Environment Settings")
@export var ambient_light_color : Gradient
@export var tonemap_exposure : Curve
@export var fog_color : Gradient
@export var fog_energy : Curve
@export var fog_sun_scatter : Curve
@export var fog_density : Curve
@export var fog_height : Curve
@export var fog_height_density : Curve
@export var volumetric_fog_density : Curve
@export var volumetric_fog_albedo : Gradient
@export var volumetric_fog_emission : Gradient
@export var volumetric_fog_anisotropy : Curve
@export var volumetric_fog_sky_affect : Curve
@export var adjustments_brightness : Curve
@export var adjustments_contrast : Curve
@export var adjustments_saturation : Curve
@export_subgroup("editor")
@export var editor_preview : bool = false
const properties = [
		"ambient_light_color",
		"tonemap_exposure",
		"fog_color",
		"fog_energy",
		"fog_sun_scatter",
		"fog_density",
		"fog_height",
		"fog_height_density",
		"volumetric_fog_density",
		"volumetric_fog_albedo",
		"volumetric_fog_emission",
		"volumetric_fog_anisotropy",
		"volumetric_fog_sky_affect",
		"adjustments_brightness",
		"adjustments_contrast",
		"adjustments_saturation"
		]

var time : float = 0.0


func _update_world_environment() -> void:
	var percent = get_time_in_day()
	var sky : Environment = world_env_node.environment

	sun.rotation.x = (percent - 0.5) * 2.0 * PI - (PI/2.0)

	if sky == null:
		return

	for property in properties:
		var prop = get(property)
		if prop != null:
			sky.set(property, prop.sample(percent))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not editor_preview:
		return
	time += delta
	_update_world_environment()


##Set time of day, range 0.0 to 1.0
func set_time_in_day(time : float) -> void:
	time = day_length_seconds * time


##Gets current time of day as a percentage
func get_time_in_day() -> float:
	return fmod(time / day_length_seconds, 1.0)
