extends Node3D
## The gizmo was moved
signal gizmoTranslate(pos: Vector3, pos_global: Vector3)
## The gizmo was rotated
signal gizmoRotate(rot: Vector3, rot_global: Vector3)
## The gizmo was resized
signal gizmoScaling(sca: Vector3)
## Start focus gizmo
signal gizmoFocus()
## Unfocus gizmo
signal gizmoUngrab()
@export_category("Gizmo")
var target : Node3D
var leftButtonDown : bool = false
@export_enum("Translate","Rotate","Scale") var translateType = 0
@export var moveSspeed: float = 2
@export var rotateSpeed: float = 1000
@export var scaleSpeed: float = 0.05



func _physics_process(delta: float) -> void:
	if target:
		position = target.position
		if leftButtonDown:
			#rotation = target.rotation
			rotation_degrees = Vector3.ZERO
		else:
			#---is release left button, recover gizmo rotation  to ZERO base.
			rotation_degrees = Vector3.ZERO

	#---change this gizmo size by distance to main camera
	var glodist = get_viewport().get_camera_3d().global_position - global_position
	#print("glodist=",glodist.length())
	var basesize = (glodist.length() * 0.1)
	#print("basesize=",basesize)
	if basesize < 0.1:
		basesize = 0.1
	#if basesize > 5:
	#	basesize = basesize * 0.5

	scale.x = basesize
	scale.y = basesize
	scale.z = basesize
