extends Node3D
var camTween : Tween
@onready var horizontal = $Camera/camHoriz
@onready var vertical = $Camera/camHoriz/camVert
@onready var camera = $Camera/camHoriz/camVert/camera3d
@onready var cameraHolder = $Camera
## Which direction will the camera face on the map? The array holds rotations that the player can cycle through to view different parts of the map
@export var mapRotations : Array[Vector3]
## Which position will the camera be at on the map? The array holds positions that the player can cycle through to view different parts of the map
@export var mapPositions : Array[Vector3]
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 1

func setCameraPositionAndRotation(pos:Vector3,rot:Vector3)->void:
	if camTween:
		camTween.kill()
	camTween = create_tween()
	camTween.parallel().tween_property(cameraHolder,"global_position",pos,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	camTween.parallel().tween_property(horizontal,"rotation_degrees:y",rot.y,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	camTween.parallel().tween_property(vertical,"rotation_degrees:x",rot.x,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
