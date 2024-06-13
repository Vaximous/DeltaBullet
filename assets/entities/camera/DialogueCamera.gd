extends Node3D
class_name CutsceneCamera
@export var camera : Camera3D
@onready var horizontal = $horiz
@onready var vertical = $horiz/vertical

var return_cam : Camera3D = null
var targetPosition : Vector3
var targetRotation : Vector3
var lerpSpeed = 5.0
var useSmoothstep = false

func _ready() -> void:
	var cam_to_copy = gameManager.activeCamera
	position = cam_to_copy.followingEntity.position
	vertical.rotation.x = gameManager.activeCamera.verticalHolder.rotation.x
	horizontal.rotation.y = gameManager.activeCamera.horizontal.rotation.y
	camera.fov = cam_to_copy.camera.fov
	camera.frustum_offset = cam_to_copy.camera.frustum_offset
	camera.attributes = cam_to_copy.camera.attributes
	camera.cull_mask = cam_to_copy.camera.cull_mask
	camera.keep_aspect = cam_to_copy.camera.keep_aspect
	camera.environment = cam_to_copy.camera.environment
	camera.doppler_tracking = cam_to_copy.camera.doppler_tracking
	camera.near = cam_to_copy.camera.near
	camera.far = cam_to_copy.camera.far


func activate(_return_cam, targetPos : Vector3, targetRot : Vector3, speed:float = 5.0) -> void:
	return_cam = _return_cam
	setTargetPosition(targetPos, targetRot, speed)
	camera.make_current()


func setTargetPosition(tPosition : Vector3, tRotation : Vector3, speed:float = 5.0, _useSmoothstep : bool = false) -> void:
	targetPosition = tPosition
	targetRotation = tRotation
	lerpSpeed = speed
	useSmoothstep = _useSmoothstep

func _process(delta: float) -> void:
	if targetPosition != null:
		if !useSmoothstep:
			global_position = lerp(global_position,targetPosition,lerpSpeed*delta)
			vertical.rotation.x = lerpf(vertical.rotation.x,targetRotation.x,lerpSpeed*delta)
			horizontal.rotation.y = lerpf(horizontal.rotation.y,targetRotation.y,lerpSpeed*delta)
		else:
			global_position.x = smoothstep(global_position.x,targetPosition.x,lerpSpeed*delta)
			global_position.y = smoothstep(global_position.x,targetPosition.x,lerpSpeed*delta)
			global_position.z = smoothstep(global_position.x,targetPosition.x,lerpSpeed*delta)
			vertical.rotation.x = smoothstep(vertical.rotation.x,targetRotation.x,lerpSpeed*delta)
			horizontal.rotation.y = smoothstep(horizontal.rotation.y,targetRotation.y,lerpSpeed*delta)
func remove() -> void:
	return_cam.make_current()
	queue_free()
