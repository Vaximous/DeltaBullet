extends Node
class_name CameraShakerComponent

@export var shakeAmp : Vector3
@export var shakeFreq : Vector3
@export var shakeDuration : float
@export var randoms : Vector3 = Vector3.ONE
@export var ignoreDirection : bool = false


func shakeCam(mult : float, camera : Node3D, direction : Vector3 = Vector3.ZERO) -> void:
	#if the camera is null assume active cam
	var shaken : Vector3 = shakeFreq
	if direction == Vector3.ZERO or ignoreDirection:
		shaken.y *= -1 if randi()%2 == 0 and randoms.y != 0 else 1
		shaken.x *= -1 if randi()%2 == 0 and randoms.x != 0 else 1
		shaken.z *= -1 if randi()%2 == 0 and randoms.z != 0 else 1
	else:
		#make the camera tilt depending on the direction of attack
		#from front and back, tilt up and down, multiplied by y
		var camtransform : Transform3D = camera.camera.global_transform
		#up and down
		direction *= Vector3(1, 0, 1)
		direction = direction.normalized()
		#side to side, tilt
		shaken.x *= camtransform.basis.z.dot(direction)
		shaken.y *= -camtransform.basis.x.dot(direction)
		shaken.z *= camtransform.basis.x.dot(direction)
	if camera.has_method(&"shakeCam"):
			camera.shakeCam(shaken * mult, shakeFreq * mult, shakeDuration)
			if !gameManager.bulletTime:
				camera.hud.triggerRadialBlur(Vector2(0.5,0.5),shaken.length() * randf_range(0.05,0.07),randf_range(0.3,0.9))
