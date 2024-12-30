extends "res://assets/components/3Dto2Dcomponent/3Dto2DComponent.gd"
var visibilityTween : Tween
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 1
@onready var animPlayer : AnimationPlayer = $marginContainer/animationPlayer
@onready var markerLabel : Label = $marginContainer/hBoxContainer/label
@onready var container : MarginContainer = $marginContainer
@export var map : Node3D:
	set(value):
		map = value
		setupMap()
##What is this areas name?
@export var locationName : String = ""
##What scene will this location load?
@export var travelScene : PackedScene
##Controls whether or not this area is locked or unlocked. If its locked then the player will be unable to travel to this location. Otherwise, they will be able to
@export_enum("Locked","Unlocked") var travelStatus : int = 1
## This ID will correspong with whichever area value the selection index is currently on. If it equals the selection index of the map, it will be visible. Otherwise it won't be
@export var travelGroupID = 0
##This is the ID of the location itself.
@export var travelID = 0

func setupMap()->void:
	playCloseAnimation()
	markerLabel.text = locationName
	if map:
		map.mapScreen.index_changed.connect(updateVisibility.unbind(1))

func updateVisibility()->void:
	if map.mapScreen.selectedIndex == travelGroupID:
		setVisible(true)
	else:
		setVisible(false)

func _ready() -> void:
	setupMap()

func playOpenAnimation()->void:
	animPlayer.play("open")

func playCloseAnimation()->void:
	animPlayer.play("close")

func gotoLocation()->void:
	if travelScene and get_tree().current_scene.scene_file_path != travelScene.resource_path:
		await Fade.fade_out(0.5).finished
		gameManager.removeWorldMap()
		gameManager.loadWorld(travelScene.resource_path)
	else:
		gameManager.notify_warn("You're already at this location.", 4, 5)

func setVisible(value:bool)->void:
	if visibilityTween:
		visibilityTween.kill()
	visibilityTween = create_tween()
	if value:
		show()
		visibilityTween.parallel().tween_property(container,"modulate",Color.WHITE,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	else:
		await visibilityTween.parallel().tween_property(container,"modulate",Color.TRANSPARENT,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
		hide()
