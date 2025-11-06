class_name BasePawn
extends CharacterBody3D

##Signals
signal meshLookAtChanged(value: bool)
signal setDirection(direction: Vector3)
signal setMovementState(state: MovementState)
signal weaponFireChanged
signal freeAimChanged
signal directionChanged
signal controllerAssigned
signal clothingChanged
signal itemChanged
signal forcingAnimation
signal killedPawn
signal callFinished
signal onPawnKilled
signal hitboxAssigned(hitbox: Hitbox)
signal headshottedPawn

##The current attached camera (if there is one)
signal cameraAttached

##Component Setup
@export_category("Pawn")
var defaultPawnMaterial: StandardMaterial3D = load("res://assets/materials/pawnMaterial/MALE.tres")
@export var pawnColor: Color = Color(1.0, 0.76, 0.00, 1.0):
	set(value):
		pawnColor = value
		setupPawnColor()
#Base Components - Components required for this entity to even be used
@export_subgroup("Base Components")
@export var animationController: Node
@export var movementController: MovementController
@export var healthComponent: HealthComponent
@export_subgroup("Sub-Components")
@export var statModifierStack: StatModifierStack
@export var inputComponent: Node:
	set(value):
		inputComponent = value
		if value == InputComponent:
			emit_signal("controllerAssigned")
	get:
		return inputComponent
##Variables
@export_subgroup("Camera Behavior")
##Root Follow Node
@export var rootCameraNode: Node3D
##Camera Data for a camera to follow
@export var pawnCameraData: CameraData
##If a camera were to be attached to this node, it would follow this.
@export var followNode: Node3D
@export var attachedCam: PlayerCamera:
	set(value):
		attachedCam = value
		emit_signal("cameraAttached")
		#attachedCam.cameraRotationUpdated.connect(doMeshRotation.bind(get_physics_process_delta_time()))
	get:
		return attachedCam
@export_subgroup("Behavior")
var isStaggered: bool = false:
	set(value):
		isStaggered = value
		if value:
			isMoving = false
			velocity = Vector3.ZERO
			disableBodyIK()
			turnAmount = 0
			meshLookAt = false
			freeAim = false
			if currentItem and currentItem.isAiming:
				currentItem.isAiming = false
			movementController.enabled = false
			direction = Vector3.ZERO
		else:
			movementController.enabled = true
