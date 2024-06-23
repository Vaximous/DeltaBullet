extends Node

#game configs
var game_lowHP_ambience : bool = false
var game_show_fps : bool = false
var game_camera_screentilt_always : bool = false
var game_aim_screentilt : bool = true
var game_crosshair_tilt : bool = true
var game_crosshair_dynamic_position : bool = true
var game_simple_crosshairs : bool = false
var game_ragdoll_remove_time : int = 15
var game_decal_remove_time : int = 120

#audio configs
var audio_MasterVolume : float = -15.0
var audio_GameVolume : float = 1.0
var audio_MusicVolume : float = 0.6
var audio_ambience_volume : float = 0.6
var audio_UiVolume : float = 0.6
var audio_custom_music_enabled : bool = false

#graphics settings
@export_enum("Hard"," Soft Very Low", "Soft Low", "Soft Medium", "Soft High", "Soft Very High") var graphics_shadow_filter_quality : int = 1
@export_enum("Very Low", "Low", "Medium", "High", "Very High") var graphics_shadow_quality : int = 3
var graphics_motion_blur : bool = false
var graphics_resolution : int = 0
var graphics_fullscreen : bool = false
var graphics_fxaa : bool = true:
	set(value):
		graphics_fxaa = value
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa",value)
		RenderingServer.viewport_set_screen_space_aa(get_viewport().get_viewport_rid(),int(value))
var graphics_msaa : int = 1:
	set(value):
		graphics_msaa = value
		if value < 0:
			value = 0
		RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(),value)
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d",graphics_msaa)
var graphics_Ssr : bool = false
var graphics_Sdfgi : bool = false
var graphics_Ssil : bool = false
enum PARTICLE_COUNT{VERY_FEW, LESS, NORMAL}
enum WORLD_DETAILS{VERY_FEW, LESS, NORMAL}
var graphics_particle_amount : PARTICLE_COUNT = PARTICLE_COUNT.NORMAL
var graphics_world_details : WORLD_DETAILS = WORLD_DETAILS.NORMAL


var configs_loaded : bool = false
signal finish_loading_configs
signal configs_updated
func _ready() -> void:
	print(getSettingsDict())
	loadConfigs()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		saveConfigs()


func loadConfigs() -> void:
	var configs = ConfigFile.new()
	var err = configs.load("user://user_settings.cfg")

	if err != OK:
		return

	for section in configs.get_sections():
		for key in configs.get_section_keys(section):
			set(section.to_lower()+"_"+key, configs.get_value(section, key))
#	print("Loaded configs.")
	configs_loaded = true
	applyConfigs()


func saveConfigs() -> void:
	var configs = ConfigFile.new()

	for property in get_script().get_script_property_list():
		if property["usage"] == 128:
			continue
		var section = (property["name"] as String).split("_", 0)
		if section[0] == "configs":
			continue
		var key = (property["name"] as String).replace(section[0]+"_", "")
		configs.set_value(section[0].to_upper(), key, get(property["name"]))
#		print("Set section %s key %s with value %s" % [section, key, get(property["name"])])
	configs.save("user://user_settings.cfg")
#	print("Finished saving configs.")
	applyConfigs()


func applyConfigs() -> void:
	AudioServer.set_bus_volume_db(0, audio_MasterVolume)
	AudioServer.set_bus_volume_db(1, audio_UiVolume)
	AudioServer.set_bus_volume_db(2, audio_GameVolume)
	AudioServer.set_bus_volume_db(3, audio_MusicVolume)
	AudioServer.set_bus_volume_db(4, audio_ambience_volume)
	applyShadowQuality()
	applyShadowFilterQuality()
	get_window().mode = Window.MODE_FULLSCREEN if graphics_fullscreen else Window.MODE_WINDOWED
	configs_updated.emit()


func getSettingsDict() -> Dictionary:
	var output : Dictionary = {}
	for property in get_script().get_script_property_list():
		if property["usage"] == 128:
			continue
		var section = (property["name"] as String).split("_", 0)
		if section[0] == "configs":
			continue
		output[property["name"]] = get(property["name"])
	return output


func getOption(optionString:String):
	return optionString

func applyShadowFilterQuality() -> void:
	match graphics_shadow_filter_quality:
		-1:
			RenderingServer.directional_soft_shadow_filter_set_quality(0)
			RenderingServer.positional_soft_shadow_filter_set_quality(0)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",0)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",0)
		0:
			RenderingServer.directional_soft_shadow_filter_set_quality(0)
			RenderingServer.positional_soft_shadow_filter_set_quality(0)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",0)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",0)
		1:
			RenderingServer.directional_soft_shadow_filter_set_quality(1)
			RenderingServer.positional_soft_shadow_filter_set_quality(1)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",1)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",1)
		2:
			RenderingServer.directional_soft_shadow_filter_set_quality(2)
			RenderingServer.positional_soft_shadow_filter_set_quality(2)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",2)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",2)
		3:
			RenderingServer.directional_soft_shadow_filter_set_quality(3)
			RenderingServer.positional_soft_shadow_filter_set_quality(3)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",3)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",3)
		4:
			RenderingServer.directional_soft_shadow_filter_set_quality(4)
			RenderingServer.positional_soft_shadow_filter_set_quality(4)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",4)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",4)
		5:
			RenderingServer.directional_soft_shadow_filter_set_quality(5)
			RenderingServer.positional_soft_shadow_filter_set_quality(5)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",5)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",5)

func applyShadowQuality() -> void:
	match graphics_shadow_quality:
		-1:
			RenderingServer.directional_shadow_atlas_set_size(16,true)
			RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(),16,true)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",16)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size",16)
		0:
			RenderingServer.directional_shadow_atlas_set_size(256,true)
			RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(),256,true)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",256)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size",256)
		1:
			RenderingServer.directional_shadow_atlas_set_size(1024,true)
			RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(),1024,true)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",1024)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size",1024)
		2:
			RenderingServer.directional_shadow_atlas_set_size(2048,true)
			RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(),2048,true)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",2048)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size",2048)
		3:
			RenderingServer.directional_shadow_atlas_set_size(4096,true)
			RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(),4096,true)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",4096)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size",4096)
		4:
			RenderingServer.directional_shadow_atlas_set_size(8192,true)
			RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(),8192,true)
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",8192)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size",8192)
