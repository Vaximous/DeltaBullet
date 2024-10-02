extends Node
var meshRotationTween : Tween
var meshRotationTweenMovement : Tween
@export var pawnControlling : BasePawn:
	set(value):
		pawnControlling = value
@export var meshNode : Node3D
@export var rotationSpeed : float = 8
var acceleration : float
var speed : float
var movementDirection : Vector3
var velocity : Vector3
var cameraRotation : float
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	if pawnControlling.pawnEnabled and !pawnControlling.isPawnDead:
		velocity.x = speed * movementDirection.normalized().x
		velocity.z = speed * movementDirection.normalized().z

		if not pawnControlling.is_on_floor():
			pawnControlling.velocity.y -= gravity * delta

		if !pawnControlling.is_on_floor():
			pawnControlling.canJump = false
		else:
			pawnControlling.canJump = true

		pawnControlling.velocity.z = pawnControlling.velocity.lerp(velocity,acceleration*delta).z
		pawnControlling.velocity.x = pawnControlling.velocity.lerp(velocity,acceleration*delta).x

		if velocity != Vector3.ZERO and !pawnControlling.meshLookAt:
			doMeshRotation(delta)
		elif pawnControlling.meshLookAt:
			doMeshLookat(delta)

		pawnControlling.move_and_slide()

func onMovementStateSet(state:MovementState)->void:
	speed = state.movementSpeed
	acceleration = state.acceleration
	if pawnControlling.attachedCam and pawnControlling:
		if !pawnControlling.attachedCam.setCamRot.is_connected(onSetCamRot):
			pawnControlling.attachedCam.setCamRot.connect(onSetCamRot)

func onMovementDirectionSet(direction:Vector3)->void:
	movementDirection = direction.rotated(Vector3.UP,cameraRotation)

func onSetCamRot(camRotation:float):
	cameraRotation = camRotation

func doMeshLookat(delta:float):
	pawnControlling.canJump = false
	pawnControlling.bodyIKMarker.rotation.x = pawnControlling.turnAmount
	pawnControlling.bodyIKMarker.rotation_degrees.y = lerpf(pawnControlling.bodyIKMarker.rotation_degrees.y, pawnControlling.to_local(Vector3(0,180,0)).y, 16*delta)
	pawnControlling.pawnMesh.rotation.y = lerp_angle(pawnControlling.pawnMesh.rotation.y, cameraRotation, 23 * delta)
	pawnControlling.bodyIKMarker.rotation.z = lerpf(pawnControlling.bodyIKMarker.rotation.z, 0.0, 16*delta)

func doMeshRotation(delta:float) -> void:
	var targetRotation = atan2(-pawnControlling.velocity.x,-pawnControlling.velocity.z)
	meshNode.rotation.y = lerp_angle(meshNode.rotation.y, targetRotation, rotationSpeed * delta)
