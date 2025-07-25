extends Node
class_name MovementController
@export var enabled : bool = true
var meshRotationTween : Tween
var meshRotationTweenMovement : Tween
var movementDirection : Vector3
@export var pawnControlling : BasePawn:
	set(value):
		pawnControlling = value
		if pawnControlling.isPlayerPawn():
			movementDirection = pawnControlling.direction.rotated(Vector3.UP,cameraRotation)
		else:
			movementDirection = pawnControlling.direction
@export var meshNode : Node3D
@export var rotationSpeed : float = 8
var acceleration : float
var speed : float
var velocity : Vector3
var cameraRotation : float
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	if enabled and !pawnControlling.isPawnDead and is_instance_valid(pawnControlling):
		if pawnControlling.pawnEnabled and !pawnControlling.isPawnDead:
			velocity.x = speed * movementDirection.normalized().x
			velocity.z = speed * movementDirection.normalized().z

			if not pawnControlling.is_on_floor() or pawnControlling.snappedToStairsLastFrame:
				pawnControlling.velocity.y -= gravity * delta

			if !pawnControlling.is_on_floor():
				pawnControlling.canJump = false
			else:
				pawnControlling.canJump = true

			pawnControlling.velocity.z = pawnControlling.velocity.lerp(velocity,acceleration*delta).z
			pawnControlling.velocity.x = pawnControlling.velocity.lerp(velocity,acceleration*delta).x

			if velocity != Vector3.ZERO and !pawnControlling.meshLookAt and !pawnControlling.isInCover:
				doMeshRotation(delta)
			elif pawnControlling.meshLookAt:
				doMeshLookat(delta)


			if !pawnControlling.snapUpStairCheck(delta):
				pawnControlling.stairSnapCheck()
				pawnControlling.move_and_slide()

func onMovementStateSet(state:MovementState)->void:
	if enabled and !pawnControlling.isPawnDead and is_instance_valid(pawnControlling):
		speed = state.movementSpeed
		acceleration = state.acceleration
		if pawnControlling.attachedCam and pawnControlling:
			if !pawnControlling.attachedCam.setCamRot.is_connected(onSetCamRot):
				pawnControlling.attachedCam.setCamRot.connect(onSetCamRot)

func onMovementDirectionSet(direction:Vector3)->void:
	if pawnControlling.isPlayerPawn():
		if !pawnControlling.isInCover:
			movementDirection = direction.rotated(Vector3.UP,cameraRotation)
		else:
			movementDirection = direction.rotated(Vector3.UP,atan2(pawnControlling.coverNormal.x,pawnControlling.coverNormal.z))
			#print(atan2(direction.x,direction.z))
			if atan2(direction.x,direction.z) > 0 and movementDirection != Vector3.ZERO:
				pawnControlling.coverDirection = 1
				if pawnControlling.attachedCam:
					pawnControlling.attachedCam.mirroredCamera = false
			elif movementDirection != Vector3.ZERO:
				pawnControlling.coverDirection = 0
				if pawnControlling.attachedCam:
					#print(atan2(direction.x,direction.z))
					pawnControlling.attachedCam.mirroredCamera = true
	else:
		movementDirection = direction

func onSetCamRot(camRotation:float)->void:
	cameraRotation = camRotation

func doMeshLookat(delta:float)->void:
	pawnControlling.canJump = false
	pawnControlling.bodyIKMarker.rotation.x = pawnControlling.turnAmount
	#pawnControlling.bodyIKMarker.rotation_degrees.y = lerpf(pawnControlling.bodyIKMarker.rotation_degrees.y, pawnControlling.to_local(Vector3(0,180,0)).y, 16*delta)
	pawnControlling.pawnMesh.rotation.y = lerp_angle(pawnControlling.pawnMesh.rotation.y, cameraRotation, 23 * delta)
	#pawnControlling.bodyIKMarker.rotation.z = lerpf(pawnControlling.bodyIKMarker.rotation.z, 0.0-pawnControlling.pawnMesh.rotation.y, 16*delta)

func doMeshRotation(delta:float) -> void:
	var targetRotation = atan2(-pawnControlling.velocity.x,-pawnControlling.velocity.z)
	meshNode.rotation.y = lerp_angle(meshNode.rotation.y, targetRotation, rotationSpeed * delta)
