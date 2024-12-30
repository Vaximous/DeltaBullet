extends CanvasLayer
signal index_changed(value:int)
var visibleTween : Tween
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 0.25
@onready var topBarAnimPlayer : AnimationPlayer = $mapScreen/topBarAnimPlayer
##The map object
@export var map : Node3D
##Currently selected map index, controls the rotation and position of where the camera is looking
@export var selectedIndex : int = 0:
	set(value):
		selectedIndex = value
		index_changed.emit(value)
		setIndex(value)

func addIndex()->void:
	if !selectedIndex >= map.mapRotations.size()-1:
		selectedIndex += 1

func subtractIndex()->void:
	if !selectedIndex <= 0:
		selectedIndex -= 1

func _ready() -> void:
	%mapScreen.modulate = Color.TRANSPARENT
	setVisible(true)
	gameManager.showMouse()
	add_to_group(&"worldMap")
	topBarAnimPlayer.play("open")
	selectedIndex = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		setVisible(false)

func setVisible(value:bool)->void:
	if visibleTween:
		visibleTween.kill()
	visibleTween = create_tween()
	if value:
		show()
		visibleTween.parallel().tween_property(%mapScreen,"modulate",Color.WHITE,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	else:
		await visibleTween.parallel().tween_property(%mapScreen,"modulate",Color.TRANSPARENT,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
		gameManager.hideMouse()
		gameManager.pauseMenu.canPause = true
		gameManager.removeWorldMap()

func setIndex(value:int):
	if !value > map.mapRotations.size()-1 and map:
		map.setCameraPositionAndRotation(map.mapPositions[value],map.mapRotations[value])
