extends Control
@onready var topBarAnimPlayer : AnimationPlayer = $topBarAnimPlayer
##The map object
@export var map : Node3D
##Currently selected map index, controls the rotation and position of where the camera is looking
@export var selectedIndex : int = 0:
	set(value):
		selectedIndex = value
		setIndex(value)

func addIndex()->void:
	if !selectedIndex >= map.mapRotations.size()-1:
		selectedIndex += 1

func subtractIndex()->void:
	if !selectedIndex <= 0:
		selectedIndex -= 1

func _ready() -> void:
	topBarAnimPlayer.play("open")
	selectedIndex = 0

func setIndex(value:int):
	if !value > map.mapRotations.size()-1 and map:
		map.setCameraPositionAndRotation(map.mapPositions[value],map.mapRotations[value])
