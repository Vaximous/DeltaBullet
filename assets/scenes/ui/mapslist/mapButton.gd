extends Button
@onready var selectSound : AudioStreamPlayer = $selectSound
@onready var hoverSound : AudioStreamPlayer = $audioStreamPlayer
@onready var background : TextureRect = $background
@onready var mapIcon : TextureRect = $mapIcon
@onready var mapName : Label = $mapName
@onready var mapDescription : Label = $mapDescription
var sceneLoad : String
var mapFile : WorldData

func _ready()->void:
	hoverOff()

func parseMap()->void:
	if mapFile != null:
		mapName.text = mapFile.worldName
		mapDescription.text = mapFile.worldDescription
		if mapFile.worldLoadingTexture != null:
			mapIcon.texture = mapFile.worldLoadingTexture
		else:
			mapIcon.texture = load(gameManager.tempImages.pick_random())
	else:
		queue_free()

func hoverOn()->void:
	hoverSound.play()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background,"size",Vector2(615,152),0.25)

func hoverOff()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(background,"size",Vector2(256,152),0.25)

func _on_pressed()->void:
	if selectSound.playing != true:
		selectSound.play()
		hoverSound.stop()
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	gameManager.loadWorld(sceneLoad)