@export var isCrouching: bool = false:
	set(value):
		isCrouching = value
		var crouchSpeed = 0.35
		if crouchSpaceTween:
			crouchSpaceTween.kill()
		crouchSpaceTween = create_tween()
		if value:
			crouchSpaceTween.parallel().tween_property(animationTree, "parameters/crouchBlend/blend_amount", 1, crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
			crouchSpaceTween.parallel().tween_property(animationTree, "parameters/crouchStrafeBlend/blend_amount", 1, crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		else:
			crouchSpaceTween.parallel().tween_property(animationTree, "parameters/crouchBlend/blend_amount", 0, crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
			crouchSpaceTween.parallel().tween_property(animationTree, "parameters/crouchStrafeBlend/blend_amount", 0, crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
@export var fallDamageEnabled: bool = true
@export var forceAnimation: bool = false:
	set(value):
		emit_signal("forcingAnimation")
		forceAnimation = value
		if value == false:
			if animationTree:
				animationTree.active = false
		else:
			if animationTree:
				animationTree.active = true
@export var animationToForce: String = "":
	set(value):
		animationToForce = value
		if forceAnimation:
			if is_instance_valid(animationPlayer):
				if !animationPlayer.is_playing():
					animationPlayer.play(animationToForce)
##Allows the pawn to interact with the environment, move and have physics applied, etc..
@export var freeAim: bool = false:
	set(value):
		if freeAim != value:
			freeAim = value
			if freeAim:
				if !isStaggered:
					meshLookAt = true
			else:
				meshLookAt = false
			freeAimChanged.emit()
@export var pawnEnabled: bool = true
@export var isUsingFlashlight: bool = false:
	set(value):
		isUsingFlashlight = value
@export var animationPlayerSpeed: float = 1.0:
	set(value):
		animationPlayerSpeed = value
		if animationPlayer != null:
			animationPlayer.speed_scale = value
@export var collisionEnabled: bool = true:
	set(value):
		collisionEnabled = value
		if collisionShape:
			if collisionEnabled:
				collisionShape.disabled = false
			else:
				collisionShape.disabled = true
	get:
		return collisionEnabled

@export_subgroup("Variables")
signal pawnDied(pawnRagdoll: PawnRagdoll)
@export var turnAmount: float
@export var turnSpeed: float = 18.0
@export var isPawnDead: bool = false:
	set(value):
		isPawnDead = value
	get:
		return isPawnDead
@export var isMoving: bool = false:
	set(value):
		if is_instance_valid(self):
			isMoving = value
			if !isMoving:
	#			disableIdleSpaceBlend()
	#			disableRunBlend()
				if is_instance_valid(footstepSounds):
					if footstepSounds.playing:
						footstepSounds.stop()
@export_subgroup("Movement")
var coverNormal: Vector3
@export var isInCover: bool = false:
	set(value):
		if isInCover != value:
			isInCover = value
		if isInCover:
			hideCoverLabel()
			enableCoverTransition()
			isUsingPhone = false
		else:
			disableCoverTransition()
@export var canUseCover: bool = false:
	set(value):
		if canUseCover != value:
			canUseCover = value
		if value:
			if !isInCover and isPlayerPawn():
				showCoverLabel()
		else:
			hideCoverLabel()
@export var movementStates: Dictionary
@export var canRun: bool = true:
	set(value):
		if value:
			canRun = value
		else:
			canRun = false
@export var isRunning: bool = false:
	set(value):
		isRunning = value
@export var JUMP_VELOCITY: float = 4.5
@export var defaultWalkSpeed: float = 3.0
@export var defaultRunSpeed: float = 6.0
@export var canJump: bool = true
@export var isJumping: bool = false
@export_subgroup("Stair Handling")
const maxStepHeight: float = 0.49
var snappedToStairsLastFrame: bool = false
@export_subgroup("Throwables")
@export var throwForce: float = 35.0
@export_subgroup("Modifiers")
@export var reloadSpeedModifier: float = 1.0
@export var damageModifier: float = 1.0
@export var fireRateModifier: float = 1.0
@export var recoilModifier: float = 1.0
@export var blastResistanceModifier: float = 1.0
@export var bulletResistanceModifier: float = 1.0
@export var spreadModifier: float = 1.0
@export_subgroup("Inventory")
var pawnCash: int = 0
@export var itemInventory: Array
@export var currentItemIndex: int = 0:
	set(value):
		if !isPawnDead and is_instance_valid(self):
			if isUsingPhone:
				currentItemIndex = 0

			currentItemIndex = clamp(value, 0, itemInventory.size() - 1)
			currentItem = itemInventory[currentItemIndex]
			if !currentItem == null and !isUsingPhone:
				emit_signal("itemChanged")
				currentItem.isAiming = false
				equipWeapon(currentItemIndex)
				currentItem.isAiming = false
				currentItem.weaponOwner = self
				#setupWeaponAnimations()
				enableRightHand()
				checkMeshLookat()
				if is_instance_valid(currentItem.weaponResource):
					#await get_tree().process_frame
					if currentItem.weaponResource.leftHandParent:
						itemHolder.reparent(leftHandBone)
						itemHolder.position = Vector3.ZERO
					if currentItem.weaponResource.rightHandParent:
						itemHolder.reparent(rightHandBone)
						itemHolder.position = Vector3.ZERO

				if is_instance_valid(attachedCam):
					currentItem.weaponCast = attachedCam.camCast
					if currentItem.weaponResource.useCustomCrosshairSize:
						attachedCam.hud.getCrosshair().crosshairSize = currentItem.weaponResource.crosshairSizeOverride
					else:
						attachedCam.hud.getCrosshair().crosshairSize = attachedCam.hud.getCrosshair().defaultCrosshairSize
					if !UserConfig.game_simple_crosshairs:
						if is_instance_valid(currentItem.weaponResource.forcedCrosshair):
							attachedCam.hud.getCrosshair().setCrosshair(currentItem.weaponResource.forcedCrosshair)
						else:
							attachedCam.hud.getCrosshair().setCrosshair(attachedCam.hud.getCrosshair().defaultCrosshair)
					attachedCam.itemEquipOffsetToggle = true
					#Dialogic.VAR.set('playerHasWeaponEquipped',true)
					#attachedCam.resetCamCast()
			else:
				disableRightHand()
				disableLeftHand()
				setLeftHandFilterCover(true)
				setRightHandFilterCover(true)
				checkMeshLookat()
				for weapon in itemHolder.get_children():
					if weapon.isEquipped != false:
						weapon.isEquipped = false
					weapon.hide()
				if is_instance_valid(attachedCam):
					#Dialogic.VAR.set('playerHasWeaponEquipped',false)
					attachedCam.itemEquipOffsetToggle = false
					attachedCam.hud.getCrosshair().setCrosshair(null)
					attachedCam.hud.disableScope()
					setThirdperson()
@export var purchasedClothing: Array

@export var clothingInventory: Array:
	set(value):
		clothingInventory = value
		emit_signal("clothingChanged")

@export_subgroup("Mesh")
##Ragdoll to spawn when the pawn dies
@export var ragdollScene: PackedScene
##Makes the mesh look at a certain thing, mainly used for aiming
@export var meshLookAt: bool = false:
	set(value):
		if meshLookAt != value:
			meshLookAt = value
			meshLookAtChanged.emit(value)
		if meshLookAt:
			startBodyIK()
			if isInCover:
				disableCoverTransition()
				if peekable and !isPeeking:
					#isPeeking = true
					peekPos = global_position
					isPeeking = true
		else:
			disableBodyIK()

@export var lastHitPart: int:
	set(value):
		lastHitPart = value

@export var hitImpulse: Vector3 = Vector3.ZERO:
	set(value):
		hitImpulse = value

@export var hitVector: Vector3 = Vector3.ZERO
@export_subgroup("Misc")
const defaultTweenSpeed: float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var coverIndicatorTween: Tween

##Internal Variables

var direction: Vector3 = Vector3.ZERO:
	set(value):
		if direction != value:
			if is_instance_valid(self):
				direction = value

				#print(direction)
				directionChanged.emit()
				setDirection.emit(direction)
		if value != Vector3.ZERO:
			if is_instance_valid(self):
				direction = direction.normalized()
				if isRunning:
					setMovementState.emit(movementStates["sprint"])
				else:
					if isCrouching:
						setMovementState.emit(movementStates["crouchWalk"])
					else:
						setMovementState.emit(movementStates["walk"])
				isMoving = true
		else:
			if is_instance_valid(self):
				if isCrouching:
					setMovementState.emit(movementStates["crouch"])
				else:
					setMovementState.emit(movementStates["standing"])
				isMoving = false
		#if direction != Vector3.ZERO:
			#doMeshRotation()
var meshRotation: float = 0.0:
	set(value):
		if value != meshRotation and !isPawnDead and is_instance_valid(self):
			meshRotation = value
			#doMeshRotation()
var currentPawnMat: StandardMaterial3D
var raycaster: RayCast3D
var playingCall: bool = false
var queuedPhoneCall: ActorDialogue = null:
	set(value):
		queuedPhoneCall = value
		if is_instance_valid(queuedPhoneCall):
			if is_instance_valid(attachedCam):
				attachedCam.fadePhoneCallNotificationIn()
				gameManager.hideHUD()
				playRingtone()
		else:
			if is_instance_valid(attachedCam):
				attachedCam.fadePhoneCallNotificationOut()
				gameManager.hideHUD()

var isUsingPhone: bool = false:
	set(value):
		isUsingPhone = value
		if !value:
			canThrowThrowable = true
			playPhoneCloseAnimation()
		else:
			canThrowThrowable = false
			currentItem = null
			currentItemIndex = 0
			#print(freeAim)
var preventWeaponFire: bool = false:
	set(value):
		if preventWeaponFire != value:
			preventWeaponFire = value
			weaponFireChanged.emit()
			if currentItem:
				currentItem.checkWeaponBlend()
var directionNormal
var coverPosition: Vector3
var coverDirection: int = 0
var inPeekingProgress: bool = false
var peekable: bool = false
var isPeeking: bool = false:
	set(value):
		await get_tree().process_frame
		isPeeking = value
		if value:
			peekFromCover()
			disableCoverTransition()
		else:
			unPeekFromCover()
			enableCoverTransition()

var peekPos: Vector3
var isGrounded: bool = true
var lastFrameOnFloor: float = -INF
var throwableItem: PackedScene = load("res://assets/entities/throwables/grenade/Grenade.tscn")
var heldThrowable: ThrowableBase:
	set(value):
		heldThrowable = value
var throwableAmount: int = 5
var isArmingThrowable: bool = false:
	set(value):
		isArmingThrowable = value
		if isArmingThrowable and !isUsingPhone:
			enableThrowableAnim()
		else:
			disableThrowableAnim()
var canThrowThrowable: bool = true
var isThrowing: bool = false
var itemNames: Array
var currentItem: InteractiveObject = null

var throwableTween: Tween
var leftHandTween: Tween
var rightHandTween: Tween
var coverTween: Tween
var runTween: Tween
var fallTween: Tween
var idleSpaceTween: Tween
var crouchSpaceTween: Tween
var bodyIKTween: Tween
var meshRotationTween: Tween
var fireTween : Tween
var meshRotationTweenMovement: Tween
var flinchTween: Tween
var phoneTween: Tween
var coverMoveTween: Tween
var peekTween: Tween
var staggerTween: Tween
var lastLeftBlend: AnimationNodeStateMachinePlayback
## First-person, just for shits and giggles
var isFirstperson: bool = false:
	set(value):
		isFirstperson = value
		meshLookAt = value
		freeAim = value
var hitboxes: Array[Hitbox]
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

#Sounds
@onready var soundHolder: Node3D = $Sounds
@onready var equipSound: AudioStreamPlayer3D = $Sounds/equipSound
@onready var footstepSounds: AudioStreamPlayer3D = $Sounds/footsteps
##Onready
@onready var onScreenNotifier: VisibleOnScreenNotifier3D = $visibleOnScreenNotifier3d
@onready var componentHolder: Node3D = $Components
@onready var boneAttatchementHolder: Node = $BoneAttatchments
@onready var interactRaycast: RayCast3D = $Mesh/interactRaycast
##IK
@onready var bodyIK: SkeletonIK3D = $Mesh/MaleSkeleton/Skeleton3D/bodyIK
@onready var bodyIKMarker: Marker3D = $Mesh/bodyIKMarker
@onready var rightHandBone: BoneAttachment3D = $BoneAttatchments/rightHand
@onready var leftHandBone: BoneAttachment3D = $BoneAttatchments/leftHand
@onready var neckBone: BoneAttachment3D = $BoneAttatchments/Neck
@onready var upperChestBone: BoneAttachment3D = $BoneAttatchments/UpperChest
@onready var chestBone: BoneAttachment3D = $BoneAttatchments/Stomach
@onready var hipBone: BoneAttachment3D = $BoneAttatchments/Hips
@onready var stomachBone: BoneAttachment3D = $BoneAttatchments/Stomach
@onready var rightThighBone: BoneAttachment3D = $BoneAttatchments/RightThigh
@onready var leftThighBone: BoneAttachment3D = $BoneAttatchments/LeftThigh
@onready var flinchModifier: SkeletonModifier3D = $Mesh/MaleSkeleton/Skeleton3D/flinchMod
@onready var flinchMarker: Marker3D = %flinchmarker
##Pawn Parts
@onready var headHitbox: Hitbox = $BoneAttatchments/Neck/Hitbox
@onready var head: MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/MaleHead
@onready var maleBody: MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/maleBody
@onready var aimBlockRaycast: RayCast3D = $Mesh/aimDetect
@onready var floorcheck: RayCast3D = $floorCast
@onready var freeAimTimer: Timer = $freeAimTimer
@onready var pawnSkeleton: Skeleton3D = $Mesh/MaleSkeleton/Skeleton3D
@onready var animationTree: AnimationTree = $AnimationTree:
	set(value):
		animationTree = value
@onready var collisionShape: CollisionShape3D = $Collider
@onready var clothingHolder: Node3D = $Mesh/MaleSkeleton/Skeleton3D/Clothing
@onready var pawnMesh: Node3D = $Mesh
@onready var itemHolder: Node3D = $BoneAttatchments/rightHand/Weapons
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	setupAnimationTree()
	itemInventory.append(null)
	setMovementState.emit(movementStates["standing"])
	checkComponents()
	checkClothes()
	checkItems()

	if forceAnimation:
		animationTree.active = false
		animationPlayer.play(animationToForce)

	fixRot()
	setupPawnColor()
	setAdditiveAnimation()
	for i in getAllHitboxes():
		i.connect(&"damaged", flinch.bind(2))


func _physics_process(delta: float) -> void:
	if pawnEnabled:
		if !isPawnDead and is_instance_valid(self):

			#Set Last frame on floor
			if is_on_floor(): lastFrameOnFloor = Engine.get_physics_frames()
			if isCurrentlyMoving():
				setDirection.emit(direction)

			if fallDamageEnabled:
				if floorcheck.is_colliding() and !snappedToStairsLastFrame:
					if velocity.y <= -15:
						die(null)

			#Flashlight
			if isPlayerPawn() and isUsingFlashlight:
				%flashlight.global_rotation.y = attachedCam.camPivot.global_rotation.y
				%flashlight.global_rotation.x = attachedCam.vertical.global_rotation.x

			preventWeaponFire = aimBlockRaycast.is_colliding()

			#canUseCover = %lowerCoverCast.is_colliding()

			if $%lowerCoverCast.is_colliding():
				var offset = 0.2
				var colNormal: Vector3 = %lowerCoverCast.get_collision_normal()
				var colPoint: Vector3 = Vector3(%lowerCoverCast.get_collision_point().x, %lowerCoverCast.get_collision_point().y, %lowerCoverCast.get_collision_point().z)
				var normalAtan = atan2(colNormal.x, colNormal.y)
				var col: Vector3 = colPoint + Vector3(offset, 0, offset).rotated(Vector3.UP, normalAtan)
				#var dist : Vector3 = (%lowerCoverCast.get_collision_point() - global_position.distance_to(%lowerCoverCast.get_collision_point()))
				coverPosition = col
				%covermarker.global_position = coverPosition

			if isInCover:
				#var norm := get_slide_collision(0).get_normal()
				if coverDirection == 0:
					animationTree.set("parameters/coverTransition/transition_request", "movingLeft")
				else:
					animationTree.set("parameters/coverTransition/transition_request", "movingRight")

				if $%lowerCoverCast.is_colliding():
					coverNormal = %lowerCoverCast.get_collision_normal()
					#print(d.dot(Vector3(coverNormal.x,0,coverNormal.z)))

				directionNormal = direction.rotated(Vector3.UP, movementController.cameraRotation)
				%coverHolder.rotation.y = atan2(coverNormal.x, coverNormal.z)

				pawnMesh.rotation.y = lerpf(pawnMesh.rotation.y, atan2(coverNormal.x, coverNormal.z), 18 * delta)

				if attachedCam:
					#directionNormal = directionNormal.rotated(Vector3.UP,-attachedCam.horizontal.global_rotation_degrees.y).normalized()
					#print(directionNormal.dot(Vector3(coverNormal.x, 0, coverNormal.z)))
					if directionNormal.dot(Vector3(coverNormal.x, 0, coverNormal.z)) > 0.9:
						if peekTween:
							peekTween.kill()
						toggleCover()

				if coverDirection == 0 and !%rightCoverCast.is_colliding():
					peekable = true
					if atan2(direction.x, direction.z) < 0:
						direction = Vector3.ZERO
						#velocity= lerp(velocity,Vector3.ZERO,movementController.acceleration*delta*80)
				elif coverDirection == 1 and !%leftCoverCast.is_colliding():
					peekable = true
					if atan2(direction.x, direction.z) > 0:
						direction = Vector3.ZERO
						#velocity= lerp(velocity,Vector3.ZERO,movementController.acceleration*delta)
				else:
					peekable = false

			if isPlayerPawn() and freeAim:
				turnAmount = -attachedCam.vertical.rotation.x

			#Point the cover casts in the direction of the player, if its the player. otherwise just use the meshrotation
			if isPlayerPawn() and is_instance_valid(attachedCam) and !isInCover:
				%coverHolder.rotation_degrees.y = attachedCam.horizontal.global_rotation_degrees.y


##Checks to see if any required components (Base components) Are null
func checkComponents() -> void:
	if is_instance_valid(inputComponent):
		if inputComponent is AIComponent:
			inputComponent.pawnOwner = self
			await get_tree().process_frame
			inputComponent.aimCast.add_exception(self)
			for hitbox in getAllHitboxes():
				inputComponent.aimCast.add_exception(hitbox)
			raycaster = inputComponent.aimCast
			#%coverLabel.hide()
			set_meta(&"canBeStaggered", true)
			#healthComponent.connect("onDamaged",inputComponent.instantDetect.bind())
			#inputComponent.position = self.position

		if inputComponent is Component:
			inputComponent.controllingPawn = self
			if gameManager.activeCamera == null:
				gameManager.playerPawns.append(self)
				var cam = load("res://assets/entities/camera/camera.tscn")
				var _cam = cam.instantiate()
				gameManager.world.worldMisc.add_child(_cam)
				_cam.global_position = self.global_position
				_cam.posessObject(self, followNode)
				_cam.camCast.add_exception(self)
				_cam.interactCast.add_exception(self)
				headHitbox.hitboxDamageMult = 1.3
				raycaster = _cam.camCast
				add_to_group("Player")
				#neckMarker.reparent(_cam.camera, true)
				#neckModifier.target_node = neckMarker.get_path()
				attachedCam.setCamRot.connect(movementController.onSetCamRot)


func endPawn() -> void:
	if is_instance_valid(self) and not self.is_queued_for_deletion():
		for i in get_children():
			if i is BulletHole:
				i.reparent(gameManager.world.pooledObjects)
		get_tree().create_timer(2).timeout.connect(queue_free)
		#process_mode = Node.PROCESS_MODE_DISABLED
		#direction = Vector3.ZERO
		#velocity = Vector3.ZERO
		#removeComponents()
		#dropWeapon()
		#queue_free()
		#currentItemIndex = 0
		#pawnEnabled = false
		#collisionEnabled = false
		#if is_instance_valid(footstepSounds):
			#footstepSounds.queue_free()
		#print("Deleted %s at %s"%[name,Time.get_ticks_usec()])


func snapUpStairCheck(delta) -> bool:
	if not is_on_floor() and not snappedToStairsLastFrame: return false
	var expectedMotion = self.velocity * Vector3(1.3, 0, 1.3) * delta
	var stepPositionWithClearance = global_transform.translated(expectedMotion + Vector3(0, maxStepHeight * 1, 0))
	var downResult = PhysicsTestMotionResult3D.new()
	if (
			runBodyTestMotion(stepPositionWithClearance, Vector3(0, -maxStepHeight * 2, 0), downResult)
			and (downResult.get_collider().is_class("StaticBody3D") or downResult.get_collider().is_class("CSGShape3D"))):
		var stepHeight = ((stepPositionWithClearance.origin + downResult.get_travel()) - global_position).y
		if stepHeight > maxStepHeight or stepHeight <= 0.01 or (downResult.get_collision_point() - global_position).y > maxStepHeight: return false
		%stairRay.global_position = downResult.get_collision_point() + Vector3(0, maxStepHeight, 0) + expectedMotion.normalized() * 0.1
		%stairRay.force_raycast_update()
		if %stairRay.is_colliding() and not isSurfaceSteep(%stairRay.get_collision_normal()):
			global_position = stepPositionWithClearance.origin + downResult.get_travel()
			apply_floor_snap()
			snappedToStairsLastFrame = true
			return true
	return false


func stairSnapCheck() -> void:
	var _snapped: bool = false
	var isFloorBelow: bool = %stairUnder.is_colliding() and not isSurfaceSteep(%stairUnder.get_collision_normal())
	var wasOnFloorFrame = Engine.get_physics_frames() - lastFrameOnFloor == 1
	if not is_on_floor() and velocity.y <= 0 and (wasOnFloorFrame or snappedToStairsLastFrame) and isFloorBelow:
		var testResult = PhysicsTestMotionResult3D.new()
		if runBodyTestMotion(global_transform, Vector3(0, -maxStepHeight, 0), testResult):
			var yTranslate = testResult.get_travel().y
			self.position.y += yTranslate
			apply_floor_snap()
			_snapped = true
	snappedToStairsLastFrame = _snapped


func isSurfaceSteep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle


func runBodyTestMotion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)


func endAttachedCam() -> void:
	if is_instance_valid(attachedCam):
		if gameManager.bulletTime:
			gameManager.bulletTime = false
		attachedCam.hud.flashColor(Color.DARK_RED)
		gameManager.doDeathEffect()
		attachedCam.stopCameraRecoil()
		#attachedCam.cameraRotationUpdated.disconnect(doMeshRotation)
		gameManager.getEventSignal("playerDied").emit()
		attachedCam.hud.hudEnabled = false
		attachedCam.resetCamCast()
		#Dialogic.end_timeline()


func isPlayerPawn() -> bool:
	if has_meta(&"isPlayer"):
		return get_meta(&"isPlayer")
	else:
		return false


func moveHitboxDecals(parent: Node3D = gameManager.world.worldParticles) -> void:
	if is_instance_valid(gameManager.world):
		for boxes in getAllHitboxes():
			for decals in boxes.get_children():
				if decals is BulletHole:
					decals.reparent(parent)


func playKillSound() -> void:
	var stream: AudioStream = load("res://assets/resources/killsoundStream.tres")
	gameManager.createSoundAtPosition(stream, pawnMesh.global_position)


func die(killer) -> void:
	if is_instance_valid(self) and !isPawnDead:
		isPawnDead = true
		if isPlayerPawn():
			stopPhoneCall()
			gameManager.removePhoneMenu()
		%flipphone.queue_free()
		stopRingtone()
		gameManager.allPawns.erase(self)
		gameManager.doKillEffect(self, killer)
		dropWeapon()
		onPawnKilled.emit()
		playKillSound()
		var ragdoll = createRagdoll(lastHitPart, killer)
		#moveHitboxDecals()
		moveDecalsToRagdoll(ragdoll)
		endPawn()
		hide()
		pawnEnabled = false
		collisionShape.disabled = true
		animationController.enabled = false
		movementController.enabled = false
		killAllTweens()
		disableAllHitboxes()


func applyRagdollImpulse(ragdoll: PawnRagdoll, currentVelocity: Vector3, impulseBone: int = 0) -> void:
	for bones in ragdoll.physicalBoneSimulator.get_children():
		if bones is RagdollBone:
			bones.linear_velocity = currentVelocity
			bones.angular_velocity = currentVelocity
			bones.apply_central_impulse(currentVelocity)
			if bones.get_bone_id() == impulseBone:
				#ragdoll.startRagdoll()
				bones.apply_central_impulse(hitImpulse * randf_range(1.5, 2))


func setRagdollPose(ragdoll: PawnRagdoll) -> void:
	for bones in ragdoll.ragdollSkeleton.get_bone_count():
		ragdoll.ragdollSkeleton.set_bone_global_pose(bones, pawnSkeleton.get_bone_global_pose(bones))


func setRagdollPositionAndRotation(ragdoll: PawnRagdoll) -> void:
	ragdoll.targetSkeleton = pawnSkeleton
	ragdoll.global_transform = pawnMesh.global_transform
	ragdoll.rotation = pawnMesh.rotation


func createRagdoll(impulse_bone: int = 0, killer = null) -> PawnRagdoll:
	var ragdoll: PawnRagdoll = ragdollScene.instantiate()
	gameManager.world.worldMisc.add_child(ragdoll)
	ragdoll.savedPose = createRagdollPose(ragdoll)
	ragdoll.targetSkeleton = pawnSkeleton
	ragdoll.initializeRagdoll(self, velocity, impulse_bone, hitImpulse, hitVector, killer)
	return ragdoll


func createRagdollPose(ragdoll: PawnRagdoll) -> Array[Transform3D]:
	var pose: Array[Transform3D] = []
	for i in ragdoll.physicsBones:
		for ps in pawnSkeleton.get_bone_count():
			pose.append(pawnSkeleton.get_bone_pose(i.get_bone_id()))
	return pose


func checkItems() -> void:
	for items in itemHolder.get_children():
		items.freeze = true
		items.collisionObject.disabled = true
		items.collisionEnabled = false
		if !items.isEquipped:
			items.visible = false
		items.position = Vector3.ZERO
		items.rotation = Vector3.ZERO
		if !itemInventory.has(items):
			itemInventory.append(items)
		if !itemNames.has(items.objectName):
			itemNames.append(items.objectName)


func checkClothes() -> void:
	clothingInventory.clear()
	#resetBodyShape()
	for clothes in clothingHolder.get_children():
		if !clothingInventory.has(clothes):
			clothingInventory.append(clothes)
			clothes.itemSkeleton = pawnSkeleton.get_path()
			clothes.remapSkeleton()
			setBodyShape(clothes)
#	checkClothingHider()


func moveClothesToRagdoll(moveto: Node3D) -> void:
	for clothes in clothingHolder.get_children():
		clothes.itemSkeleton = moveto.ragdollSkeleton.get_path()
		clothes.reparent(moveto)
		clothes.remapSkeleton()
	return


func setBodyShape(clothingItem: ClothingItem):
	if clothingItem.leftUpperarm > 0:
		maleBody.set_blend_shape_value(0, clothingItem.leftUpperarm)
	if clothingItem.leftShoulder > 0:
		maleBody.set_blend_shape_value(1, clothingItem.leftShoulder)
	if clothingItem.leftUpperLeg > 0:
		maleBody.set_blend_shape_value(2, clothingItem.leftUpperLeg)
	if clothingItem.rightUpperLeg > 0:
		maleBody.set_blend_shape_value(3, clothingItem.rightUpperLeg)
	if clothingItem.lowerPelvis > 0:
		maleBody.set_blend_shape_value(4, clothingItem.lowerPelvis)
	if clothingItem.lowerStomach > 0:
		maleBody.set_blend_shape_value(5, clothingItem.lowerStomach)
	if clothingItem.middleStomach > 0:
		maleBody.set_blend_shape_value(6, clothingItem.middleStomach)
	if clothingItem.leftKnee > 0:
		maleBody.set_blend_shape_value(7, clothingItem.leftKnee)
	if clothingItem.rightKnee > 0:
		maleBody.set_blend_shape_value(8, clothingItem.rightKnee)
	if clothingItem.leftForearm > 0:
		maleBody.set_blend_shape_value(9, clothingItem.leftForearm)
	if clothingItem.rightForearm > 0:
		maleBody.set_blend_shape_value(10, clothingItem.rightForearm)
	if clothingItem.rightUpperarm > 0:
		maleBody.set_blend_shape_value(11, clothingItem.rightUpperarm)
	if clothingItem.rightShoulder > 0:
		maleBody.set_blend_shape_value(12, clothingItem.rightShoulder)
	if clothingItem.upperChest > 0:
		maleBody.set_blend_shape_value(13, clothingItem.upperChest)


func checkClothingHider() -> void:
	#setBodyVisibility(true)
	pass


func moveDecalsToRagdoll(ragdoll: PawnRagdoll) -> bool:
	#Decal reparent..
	for hboxes in getAllHitboxes():
		for decals in hboxes.get_children():
			if decals is BulletHole:
				#print(decals)
				for bone in ragdoll.physicsBones:
					if bone.get_bone_id() == hboxes.boneId:
						decals.reparent(bone, true)
						#print(decals.get_parent())
						#Console.add_console_message("For %s, %s" %[self,getCurrentDecalBones()])
	return true


func getAllHitboxes() -> Array[Hitbox]:
	return hitboxes


func killAllTweens() -> void:
	if throwableTween:
		throwableTween.kill()
	if leftHandTween:
		leftHandTween.kill()
	if rightHandTween:
		rightHandTween.kill()
	if runTween:
		runTween.kill()
	if fallTween:
		fallTween.kill()
	if idleSpaceTween:
		idleSpaceTween.kill()
	if crouchSpaceTween:
		crouchSpaceTween.kill()
	if bodyIKTween:
		bodyIKTween.kill()
	if meshRotationTween:
		meshRotationTween.kill()
	if meshRotationTweenMovement:
		meshRotationTweenMovement.kill()
	if flinchTween:
		flinchTween.kill()
	if animationController.tweener:
		animationController.tweener.kill()
	if movementController.meshRotationTween:
		movementController.meshRotationTween.kill()
	if movementController.meshRotationTweenMovement:
		movementController.meshRotationTweenMovement.kill()


func jump() -> void:
	playFootstepAudio()
	if !isJumping:
		isJumping = true
		canJump = false
		if is_on_floor() or snappedToStairsLastFrame:
			isJumping = false
	velocity.y = JUMP_VELOCITY


func setupWeaponAnimations() -> void:
	if !is_instance_valid(animationTree): return
	var blendSet
	if is_instance_valid(currentItem):
		blendSet = currentItem.animationTree.tree_root
		#print(blendSet)
		#if !currentItem.weaponAnimSet:
			##Swap out animationLibraries
		if is_instance_valid(animationPlayer):
			if animationPlayer.has_animation_library("weaponAnims"):
				animationPlayer.remove_animation_library("weaponAnims")
			if is_instance_valid(currentItem.animationPlayer):
				var libraryToAdd = currentItem.animationPlayer.get_animation_library("weaponAnims").duplicate()
				animationPlayer.add_animation_library("weaponAnims", libraryToAdd)

			#Add the weapons stateMachine to the pawn
			(animationTree.tree_root as AnimationNodeBlendTree).disconnect_node("weaponBlend_Scale", 0)
			animationTree.tree_root.remove_node("weaponState")
			animationTree.tree_root.add_node("weaponState", blendSet.duplicate())
			(animationTree.tree_root as AnimationNodeBlendTree).connect_node("weaponBlend_Scale", 0, "weaponState")
			currentItem.weaponRemoteState = animationTree.get("parameters/weaponState/weaponState/playback")
			animationTree.set("parameters/weaponState/weaponState/playback", currentItem.weaponRemoteState)
			##Left Hand
			(animationTree.tree_root as AnimationNodeBlendTree).disconnect_node("weaponBlendLeft_Scale", 0)
			animationTree.tree_root.remove_node("weaponBlend_left")
			animationTree.tree_root.add_node("weaponBlend_left", blendSet.duplicate())
			(animationTree.tree_root as AnimationNodeBlendTree).connect_node("weaponBlendLeft_Scale", 0, "weaponBlend_left")
			currentItem.weaponRemoteStateLeft = animationTree.get("parameters/weaponBlend_left/weaponState/playback")
			lastLeftBlend = currentItem.weaponRemoteStateLeft
			currentItem.weaponAnimSet = true
	else:
		print_rich("[color=red]You don't have a weapon![/color]")
		return


func setLeftHandFilter(value: bool = true) -> void:
	var filterBlend: AnimationNodeBlend2 = animationTree.tree_root.get_node("weaponBlend_Left_blend")
	filterBlend.set_filter_path("..:[Functions/Functions]", true)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Shoulder", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_UpperArm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Forearm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Hand", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie2", value)
	#Additive
	var filterBlend2: AnimationNodeAdd2 = animationTree.tree_root.get_node("Add2")
	filterBlend2.set_filter_path("..:[Functions/Functions]", true)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Shoulder", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_UpperArm", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Forearm", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Hand", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Index0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Index1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Index2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie2", value)

func setFireAdditive(minvalue:float,maxvalue:float)->void:
	#var addBlend: AnimationNodeAdd2 = animationTree.tree_root.get_node("Add2")
	animationTree.set("parameters/Add2/add_amount",randf_range(minvalue,maxvalue))
	if fireTween:
		fireTween.kill()
	fireTween = create_tween()
	fireTween.tween_property(animationTree,"parameters/Add2/add_amount",0,randf_range(0.15,0.25)).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

func setRightHandFilter(value: bool = true) -> void:
	var filterBlend: AnimationNodeBlend2 = animationTree.tree_root.get_node("weaponBlend")
	filterBlend.set_filter_path("..:[Functions/Functions]", true)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Shoulder", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_UpperArm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Forearm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Hand", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie2", value)
	#Additive
	var filterBlend2: AnimationNodeAdd2 = animationTree.tree_root.get_node("Add2")
	filterBlend2.set_filter_path("..:[Functions/Functions]", true)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Shoulder", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_UpperArm", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Forearm", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Hand", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Index0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Index1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Index2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring2", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie0", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie1", value)
	filterBlend2.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie2", value)

func setLeftHandFilterCover(value: bool = true) -> void:
	var filterBlend: AnimationNodeBlend2 = animationTree.tree_root.get_node("coverBlend")
	filterBlend.set_filter_path("..:[Functions/Functions]", true)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Shoulder", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_UpperArm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Forearm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Hand", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie2", value)


func setRightHandFilterCover(value: bool = true) -> void:
	var filterBlend: AnimationNodeBlend2 = animationTree.tree_root.get_node("coverBlend")
	filterBlend.set_filter_path("..:[Functions/Functions]", true)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Shoulder", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_UpperArm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Forearm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Hand", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie2", value)


func playEquipSound() -> void:
	if !equipSound.playing and !isUsingPhone:
		equipSound.play()


func equipWeapon(index: int) -> void:
	unequipWeapon()
	playEquipSound()
	currentItem = itemInventory[index]
	if !freeAimChanged.is_connected(currentItem.checkFreeAim):
		freeAimChanged.connect(currentItem.checkFreeAim)
	#weaponFireChanged.connect(checkWeaponBlend)
	currentItem.weaponOwner = self
	currentItem.isEquipped = true
	currentItem.visible = true
	currentItem.freeze = true
	setupWeaponAnimations()
	if currentItem.weaponResource.useRightHandCover:
		setRightHandFilterCover(false)
	if currentItem.weaponResource.useLeftHandCover:
		setLeftHandFilterCover(false)


func unequipWeapon() -> void:
	animationTree.set("parameters/weaponBlend/blend_amount", 0)
	animationTree.set("parameters/weaponBlend_Left_blend/blend_amount", 0)
	if is_instance_valid(lastLeftBlend):
		lastLeftBlend.stop()
	for weapon in itemHolder.get_children():
		weapon.hide()
		weapon.resetToDefault()
	if currentItem:
		if weaponFireChanged.is_connected(currentItem.checkFreeAim):
			weaponFireChanged.disconnect(currentItem.checkFreeAim)
		if weaponFireChanged.is_connected(currentItem.checkWeaponBlend):
			weaponFireChanged.disconnect(currentItem.checkWeaponBlend)
		currentItem.resetToDefault()
		currentItem.weaponAnimSet = false
		currentItem.isEquipped = false
		currentItem.isAiming = false
		currentItem.hide()
		currentItem = null
		setRightHandFilterCover(true)
		setLeftHandFilterCover(true)


func resetBodyShape() -> void:
	if maleBody:
		for i in maleBody.get_blend_shape_count():
			maleBody.set_blend_shape_value(i, 0)


func removeComponents() -> void:
	if is_instance_valid(healthComponent):
		healthComponent.queue_free()
		healthComponent = null

	if is_instance_valid(movementController):
		movementController.queue_free()
		movementController = null

	if is_instance_valid(animationController):
		animationController.queue_free()
		animationController = null

	if is_instance_valid(inputComponent):
		inputComponent.queue_free()
		inputComponent = null

#func checkFootstepMateral() -> void:
	#if footstepMaterialChecker.is_colliding():
		#return


func playFootstepAudio(soundprofile: AudioStream = null) -> void:
	if !footstepSounds == null and !isPawnDead:
		if is_on_floor() and isMoving:
			if !soundprofile == null:
				footstepSounds.stream = soundprofile

			if !footstepSounds.playing:
				footstepSounds.play()


func dropWeapon() -> void:
	if !isPawnDead:
		animationTree.set("parameters/weaponBlend/blend_amount", 0)
		animationTree.set("parameters/weaponBlend_left/blend_amount", 0)
	if is_instance_valid(currentItem):
		var pos = currentItem.global_position
		for i in itemInventory:
			if i == currentItem:
				itemInventory.erase(i)

		currentItem.weaponOwner = null
		currentItem.resetToDefault()
		currentItem.collisionEnabled = true
		currentItem.weaponAnimSet = false
		currentItem.isEquipped = false
		currentItem.show()
		currentItem.setInteractable()
		currentItem.apply_impulse(velocity)
		currentItem.reparent(gameManager.world.worldMisc)
		currentItem.global_position = pos
		currentItem.resetWeaponMesh()
		currentItem = null


func setFirstperson() -> void:
	isFirstperson = true
	rootCameraNode = $BoneAttatchments/Neck
	pawnCameraData = load("res://assets/resources/pawnRelated/pawnFPSCam.tres")
	attachedCam.posessObject(self, rootCameraNode)
	head.hide()
	#upperChest.hide()


func setThirdperson() -> void:
	if freeAim and isFirstperson:
		freeAim = false
		isFirstperson = false
	isFirstperson = false
	rootCameraNode = $BoneAttatchments/UpperChest
	pawnCameraData = load("res://assets/resources/pawnRelated/pawnDefaultCamData.tres")
	attachedCam.posessObject(self, rootCameraNode)
	head.show()
	#upperChest.show()
	checkClothes()


func fixRot() -> void:
	pawnMesh.rotation = self.rotation
	self.rotation = Vector3.ZERO


func playAnimation(animation: String) -> void:
	if !forceAnimation:
		forceAnimation = true
	animationPlayer.play(animation)


func getInteractionObject():
	if interactRaycast.is_colliding():
		var col = interactRaycast.get_collider()
		if is_instance_valid(col):
			if col.is_in_group("Interactable"):
				gameManager.getEventSignal("interactableFound").emit()
				return col


func getClothes():
	for clothes in clothingHolder.get_children():
		return clothes


func moveItemToWeapons(item: Weapon) -> void:
	item.reparent(itemHolder)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	checkItems()


func setPawnMaterial() -> void:
	currentPawnMat.albedo_color = pawnColor
	if is_instance_valid(pawnSkeleton):
		for mesh in pawnSkeleton.get_children():
			if mesh is MeshInstance3D:
				mesh.set_surface_override_material(0, currentPawnMat)


func setupPawnColor() -> void:
	if pawnColor != Color(1.0, 0.76, 0.00, 1.0):
		if !currentPawnMat:
			currentPawnMat = defaultPawnMaterial.duplicate()
			setPawnMaterial()


func setupAnimationTree() -> void:
	if animationTree:
		animationTree.active = false
		animationPlayer.active = false
		var dupRoot = gameManager.defaultPawnTreeRoot.duplicate()
		animationTree.tree_root = null
		animationTree.tree_root = dupRoot
		animationTree.active = true
		animationPlayer.active = true
		var filterBlend2: AnimationNodeAnimation = animationTree.tree_root.get_node("additiveAnim")
		filterBlend2.animation = "PawnAnim/Idle"


func setRunBlendFilters(value: bool) -> void:
	var filterBlend = animationTree.tree_root.get_node("weaponBlend")
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Shoulder", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_UpperArm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Forearm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Hand", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Thumb2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Index2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Middle2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Ring2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:R_Pinkie2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Shoulder", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_UpperArm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Forearm", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Hand", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Thumb2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Index2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Middle2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Ring2", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie0", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie1", value)
	filterBlend.set_filter_path("MaleSkeleton/Skeleton3D:L_Pinkie2", value)


func doMeshRotation() -> void:
	if !isPawnDead and is_instance_valid(self):
		#await get_tree().process_frame
		if meshRotationTween:
			meshRotationTween.kill()
		meshRotationTween = create_tween()
		meshRotationTween.set_parallel(true)
		if meshRotationTweenMovement:
			meshRotationTweenMovement.kill()
		meshRotationTweenMovement = create_tween()
		meshRotationTweenMovement.set_parallel(true)
		if meshRotationTween:
			if !meshLookAt:
				if isMoving:
					#var rotationTarget = lerp_angle(pawnMesh.rotation.y, atan2(-velocity.x,-velocity.z), 1)
					if direction != Vector3.ZERO:
						meshRotationTween.tween_property(pawnMesh, "rotation:y", getShortTweenAngle(pawnMesh.rotation.y, atan2(-direction.x, -direction.z)), 0.25)
			else:
				canJump = false
				bodyIKMarker.rotation.x = turnAmount
				#bodyIKMarker.rotation_degrees.y = lerpf(bodyIKMarker.rotation_degrees.y, to_local(Vector3(0,180,0)).y, 16*delta)
				meshRotationTweenMovement.tween_property(bodyIKMarker, "rotation:z", getShortTweenAngle(bodyIKMarker.rotation.z, 0.0), 0.05)
				meshRotationTween.tween_property(pawnMesh, "rotation:y", getShortTweenAngle(pawnMesh.rotation.y, meshRotation), 0.02)
				#pawnMesh.rotation.y = lerp_angle(pawnMesh.rotation.y, meshRotation, 23 * delta)
				#bodyIKMarker.rotation.z = lerpf(bodyIKMarker.rotation.z, 0.0, 16*delta)

	#if !is_on_wall():
		#if is_on_floor():
			#pawnMesh.rotation.x = clamp(lerp_angle(pawnMesh.rotation.x, (Vector3(velocity.x, 0.0, velocity.z) * pawnMesh.global_transform.basis).z * 0.015, delta * 16), -7, 7)
		#else:
			#pawnMesh.rotation.x = clamp(lerp_angle(pawnMesh.rotation.x, (Vector3(velocity.y, velocity.y, velocity.y) * pawnMesh.global_transform.basis).y * 0.030, delta * 8), -1, 1)
		#pawnMesh.rotation.z = clamp(lerpf(pawnMesh.rotation.z, -(Vector3(velocity.x,0.0, velocity.z) * pawnMesh.global_transform.basis).x * 0.035, 16 * delta), -3, 3)
	#else:
		#pawnMesh.rotation.x = lerpf(pawnMesh.rotation.x, 0, 12*delta)
		#pawnMesh.rotation.z = lerpf(pawnMesh.rotation.z, 0, 12*delta)


func getPawnSkeleton() -> Skeleton3D:
	#When the female skeleton gets added we will use this to get the skeleton of the character, but for now just return the male one
	return $Mesh/MaleSkeleton/Skeleton3D


func flinch(flinchDirection: Vector3) -> void:
	##New Flinch
	#print(flinchDirection)
	if flinchTween:
		flinchTween.kill()
	flinchTween = create_tween()
	flinchModifier.influence = 1
	flinchModifier.active = true
	flinchMarker.position = flinchMarker.position.move_toward(-(flinchDirection - flinchMarker.position).rotated(Vector3.UP, pawnMesh.global_transform.basis.get_euler().y) * randf_range(0.3, 0.7), 0.25)
	await flinchTween.tween_property(flinchModifier, "influence", 0, randf_range(0.2, 0.6)).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
	flinchModifier.active = false


func armThrowable() -> void:
	if canThrowThrowable and !isArmingThrowable and throwableAmount > 0 and !is_instance_valid(heldThrowable) and !isUsingPhone:
		heldThrowable = throwableItem.instantiate()
		%leftHandHold.add_child(heldThrowable)
		heldThrowable.dealer = self
		heldThrowable.freeze = true
		heldThrowable.add_collision_exception_with(self)
#		heldThrowable.collisionShape.disabled = true
		animationTree.set("parameters/leftArmed_Throw/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE)
		isArmingThrowable = true
		isThrowing = false


func disarmThrowable() -> void:
	if isArmingThrowable:
		animationTree.set("parameters/leftArmed_Throw/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
		canThrowThrowable = true
		isThrowing = false
		isArmingThrowable = false


func resetThrowables() -> void:
	disableThrowableAnim()
	await get_tree().create_timer(0.5).timeout
	canThrowThrowable = true
	isThrowing = false
	isArmingThrowable = false


func throwThrowable() -> void:
	if is_instance_valid(heldThrowable):
		throwableAmount -= 1
		isThrowing = true
		canThrowThrowable = false
		animationTree.set("parameters/leftArmed_Throw/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		## Throw the actual throwable here
		#heldThrowable.collisionShape.disabled = false
		heldThrowable.reparent(gameManager.world.worldProps)
		heldThrowable.freeze = false
		heldThrowable.thrown.emit()
		heldThrowable.isThrown = true
		heldThrowable.dealer = self
		if is_instance_valid(attachedCam):
			attachedCam.fireRecoil(0.0, 0.0, 0.8, true)
			heldThrowable.global_position = neckBone.global_position
			heldThrowable.global_position.z += 0.25
			heldThrowable.apply_central_impulse((attachedCam.camCast.global_transform.basis.z * -throwForce) + Vector3(0, -turnAmount, 0))
		else:
			heldThrowable.apply_central_impulse((pawnMesh.global_transform.basis.z * -throwForce) + Vector3(0, -turnAmount, 0))
		heldThrowable = null
		%throwSound.play()
		#heldThrowable.apply_central_impulse()
		await get_tree().create_timer(0.3).timeout
		canThrowThrowable = true
		isThrowing = false
		isArmingThrowable = false


func savePawnFile(pawnInfo: String, pawnFilename: String = "player") -> String:
	Console.add_rich_console_message("[color=green]Saving Pawn to File..[/color]")
	var path = FileAccess.open("%s.pwn"%pawnFilename, FileAccess.WRITE)
	path.store_line(pawnInfo)
	Console.add_rich_console_message("[color=green]Saved Pawn info to file![/color]")
	return "%s.pwn"%pawnFilename


func savePawnInformation() -> String:
	Console.add_rich_console_message("[color=green]Saving Pawn Info..[/color]")
	var saveWeapons: Array
	var saveWeaponAmmo: Array
	var saveWeaponMags: Array
	var saveClothes: Array
	var purchasedClothes: Array
	var clothesColors: Array
	saveWeapons.clear()
	for weapons in itemInventory.size():
		if itemInventory[weapons] != null:
			saveWeapons.append(itemInventory[weapons].get_scene_file_path())
			saveWeaponAmmo.append(itemInventory[weapons].currentAmmo)
			saveWeaponMags.append(itemInventory[weapons].currentMagSize)
	saveClothes.clear()
	#purchasedClothes.clear()

	for clothes in purchasedClothing.size():
		if !purchasedClothes.has(purchasedClothing[clothes]):
			purchasedClothes.append(purchasedClothing[clothes])

	for clothes in clothingInventory.size():
		if is_instance_valid(clothingInventory[clothes]):
			saveClothes.append(clothingInventory[clothes].get_scene_file_path())
			if !purchasedClothes.has(clothingInventory[clothes].get_scene_file_path()):
				purchasedClothes.append(clothingInventory[clothes].get_scene_file_path())

	for clothes in clothingInventory.size():
		if clothingInventory[clothes] != null:
			var overrides = gameManager.getMeshSurfaceOverrides(clothingInventory[clothes].clothingMesh)
			var colors = []
			for i in overrides:
				if i:
					var clr = i.albedo_color.to_html()
					colors.append(clr)
			clothesColors.append(colors)

	var pwnDict = {
		"clothes": saveClothes,
		"clothesColors": clothesColors,
		"purchasedClothes": purchasedClothes,
		"items": saveWeapons,
		"itemAmmo": saveWeaponAmmo,
		"itemMags": saveWeaponMags,
		"pawnColorR": pawnColor.r,
		"pawnColorG": pawnColor.g,
		"pawnColorB": pawnColor.b,
	}
	var stringy = JSON.stringify(pwnDict)
	Console.add_rich_console_message("[color=green]Saved Pawn info![/color]")
	return stringy


func loadPawnFile(pawnFile: String = "player") -> void:
	if not FileAccess.file_exists(pawnFile):
		Console.add_rich_console_message("[color=red]Pawn file doesn't exist![/color]")
		print(pawnFile)
		return

	var pwnFile = FileAccess.open(pawnFile, FileAccess.READ)
	while pwnFile.get_position() < pwnFile.get_length():
		var string = pwnFile.get_line()
		loadPawnInfo(string)


func loadPawnInfo(pawnInfo: String) -> void:
	purchasedClothing.clear()
	clothingInventory.clear()
	itemInventory.clear()
	for clothes in clothingHolder.get_children():
		clothes.queue_free()
	for weapons in itemHolder.get_children():
		weapons.queue_free()
	resetBodyShape()
	itemInventory.append(null)

	var json = JSON.new()
	var result = json.parse(pawnInfo)

	if not result == OK:
		Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%pawnInfo)
		return

	var nodeData: Variant = json.get_data()

	##Create Inventory Items/Clothes
	var itemAmmo: Array
	var itemMags: Array
	if nodeData["itemAmmo"] != null:
		itemAmmo = nodeData["itemAmmo"]
	if nodeData["itemMags"] != null:
		itemMags = nodeData["itemMags"]

	var items: Array = nodeData["items"]
	for item in items:
		var index: int = items.find(item)
		var inventoryItem: Weapon = load(item).instantiate()
		itemHolder.add_child(inventoryItem)
		if nodeData["itemAmmo"] != null and nodeData["itemMags"] != null:
			if itemAmmo.size() > 0:
				inventoryItem.currentAmmo = itemAmmo[index]
			if itemMags.size() > 0:
				inventoryItem.currentMagSize = itemMags[index]

	if nodeData["purchasedClothes"] != null:
		purchasedClothing = nodeData["purchasedClothes"]

	for clothing in nodeData["clothes"]:
		#var colors = nodeData["clothesColors"]
		var clothingItem: ClothingItem = load(clothing).instantiate()
		clothingHolder.add_child(clothingItem)
		for i in clothingItem.clothingMesh.get_surface_override_material_count():
			if !clothingItem.clothingMesh.get_surface_override_material(i):
				gameManager.createOverrideFromSurfaceMaterial(clothingItem.clothingMesh, clothingItem.clothingMesh.mesh, i)
			var mat = clothingItem.clothingMesh.get_surface_override_material(i)
			var clr = Color.html(nodeData["clothesColors"][nodeData["clothes"].find(clothing)][i])
			print("Item: %s | Color : %s | Surface ID: %s" % [clothingItem, clr, i])
			mat.albedo_color = clr
				#clothingItem.clothingMesh.set_surface_override_material(i,mat)

	checkClothes()
	checkItems()
	pawnColor = Color(nodeData["pawnColorR"], nodeData["pawnColorG"], nodeData["pawnColorB"], 1)
	Console.add_rich_console_message("[color=green]Loaded Pawn File![/color]")


func setThrowableBlendValue(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/leftThrowableBlend/blend_amount", value)


func setRightHandBlendValue(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/weaponBlend/blend_amount", value)


func setLeftHandBlendValue(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/weaponBlend_Left_blend/blend_amount", value)


func enableRunBlend() -> void:
	if !isPawnDead and is_instance_valid(self):
		if runTween:
			runTween.kill()
		runTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/runBlend/blend_amount")
		runTween.tween_method(setRunBlendValue, currentBlend, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func disableRunBlend() -> void:
	if !isPawnDead and is_instance_valid(self):
		if runTween:
			runTween.kill()
		runTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/runBlend/blend_amount")
		runTween.tween_method(setRunBlendValue, currentBlend, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func enableFallBlend() -> void:
	if !isPawnDead and is_instance_valid(self):
		if fallTween:
			fallTween.kill()
		fallTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/fallBlend/blend_amount")
		fallTween.tween_method(setFallBlendValue, currentBlend, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func disableFallBlend() -> void:
	if !isPawnDead and is_instance_valid(self):
		if fallTween:
			fallTween.kill()
		fallTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/fallBlend/blend_amount")
		fallTween.tween_method(setFallBlendValue, currentBlend, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func enableIdleSpaceBlend() -> void:
	if !isPawnDead and is_instance_valid(self):
		if idleSpaceTween:
			idleSpaceTween.kill()
		idleSpaceTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/idleSpace/blend_position")
		idleSpaceTween.tween_method(setIdleBlend, currentBlend, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func disableIdleSpaceBlend() -> void:
	if !isPawnDead and is_instance_valid(self):
		if idleSpaceTween:
			idleSpaceTween.kill()
		idleSpaceTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/idleSpace/blend_position")
		idleSpaceTween.tween_method(setIdleBlend, currentBlend, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func enableLeftHand() -> void:
	if !isPawnDead and is_instance_valid(self):
		if leftHandTween:
			leftHandTween.kill()
		leftHandTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/weaponBlend_Left_blend/blend_amount")
		leftHandTween.tween_method(setLeftHandBlendValue, currentBlend, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		#tween.tween_callback(tween.kill)


func enableRightHand() -> void:
	if !isPawnDead and is_instance_valid(self):
		if rightHandTween:
			rightHandTween.kill()
		rightHandTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/weaponBlend/blend_amount")
		rightHandTween.tween_method(setRightHandBlendValue, currentBlend, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		#tween.tween_callback(tween.kill)


func disableLeftHand() -> void:
	if !isPawnDead and is_instance_valid(self):
		if leftHandTween:
			leftHandTween.kill()
		leftHandTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/weaponBlend_Left_blend/blend_amount")
		leftHandTween.tween_method(setLeftHandBlendValue, currentBlend, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		#tween.tween_callback(tween.kill)


func disableRightHand() -> void:
	if !isPawnDead and is_instance_valid(self):
		if rightHandTween:
			rightHandTween.kill()
		rightHandTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/weaponBlend/blend_amount")
		rightHandTween.tween_method(setRightHandBlendValue, currentBlend, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		#rightHandTween.tween_callback(tween.kill)


func disableThrowableAnim() -> void:
	if !isPawnDead and is_instance_valid(self):
		if throwableTween:
			throwableTween.kill()
		throwableTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/leftThrowableBlend/blend_amount")
		throwableTween.tween_method(setThrowableBlendValue, currentBlend, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func enableThrowableAnim() -> void:
	if !isPawnDead and is_instance_valid(self):
		#enableLeftHand()
		if throwableTween:
			throwableTween.kill()
		throwableTween = create_tween().bind_node(animationTree)
		var currentBlend: float = animationTree.get("parameters/leftThrowableBlend/blend_amount")
		throwableTween.tween_method(setThrowableBlendValue, currentBlend, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func setFallBlendValue(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/fallBlend/blend_amount", value)


func setRunBlendValue(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/runBlend/blend_amount", value)


func setIdleBlend(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/idleSpace/blend_position", value)


func setCoverBlend(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/coverBlend/blend_amount", value)


func setStaggerBlend(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/staggerBlend/blend_amount", value)


func setPhoneBlend(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/phoneOpened/blend_amount", value)


func setCoverMoveLBlend(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/coverMoveL/blend_position", value)


func setCoverMoveRBlend(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/coverMoveR/blend_position", value)


func setBodyIKInterpolation(value: float) -> void:
	if !isPawnDead and is_instance_valid(self):
		bodyIK.interpolation = value


func disableBodyIK() -> void:
	if !isPawnDead and is_instance_valid(self):
		if bodyIKTween:
			bodyIKTween.kill()
		bodyIKTween = create_tween().bind_node(animationTree)
		await bodyIKTween.tween_method(setBodyIKInterpolation, bodyIK.interpolation, 0, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
		bodyIK.stop()


func startBodyIK() -> void:
	if !isPawnDead and is_instance_valid(self):
		if bodyIKTween:
			bodyIKTween.kill()
		bodyIKTween = create_tween().bind_node(animationTree)
		bodyIK.start()
		bodyIKTween.tween_method(setBodyIKInterpolation, bodyIK.interpolation, 1, defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished


func checkMeshLookat() -> void:
	if !isPawnDead and is_instance_valid(self):
		if meshLookAt:
			startBodyIK()
			if !freeAim:
				if is_instance_valid(currentItem):
					if currentItem.isAiming != true:
						currentItem.isAiming = true
					else:
						if currentItem.isAiming != false:
							currentItem.isAiming = false

		else:
			disableBodyIK()

			if isInCover:
				enableCoverTransition()


func getShortTweenAngle(currentAngle: float, targetAngle: float) -> float:
	return currentAngle + wrapf(targetAngle - currentAngle, -PI, PI)


func isCurrentlyMoving() -> bool:
	return abs(direction.x) > 0 or abs(direction.z) > 0


func isOnGround() -> bool:
	return is_on_floor()


func setBulletTime(value: bool) -> void:
	if value:
		gameManager.enableBulletTime()
	else:
		gameManager.disableBulletTime()


func disableAllHitboxes() -> void:
	for hb in getAllHitboxes():
		hb.collision_layer = 0
		hb.collision_mask = 0
		hb.enabled = false


func deleteAllHitboxes():
	for hb in getAllHitboxes():
		hb.queue_free()


func toggleBulletTime() -> void:
	if gameManager.bulletTime:
		setBulletTime(false)
	else:
		if gameManager.canBulletTime:
			setBulletTime(true)


func enableCoverTransition() -> void:
	if coverTween:
		coverTween.kill()
	coverTween = create_tween()
	coverTween.tween_method(setCoverBlend, animationTree.get("parameters/coverBlend/blend_amount"), 1, 0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func disableCoverTransition() -> void:
	if coverTween:
		coverTween.kill()
	coverTween = create_tween()
	coverTween.tween_method(setCoverBlend, animationTree.get("parameters/coverBlend/blend_amount"), 0, 0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func playInteractAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/useType/transition_request", "interactL")
		animationTree.set("parameters/useShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func playUseAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/useType/transition_request", "useL")
		animationTree.set("parameters/useShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func playGrabAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		animationTree.set("parameters/useType/transition_request", "grabL")
		animationTree.set("parameters/useShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func stopRingtone() -> void:
	%ringtone.stop()


func playRingtone() -> void:
	if !%ringtone.playing:
		%ringtone.play()

	%ringtone.finished.connect(%ringtone.play)


func stopPhoneCall() -> void:
	if attachedCam:
		attachedCam.fadePhoneCallNotificationOut()
		attachedCam.clearSubtitles()
		if !isPawnDead:
			attachedCam.hud.fadeHudIn()
	gameManager.removeDialogue2D()
	stopRingtone()
	playingCall = false
	isUsingPhone = false


func endPhoneCall() -> void:
	if queuedPhoneCall and !isPawnDead and playingCall:
		if gameManager.bulletTime:
			gameManager.bulletTime = false
		gameManager.showHUD()
		queuedPhoneCall = null
		playPhoneHangupAnimation()
		await callFinished
		stopPhoneCall()


func playPhoneCall() -> void:
	if !isUsingPhone and queuedPhoneCall and isPlayerPawn() and !isPawnDead:
		if gameManager.bulletTime:
			gameManager.bulletTime = false
		gameManager.hideHUD()
		playingCall = true
		attachedCam.fadePhoneCallNotificationOut()
		isUsingPhone = true
		currentItemIndex = 0
		currentItem = null
		playPhoneAnswerAnimation()
		isUsingPhone = true
		await get_tree().create_timer(2.1, false).timeout
		var pcall = await gameManager.playDialogue2D(queuedPhoneCall)
		await pcall.tree_exited
		isUsingPhone = false
		gameManager.showHUD()
		playingCall = false
		queuedPhoneCall = null
		if attachedCam:
			attachedCam.hud.fadeHudIn()
		playPhoneHangupAnimation()


func playPhoneAnswerAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		if phoneTween:
			phoneTween.kill()
		phoneTween = create_tween()
		%flipphone.visible = true
		phoneTween.tween_method(setPhoneBlend, animationTree.get("parameters/phoneOpened/blend_amount"), 1, 0.05).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		animationTree.set("parameters/phoneAnimation/transition_request", "phoneAnswer")
		animationTree.set("parameters/phoneSeek/seek_request", 0.1)


func playPhoneOpenAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		if phoneTween:
			phoneTween.kill()
		phoneTween = create_tween()
		%flipphone.visible = true
		phoneTween.tween_method(setPhoneBlend, animationTree.get("parameters/phoneOpened/blend_amount"), 1, 0.05).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		animationTree.set("parameters/phoneAnimation/transition_request", "phoneOpen")
		animationTree.set("parameters/phoneSeek/seek_request", 0.1)


func playPhoneHangupAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		%flipphone.visible = true
		if phoneTween:
			phoneTween.kill()
		phoneTween = create_tween()
		animationTree.set("parameters/phoneAnimation/transition_request", "phoneHangup")
		animationTree.set("parameters/phoneSeek/seek_request", 0.1)
		await get_tree().create_timer(1.3, false).timeout
		%flipphone.visible = false
		#callFinished.emit()
		if phoneTween:
			phoneTween.kill()
		phoneTween = create_tween()
		phoneTween.tween_method(setPhoneBlend, animationTree.get("parameters/phoneOpened/blend_amount"), 0, 0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func playPhoneCloseAnimation() -> void:
	if !isPawnDead and is_instance_valid(self):
		%flipphone.visible = false
		if phoneTween:
			phoneTween.kill()
		phoneTween = create_tween()
		phoneTween.tween_method(setPhoneBlend, animationTree.get("parameters/phoneOpened/blend_amount"), 0, 0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func togglePhone() -> void:
	if isUsingPhone and !isPawnDead:
		closePhone()
	else:
		if isInCover:
			isInCover = false

		openPhone()


func showPhone() -> void:
	gameManager.initializePhoneMenu(self)


func deletePhone() -> void:
	gameManager.removePhoneMenu()


func openPhone() -> void:
	if isPlayerPawn() and !isPawnDead:
		currentItemIndex = 0
		currentItem = null
		playPhoneOpenAnimation()
		isUsingPhone = true
		#direction = Vector3.ZERO
		#velocity = Vector3.ZERO


func closePhone() -> void:
	if isPlayerPawn() and !isPawnDead:
		currentItem = null
		currentItemIndex = 0
		isUsingPhone = false


func toggleCover() -> void:
	if !isInCover and is_on_floor():
		#if %lowerCoverCast.get_collision_normal().y > 0:
			#return
		#var collisionPoint = %lowerCoverCast.get_collision_point()

		freeAim = false
		meshLookAt = false
		var tween = create_tween()

		## 0 = Crouching cover, 1 = standing cover
		var coverType = 0

		##If the player is at a knee-high cover, then crouch. Otherwise, stand
		coverNormal = %lowerCoverCast.get_collision_normal()
		if %lowerCoverCast.is_colliding() and !%topCoverCast.is_colliding():
			coverType = 0
		else:
			coverType = 1

		isInCover = true
		#print(get_wall_normal())
		var rot := atan2(coverNormal.x, coverNormal.y)
		pawnMesh.rotation.y = rot

		#velocity.move_toward(coverPosition,0.25)
		tween.parallel().tween_property(self, "global_position:x", coverPosition.x, 0.55).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		tween.parallel().tween_property(self, "global_position:z", coverPosition.z, 0.55).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	else:
		isInCover = false


func peekFromCover() -> void:
	if peekTween:
		peekTween.kill()
	peekTween = create_tween()
	if coverDirection == 0:
		preventWeaponFire = false
		peekTween.parallel().tween_property(self, "global_position:x", %rightPeekCast.get_collision_point().x, 0.4).set_trans(defaultTransitionType).set_ease(defaultEaseType)
		peekTween.parallel().tween_property(self, "global_position:z", %rightPeekCast.get_collision_point().z, 0.4).set_trans(defaultTransitionType).set_ease(defaultEaseType)
		#isPeeking = true
	else:
		preventWeaponFire = false
		peekTween.parallel().tween_property(self, "global_position:x", %leftPeekCast.get_collision_point().x, 0.4).set_trans(defaultTransitionType).set_ease(defaultEaseType)
		peekTween.parallel().tween_property(self, "global_position:z", %leftPeekCast.get_collision_point().z, 0.4).set_trans(defaultTransitionType).set_ease(defaultEaseType)
		#isPeeking = true


func unPeekFromCover() -> void:
	if peekTween:
		peekTween.kill()
	peekTween = create_tween()
	peekTween.parallel().tween_property(self, "global_position:x", peekPos.x, 0.4).set_trans(defaultTransitionType).set_ease(defaultEaseType)
	peekTween.parallel().tween_property(self, "global_position:z", peekPos.z, 0.4).set_trans(defaultTransitionType).set_ease(defaultEaseType)


func hideCoverLabel() -> void:
	if coverIndicatorTween:
		coverIndicatorTween.kill()
	coverIndicatorTween = create_tween()
	coverIndicatorTween.parallel().tween_property(%coverLabel, "outline_modulate", Color.TRANSPARENT, .15).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	coverIndicatorTween.parallel().tween_property(%coverLabel, "modulate", Color.TRANSPARENT, .15).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	coverIndicatorTween.parallel().tween_property(%coverLabel, "position:y", 0.5, 0.55).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func showCoverLabel() -> void:
	if coverIndicatorTween:
		coverIndicatorTween.kill()
	coverIndicatorTween = create_tween()
	#%coverLabel.position = Vector3.ZERO
	%coverLabel.show()
	coverIndicatorTween.parallel().tween_property(%coverLabel, "outline_modulate", Color.BLACK, 1.05).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	coverIndicatorTween.parallel().tween_property(%coverLabel, "modulate", Color.WHITE, 1.05).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	coverIndicatorTween.parallel().tween_property(%coverLabel, "position:y", 0.00, 0.35).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func disableFlashlight() -> void:
	isUsingFlashlight = false
	%flashlight.visible = false


func enableFlashlight() -> void:
	isUsingFlashlight = true
	%flashlight.visible = true


func toggleFlashlight() -> void:
	if !isUsingFlashlight:
		enableFlashlight()
	else:
		disableFlashlight()


func enableStaggerBlend() -> void:
	if staggerTween:
		staggerTween.kill()
	staggerTween = create_tween()
	staggerTween.tween_method(setStaggerBlend, animationTree.get("parameters/staggerBlend/blend_amount"), 1, 0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func disableStaggerBlend() -> void:
	if staggerTween:
		staggerTween.kill()
	staggerTween = create_tween()
	staggerTween.tween_method(setStaggerBlend, animationTree.get("parameters/staggerBlend/blend_amount"), 0, 0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func playPhoneCloseSound() -> void:
	if !%phoneClose.playing:
		%phoneClose.play()


func playPhoneOpenSound() -> void:
	if !%phoneOpen.playing:
		%phoneOpen.play()


func playPhoneBeepSound() -> void:
	%phoneBeep.play()


func setAdditiveAnimation()->void:
	var filterBlend2: AnimationNodeAnimation = animationTree.tree_root.get_node("additiveAnim")
	if animationPlayer.has_animation("weaponAnims/fire"):
		filterBlend2.animation = "weaponAnims/fire"
	else:
		filterBlend2.animation = "PawnAnim/Idle"


func staggerEnd() -> void:
	isStaggered = false


func doStagger(stagger, speed: float = 1.0, randomChance: bool = false, interruptible:bool=false) -> void:
	if get_meta(&"canBeStaggered") == false or isStaggered and !interruptible or forceAnimation: return
	if randomChance:
		if [true, false].pick_random() == false:
			return
	isStaggered = true
	#Upon Calling the stagger, it should trigger the animation and play it. Freezing the pawn
	#until it ends.

	#Set the transition to the stagger var alongside the seek and speed
	if stagger is String or stagger is StringName:
		animationTree.set("parameters/staggerTransition/transition_request", str(stagger))
	elif stagger is Array:
		var staggerToUse = stagger.pick_random()
		if staggerToUse is String or staggerToUse is StringName:
			animationTree.set("parameters/staggerTransition/transition_request", str(staggerToUse))
	animationTree.set("parameters/staggerScale/scale", speed)
	animationTree.set("parameters/staggerShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

		#process_mode = Node.PROCESS_MODE_DISABLED


func _on_health_component_health_depleted(dealer: BasePawn) -> void:
	if !isPawnDead and is_instance_valid(self):
		if is_instance_valid(dealer):
			die(dealer)
		else:
			die(null)


func _on_free_aim_timer_timeout() -> void:
	freeAim = false


func _on_footsteps_finished() -> void:
	footstepSounds.stop()

	#animationTree.set("parameters/flinchSpace/blend_position",Vector2(randf_range(-1,1),randf_range(-0.25,1)))
	#animationTree.set("parameters/flinchShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	##Old flinch
	#if !healthComponent.health <= 10 or !lastHitPart == 41:
		#if !meshLookAt:
			#bodyIK.start()
			#bodyIK.interpolation = 1
		#bodyIKMarker.rotation.x += randf_range(-0.1,0.35)
		#bodyIKMarker.rotation.z += randf_range(-0.25,0.35)
		#flinchTween.parallel().tween_property(bodyIKMarker,"rotation:x",0,1).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		#flinchTween.parallel().tween_property(bodyIKMarker,"rotation:z",0,1).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		##bodyIKMarker.rotation.y += randf_range(-0.5,0.5)
		#if !meshLookAt:
			#disableBodyIK()

func update_pawn_movement(delta:float)->void:
	if movementController.enabled:
		movementController.update(delta)

func _on_health_component_on_damaged(dealer: Node3D, hitDirection: Vector3) -> void:
	if is_instance_valid(self) and !isPawnDead:
		flinch(hitDirection)
