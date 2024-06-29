extends Button
@onready var selectSound : AudioStreamPlayer = $selectSound
@onready var hoverSound : AudioStreamPlayer = $audioStreamPlayer
@onready var background : TextureRect = $background
@onready var mapIcon : TextureRect = $mapIcon
@onready var mapName : Label = $mapName
@onready var mapDescription : Label = $mapDescription
var sceneLoad : String
var mapFile

func _ready()->void:
	hoverOff()

func parseMap()->void:
	if mapFile != null:
		if mapFile.get("worldData") != null:
			mapName.text = mapFile.worldData.worldName
			mapDescription.text = mapFile.worldData.worldDescription
			if mapFile.worldData.worldLoadingTexture != null:
				mapIcon.texture = mapFile.worldData.worldLoadingTexture
		else:
			queue_free()
			gameManager.freeOrphanNodes()

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
	gameManager.freeOrphanNodes()
