extends CanvasLayer

signal index_changed(value: int)

const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed: float = 0.25

##The map object
@export var map: Node3D:
	set(value):
		map = value
		%cityName.text = map.mapName
##Currently selected map index, controls the rotation and position of where the camera is looking
@export var selectedIndex: int = 0:
	set(value):
		selectedIndex = value

var screenBusy: bool = false
var visibleTween: Tween
##This is the marker that is selected
var selectedMarker: Node3D = null:
	set(value):
		if value != null:
			if selectedMarker != null:
				var previousMarker = selectedMarker
				selectedMarker = value
				selectedMarker.setMarkerIcon(selectedMarker.IconType.CURRENT)
				previousMarker.playCloseAnimation()
				previousMarker.setMarkerIcon(previousMarker.defaultMarkerIcon)
				%AreaInformation.show()
			else:
				selectedMarker = value
				#%AreaInformation.hide()
				#selectedMarker.playCloseAnimation()
		if !%AreaInformation.isTravelHovered:
			%AreaInformation.marker = value

@onready var uiAnimPlayer: AnimationPlayer = $mapScreen/uiAnimPlayer
@onready var areaInfo := %AreaInformation


func _ready() -> void:
	musicManager.fade_all_audioplayers_out(0.5)
	%mapScreen.modulate = Color.TRANSPARENT
	setVisible(true)
	gameManager.showMouse()
	add_to_group(&"worldMap")
	uiAnimPlayer.play("open")
	selectedIndex = 0

func _process(delta: float) -> void:
	setGritLabel(str(gameState.getPawnCash()))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		gameManager.removeMapPurchasePopups()
		setVisible(false)


func addIndex() -> void:
	if !selectedIndex >= map.mapRotations.size() - 1:
		selectedIndex += 1


func subtractIndex() -> void:
	if !selectedIndex <= 0:
		selectedIndex -= 1


func setSelectedMarker(value) -> void:
	selectedMarker = value


func setVisible(value: bool) -> void:
	if visibleTween:
		visibleTween.kill()
	visibleTween = create_tween()
	if value:
		show()
		#%mapTheme.play()
		musicManager.create_audioplayer_with_stream(load("res://assets/music/menu/maptheme.wav"), 0.5)
		visibleTween.parallel().tween_property(%mapScreen, "modulate", Color.WHITE, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	else:
		musicManager.fade_all_audioplayers_out(0.5)
		map.tweenModelPosition(map.modelHolder, Vector3(0, -5, 0), 0.7)
		await visibleTween.parallel().tween_property(%mapScreen, "modulate", Color.TRANSPARENT, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
		gameManager.hideMouse()
		gameManager.pauseMenu.canPause = true
		gameManager.removeWorldMap()

func setRankLabel(text:String)->void:
	%ranklabel.text = text

func setGritLabel(text:String)->void:
	%gritLabel.text = text

func setIndex(value: int):
	if !value > map.mapRotations.size() - 1 and map:
		map.setCameraPositionAndRotation(map.mapPositions[value], map.mapRotations[value])
