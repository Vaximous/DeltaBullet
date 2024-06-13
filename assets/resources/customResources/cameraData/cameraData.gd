extends Resource
class_name CameraData

@export_category("Camera")
@export var isHudEnabled : bool = true
@export var useZoomFOV : bool = true
@export var zoomSpringAmount : float = 2.0
@export var cameraOffset : Vector3 = Vector3.ZERO
@export var camLerpSpeed : float = 8.0
@export var itemEquipOffset : Vector3 = Vector3.ZERO
@export var itemEquipLerpSpeed : float = 5.0
@export var zoomAmount : float = 25.0
@export var zoomInSpeed : float = 16.0
@export var zoomOutSpeed : float = 16.0
@export var zoomSpeed : float = 5.0
