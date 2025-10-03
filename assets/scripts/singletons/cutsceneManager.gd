extends Node

var currentCutsceneCam: Camera3D
var cutsceneAnimationPlayer: AnimationPlayer = AnimationPlayer.new()
var animLibrary: AnimationLibrary = AnimationLibrary.new()


func _ready() -> void:
	initiateCutsceneCam()


func createCutscene(cutsceneName, cutscenePath: String) -> void:
	if cutscenePath:
		currentCutsceneCam = Camera3D.new()
		add_child(currentCutsceneCam)
		currentCutsceneCam.name = "cutsceneCamera"
		currentCutsceneCam.process_mode = Node.PROCESS_MODE_DISABLED
		currentCutsceneCam.clear_current()
		currentCutsceneCam.current = false
		cutsceneAnimationPlayer.get_animation_library("cutscene").add_animation(cutsceneName, load(cutscenePath))
		cutsceneAnimationPlayer.play("cutscene/%s"%cutsceneName)
		currentCutsceneCam.make_current()


func initiateCutsceneCam() -> void:
	add_child(cutsceneAnimationPlayer)
	cutsceneAnimationPlayer.add_animation_library("cutscene", animLibrary)
