extends Control
@onready var worldNameControl : Control = $worldName
@onready var worldBG = $worldBackground
@onready var worldNameLabel : Label = $worldName/worldNamelabel
@onready var worldDescription : Label = $worldName/worldDescription
@onready var animPlayer : AnimationPlayer = $animationPlayer
@onready var continueAnim : AnimationPlayer = $control/continueLabel/animationPlayer
@onready var continueLabel : Label = $control/continueLabel
var loadingProgress : Array = []
var loadingFinished : bool = false:
	set(value):
		loadingFinished = value
		if loadingFinished:
			continueLabel.show()
			continueAnim.play("flyout")
@onready var progressBar : ProgressBar = $control/progressBar
var sceneToLoad:String:
	set(value):
		sceneToLoad = value
		if sceneToLoad != "" or " " or null:
			loadingFinished = false
			data = load(sceneToLoad).instantiate()
var data:
	set(value):
		data = value.worldData
		worldNameLabel.text = data.worldName
		worldDescription.text = data.worldDescription
		worldBG.texture = data.worldLoadingTexture
var loadStatus
var sceneLoading
var press = false

func _ready() -> void:
	worldNameControl.hide()
	await Fade.fade_in(0.3)
	await get_tree().create_timer(0.2).timeout
	ResourceLoader.load_threaded_request(sceneToLoad)
	loadingFinished = false
	animPlayer.play("flyout")
	worldNameControl.show()
	continueLabel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	gameManager.freeOrphanNodes()

func _process(delta) -> void:
	if sceneToLoad != "" or " " or null:
		loadStatus = ResourceLoader.load_threaded_get_status(sceneToLoad,loadingProgress)
		if loadingProgress[0]>0:
			progressBar.value = lerpf(progressBar.value,floor(loadingProgress[0]*100), 16*delta)
		if loadStatus == ResourceLoader.THREAD_LOAD_LOADED:
			sceneLoading = ResourceLoader.load_threaded_get(sceneToLoad)
			if loadingFinished != true:
				loadingFinished = true
	if loadingFinished:
		progressBar.value = lerpf(progressBar.value,100, 16*delta)

func _unhandled_key_input(event) -> void:
	if loadingFinished:
		if event.is_pressed() and !press:
			press = true
			await Fade.fade_out(0.5).finished
			get_tree().change_scene_to_packed(sceneLoading)
			queue_free()