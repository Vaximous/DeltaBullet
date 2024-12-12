extends CharacterBody3D
class_name BasePawn

##Signals
signal meshLookAtChanged(value:bool)
signal setDirection(direction:Vector3)
signal setMovementState(state:MovementState)
signal weaponFireChanged
signal freeAimChanged
signal directionChanged
signal controllerAssigned
signal clothingChanged
signal itemChanged
signal forcingAnimation
signal killedPawn
signal onPawnKilled
signal hitboxAssigned(hitbox:Hitbox)
signal headshottedPawn

#Sounds
@onready var soundHolder : Node3D = $Sounds
@onready var equipSound : AudioStreamPlayer3D = $Sounds/equipSound
@onready var footstepSounds : AudioStreamPlayer3D = $Sounds/footsteps
##Onready
@onready var onScreenNotifier : VisibleOnScreenNotifier3D = $Mesh/visibleOnScreenNotifier3d
@onready var footstepMaterialChecker : RayCast3D = $Misc/footstepMaterialChecker
@onready var componentHolder : Node3D = $Components
@onready var boneAttatchementHolder : Node = $BoneAttatchments
@onready var interactRaycast : RayCast3D = $Mesh/interactRaycast

##IK
@onready var bodyIK : SkeletonIK3D= $Mesh/MaleSkeleton/Skeleton3D/bodyIK
@onready var bodyIKMarker : Marker3D = $Mesh/bodyIKMarker:
	set(value):
		bodyIKMarker = value
		defaultBodyIKMarkerPosition = bodyIKMarker.position
@onready var rightHandBone : BoneAttachment3D = $BoneAttatchments/rightHand
@onready var leftHandBone : BoneAttachment3D = $BoneAttatchments/leftHand
@onready var neckBone : BoneAttachment3D = $BoneAttatchments/Neck
@onready var upperChestBone  : BoneAttachment3D= $BoneAttatchments/UpperChest
@onready var chestBone : BoneAttachment3D = $BoneAttatchments/Stomach
@onready var hipBone : BoneAttachment3D = $BoneAttatchments/Hips
@onready var stomachBone : BoneAttachment3D = $BoneAttatchments/Stomach
@onready var rightThighBone : BoneAttachment3D = $BoneAttatchments/RightThigh
@onready var leftThighBone : BoneAttachment3D = $BoneAttatchments/LeftThigh

##Pawn Parts
@onready var headHitbox : Hitbox = $BoneAttatchments/Neck/Hitbox
@onready var head : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/MaleHead
@onready var upperChest : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_UpperBody
@onready var shoulders : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_Shoulders
@onready var leftUpperArm : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_LeftArm
@onready var rightUpperArm : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_RightArm
@onready var leftForearm : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_LeftForearm
@onready var rightForearm : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_RightForearm
@onready var lowerBody : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_LowerBody
@onready var leftUpperLeg : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_LeftThigh
@onready var rightUpperLeg  : MeshInstance3D= $Mesh/MaleSkeleton/Skeleton3D/Male_RightThigh
@onready var leftLowerLeg : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_LeftKnee
@onready var rightLowerLeg : MeshInstance3D = $Mesh/MaleSkeleton/Skeleton3D/Male_RightKnee
@onready var aimBlockRaycast : RayCast3D = $Mesh/aimDetect
@onready var floorcheck : RayCast3D = $floorCast
@onready var freeAimTimer : Timer = $freeAimTimer
@onready var pawnSkeleton : Skeleton3D = $Mesh/MaleSkeleton/Skeleton3D
@onready var animationTree : AnimationTree = $AnimationTree:
	set(value):
		animationTree = value
		setupAnimationTree()
@onready var collisionShape : CollisionShape3D = $Collider
@onready var clothingHolder : Node3D = $Mesh/MaleSkeleton/Skeleton3D/Clothing
@onready var pawnMesh : Node3D = $Mesh
@onready var itemHolder : Node3D = $BoneAttatchments/rightHand/Weapons
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
##Internal Variables

var direction : Vector3 = Vector3.ZERO:
	set(value):
		if direction != value and is_instance_valid(self):
			direction = value
			#print(direction)
			directionChanged.emit()
			setDirection.emit(direction)
		if value != Vector3.ZERO and is_instance_valid(self):
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
			if isCrouching:
				setMovementState.emit(movementStates["crouch"])
			else:
				setMovementState.emit(movementStates["standing"])
			isMoving = false
		#if direction != Vector3.ZERO:
			#doMeshRotation()
var meshRotation : float = 0.0:
	set(value):
		if value != meshRotation and !isPawnDead and is_instance_valid(self):
			meshRotation = value
			#doMeshRotation()
##Component Setup
@export_category("Pawn")
var defaultPawnMaterial : StandardMaterial3D = load("res://assets/materials/pawnMaterial/MALE.tres")
var currentPawnMat : StandardMaterial3D
@export var pawnColor : Color = Color(1.0,0.76,0.00,1.0):
	set(value):
		pawnColor = value
		setupPawnColor()
var raycaster : RayCast3D
#Base Components - Components required for this entity to even be used
@export_subgroup("Base Components")
@export var animationController : Node
@export var movementController : Node
@export var healthComponent : HealthComponent
@export_subgroup("Sub-Components")
@export var inputComponent : Node:
	set(value):
		inputComponent = value
		if value == InputComponent:
			emit_signal("controllerAssigned")
	get:
		return inputComponent

##Variables
@export_subgroup("Camera Behavior")
##Root Follow Node
@export var rootCameraNode : Node3D
##Camera Data for a camera to follow
@export var pawnCameraData : CameraData
##If a camera were to be attached to this node, it would follow this.
@export var followNode : Node3D
##The current attached camera (if there is one)
signal cameraAttached
@export var attachedCam : PlayerCamera:
	set(value):
		attachedCam = value
		emit_signal("cameraAttached")
		#attachedCam.cameraRotationUpdated.connect(doMeshRotation.bind(get_physics_process_delta_time()))
	get:
		return attachedCam
@export_subgroup("Behavior")
@export var isCrouching : bool = false:
	set(value):
		isCrouching = value
		var crouchSpeed = 0.35
		if crouchSpaceTween:
			crouchSpaceTween.kill()
		crouchSpaceTween = create_tween()
		if value:
			crouchSpaceTween.parallel().tween_property(animationTree,"parameters/crouchBlend/blend_amount",1,crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
			crouchSpaceTween.parallel().tween_property(animationTree,"parameters/crouchStrafeBlend/blend_amount",1,crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		else:
			crouchSpaceTween.parallel().tween_property(animationTree,"parameters/crouchBlend/blend_amount",0,crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
			crouchSpaceTween.parallel().tween_property(animationTree,"parameters/crouchStrafeBlend/blend_amount",0,crouchSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
@export var fallDamageEnabled : bool = true
@export var forceAnimation : bool = false:
	set(value):
		emit_signal("forcingAnimation")
		forceAnimation = value
		if value == false:
			if animationTree:
				animationTree.active = false
		else:
			if animationTree:
				animationTree.active = true
@export var animationToForce : String = "":
	set(value):
		animationToForce = value
		if forceAnimation:
			if animationPlayer != null:
				if !animationPlayer.is_playing():
					animationPlayer.play(animationToForce)
##Allows the pawn to interact with the environment, move and have physics applied, etc..
@export var freeAim : bool = false:
	set(value):
		if freeAim != value:
			freeAim = value
			if freeAim:
				meshLookAt = true
			else:
				meshLookAt = false
			freeAimChanged.emit()
			#print(freeAim)
@export var pawnEnabled : bool = true
@export var animationPlayerSpeed : float = 1.0:
	set(value):
		animationPlayerSpeed = value
		if animationPlayer !=null:
			animationPlayer.speed_scale = value
@export var collisionEnabled : bool = true:
	set(value):
		collisionEnabled = value
	get:
		return collisionEnabled

@export_subgroup("Variables")
signal pawnDied(pawnRagdoll:PawnRagdoll)
@export var turnAmount : float
@export var turnSpeed : float = 18.0
var preventWeaponFire : bool = false:
	set(value):
		if preventWeaponFire != value:
			preventWeaponFire = value
			weaponFireChanged.emit()
@export var isPawnDead : bool = false:
	set(value):
		isPawnDead = value
	get:
		return isPawnDead
@export var isMoving : bool = false:
	set(value):
		if is_instance_valid(self):
			isMoving = value
			if !isMoving:
	#			disableIdleSpaceBlend()
	#			disableRunBlend()
				if footstepSounds != null:
					if footstepSounds.playing:
						footstepSounds.stop()
@export_subgroup("Movement")
@export var diveForce : float = 6.5
var diveDirection : Vector3
@export var isDiving : bool = false:
	set(value):
		isDiving = value
		if value:
			diveDirection = direction
			direction = Vector3.ZERO
			velocity += diveDirection * diveForce
			velocity.y += diveForce
			animationTree.set("parameters/dive_transition/transition_request", "diving")
			canRun = false
			isRunning = false
			isCrouching = false
			meshLookAt = true
			canJump = false


@export var movementStates : Dictionary
@export var canRun : bool = true:
	set(value):
		if value:
			if !isDiving:
				canRun = value
			else:
				canRun = false

@export var isRunning : bool = false:
	set(value):
		isRunning = value
@export var JUMP_VELOCITY : float = 4.5
@export var defaultWalkSpeed : float = 3.0
@export var defaultRunSpeed : float = 6.0
@export var canJump : bool = true
@export var isJumping : bool = false
var isGrounded : bool = true
@export_subgroup("Throwables")
var throwableItem : Node
var throwableAmount : int = 0
var isArmingThrowable : bool = false:
	set(value):
		isArmingThrowable = value
		if isArmingThrowable:
			enableThrowableAnim()
		else:
			disableThrowableAnim()
var canThrowThrowable : bool = true
var isThrowing : bool = false
@export_subgroup("Inventory")
var pawnCash : int = 0
var itemNames : Array
@export var itemInventory : Array
var currentItem : InteractiveObject = null
@export var currentItemIndex : int = 0:
	set(value):
		currentItemIndex = clamp(value, 0, itemInventory.size()-1)
		currentItem = itemInventory[currentItemIndex]
		if !currentItem == null:
			emit_signal("itemChanged")
			currentItem.isAiming = false
			equipWeapon(currentItemIndex)
			currentItem.isAiming = false
			currentItem.weaponOwner = self
			enableRightHand()
			checkMeshLookat()
			if currentItem.weaponResource != null:
				await get_tree().process_frame
				if currentItem.weaponResource.leftHandParent:
					itemHolder.reparent(leftHandBone)
					itemHolder.position = Vector3.ZERO
				if currentItem.weaponResource.rightHandParent:
					itemHolder.reparent(rightHandBone)
					itemHolder.position = Vector3.ZERO

			if attachedCam:
				currentItem.weaponCast = attachedCam.camCast
				if currentItem.weaponResource.useCustomCrosshairSize:
					attachedCam.hud.getCrosshair().crosshairSize = currentItem.weaponResource.crosshairSizeOverride
				else:
					attachedCam.hud.getCrosshair().crosshairSize = attachedCam.hud.getCrosshair().defaultCrosshairSize
				if !UserConfig.game_simple_crosshairs:
					if currentItem.weaponResource.forcedCrosshair != null:
						attachedCam.hud.getCrosshair().setCrosshair(currentItem.weaponResource.forcedCrosshair)
					else:
						attachedCam.hud.getCrosshair().setCrosshair(attachedCam.hud.getCrosshair().defaultCrosshair)
				attachedCam.itemEquipOffsetToggle = true
				#Dialogic.VAR.set('playerHasWeaponEquipped',true)
				#attachedCam.resetCamCast()
		else:
			disableRightHand()
			disableLeftHand()
			checkMeshLookat()
			for weapon in itemHolder.get_children():
				if weapon.isEquipped != false:
						weapon.isEquipped = false
				weapon.hide()
			if attachedCam:
				#Dialogic.VAR.set('playerHasWeaponEquipped',false)
				attachedCam.itemEquipOffsetToggle = false
				attachedCam.hud.getCrosshair().setCrosshair(null)
				#attachedCam.resetCamCast()
@export var purchasedClothing : Array

@export var clothingInventory : Array:
	set(value):
		clothingInventory = value
		emit_signal("clothingChanged")

@export_subgroup("Mesh")
##Ragdoll to spawn when the pawn dies
@export var ragdollScene : PackedScene
##Makes the mesh look at a certain thing, mainly used for aiming
@export var meshLookAt : bool = false:
	set(value):
		meshLookAt = value
		meshLookAtChanged.emit(value)
		if value == true:
			startBodyIK()
		else:
			disableBodyIK()
		#if meshLookAt != value:
			#checkWeaponBlend()

@export var lastHitPart : int:
	set(value):
		lastHitPart = value

@export var hitImpulse : Vector3 = Vector3.ZERO:
	set(value):
		hitImpulse = value

@export var hitVector : Vector3 = Vector3.ZERO
@export_subgroup("Misc")
const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var throwableTween : Tween
var leftHandTween : Tween
var rightHandTween : Tween
var runTween : Tween
var fallTween : Tween
var idleSpaceTween : Tween
var crouchSpaceTween : Tween
var bodyIKTween : Tween
var meshRotationTween : Tween
var meshRotationTweenMovement : Tween
var flinchTween : Tween
var lastLeftBlend : AnimationNodeStateMachinePlayback
## First-person, just for shits and giggles
var isFirstperson : bool = false:
	set(value):
		isFirstperson = value
		meshLookAt = value
		freeAim = value
var hitboxes : Array[Hitbox]
var defaultBodyIKMarkerPosition : Vector3
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	itemInventory.append(null)
	setMovementState.emit(movementStates["standing"])
	checkComponents()
	checkClothes()
	checkItems()
	if collisionEnabled:
		collisionShape.disabled = false
	else:
		collisionShape.disabled = false

	if forceAnimation:
		animationTree.active = false
		animationPlayer.play(animationToForce)

	fixRot()
	setupPawnColor()
	setupAnimationTree()
	if !gameManager.getEventSignal("playerDied").is_connected(gameManager.doDeathEffect):
		gameManager.getEventSignal("playerDied").connect(gameManager.doDeathEffect)
	#getAllHitboxes()

func _physics_process(delta:float) -> void:
	if pawnEnabled:
		if !isPawnDead and is_instance_valid(self):
			do_stairs(delta)
			if isCurrentlyMoving():
				setDirection.emit(direction)

			if fallDamageEnabled:
				if floorcheck.is_colliding():
					if velocity.y <= -15:
						die(null)

			preventWeaponFire = aimBlockRaycast.is_colliding()

			if isDiving and !isOnGround():
				freeAim = true
			elif isDiving and isOnGround():
				animationTree.set("parameters/dive_transition/transition_request", "not_diving")
				isDiving = false


##Checks to see if any required components (Base components) Are null
func checkComponents():
	if inputComponent:
		if inputComponent is AIComponent:
			inputComponent.pawnOwner = self
			await get_tree().process_frame
			inputComponent.aimCast.add_exception(self)
			for hitbox in getAllHitboxes():
				inputComponent.aimCast.add_exception(hitbox)
			raycaster = inputComponent.aimCast
			#healthComponent.connect("onDamaged",inputComponent.instantDetect.bind())
			#inputComponent.position = self.position

		if inputComponent is Component:
			inputComponent.controllingPawn = self
			if gameManager.activeCamera == null:
				gameManager.playerPawns.append(self)
				var cam = load("res://assets/entities/camera/camera.tscn")
				var _cam = cam.instantiate()
				_cam.global_position = self.global_position
				await get_tree().process_frame
				gameManager.world.worldMisc.add_child(_cam)
				_cam.posessObject(self, followNode)
				_cam.camCast.add_exception(self)
				_cam.interactCast.add_exception(self)
				headHitbox.hitboxDamageMult = 1.3
				raycaster = _cam.camCast
				add_to_group("Player")

	if healthComponent == null:
		return null

func endPawn()->void:
	direction = Vector3.ZERO
	velocity = Vector3.ZERO
	removeComponents()
	dropWeapon()
	if currentItem:
		currentItem.weaponOwner = null
	currentItemIndex = 0
	currentItem = null
	pawnEnabled = false
	collisionEnabled = false
	animationPlayer.queue_free()
	animationController.queue_free()
	footstepSounds.queue_free()


func endAttachedCam()->void:
	if attachedCam != null:
		if gameManager.bulletTime:
			gameManager.bulletTime = false
		attachedCam.hud.flashColor(Color.DARK_RED)
		attachedCam.stopCameraRecoil()
		attachedCam.cameraRotationUpdated.disconnect(doMeshRotation)
		gameManager.getEventSignal("playerDied").emit()
		attachedCam.lowHP = false
		attachedCam.hud.hudEnabled = false
		attachedCam.resetCamCast()
		#Dialogic.end_timeline()


func doKillEffect(deathDealer)->void:
	if deathDealer != null and !deathDealer.isPawnDead and is_instance_valid(deathDealer):
		if deathDealer.currentItem != null:
			if deathDealer.currentItem.weaponResource.headDismember:
				healthComponent.killedWithDismemberingWeapon.emit()
		if !healthComponent.killerSignalEmitted:
			if healthComponent.componentOwner is BasePawn:
				deathDealer.killedPawn.emit()
				healthComponent.killerSignalEmitted = true

func moveHitboxDecals(parent:Node3D = gameManager.world.worldParticles) ->void:
	if gameManager.world != null:
		for boxes in getAllHitboxes():
			for decals in boxes.get_children():
				if decals is BulletHole:
					decals.reparent(parent)


func die(killer) -> void:
	if is_instance_valid(self) and !isPawnDead:
		isPawnDead = true
		killAllTweens()
		createRagdoll(lastHitPart, killer)
		pawnEnabled = false
		moveHitboxDecals()
		animationTree.set("parameters/standToCrouchAdd/add_amount", 0)
		animationTree.set("parameters/standToCrouchStrafe/add_amount", 0)
		doKillEffect(killer)
		#moveDecalsToRagdoll(ragdoll)
		endPawn()
		deleteAllHitboxes()
		onPawnKilled.emit()
		#killedPawn.emit()
		queue_free()



func do_stairs(delta) -> void:
	#Does staircase stuff
	const step_check_distance : float = 0.5
	const step_height_max : float = 1.0
	const step_depth_min : float = 0.15

	var input_direction : Vector2 = Vector2(direction.x, direction.z)
	if !is_on_floor() or input_direction.length() <= 0.1:
		return
	#Check multiple directions
	var cam = gameManager.activeCamera
	if cam == null:
		return
	var flat_vel = (velocity * Vector3(1.0, 0.0, 1.0)).normalized()
	var check_directions : Array[Vector3] = [
		flat_vel,
		flat_vel.rotated(Vector3.UP, PI/3),
		flat_vel.rotated(Vector3.UP, -PI/3),
		]
	#if gameManager.debugEnabled:
		#print(input_direction)
		#print(flat_vel)
	for direction in check_directions:
		var step_ray_dir := direction * step_check_distance
		#if step_ray_dir.dot(Vector3(velocity.x, 0, velocity.z).normalized()) < 0.5:
			#continue
		var direct_state = get_world_3d().direct_space_state
		var obs_ray_info : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		obs_ray_info.exclude = [RID(self)]
		obs_ray_info.from = global_position
		obs_ray_info.to = obs_ray_info.from + step_ray_dir
		#First check : Is a flat wall found?
		var first_collision = direct_state.intersect_ray(obs_ray_info)
		#print("Ray from %s to %s" % [obs_ray_info.from, obs_ray_info.to])
		if !first_collision.is_empty():
			#if gameManager.debugEnabled:
				#print("Ray hit something.")
			if not first_collision["collider"] is StaticBody3D and not first_collision["collider"] is CSGShape3D:
				continue
			if first_collision["normal"].angle_to(Vector3.UP) < 1.39626:
				var remain_length = step_check_distance - first_collision["position"].distance_to(obs_ray_info.from)
				obs_ray_info.from = first_collision["position"]
				obs_ray_info.to = obs_ray_info.from + (remain_length * step_ray_dir.slide(first_collision["normal"]))
				obs_ray_info.to.y += 0.05
				first_collision = direct_state.intersect_ray(obs_ray_info)
				if first_collision.is_empty():
					return
				if first_collision["normal"].angle_to(Vector3.UP) < 1.39626:
					return
			#if gameManager.debugEnabled:
				#print("Ready to climb up step.")
			#From that first collision point, we now check if 'min_stair_depth' is met
			#at the the 'max_step_height'
			var depth_check : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
			depth_check.exclude = obs_ray_info.exclude
			depth_check.from = global_position + Vector3(0, step_height_max, 0)
			depth_check.to = depth_check.from + (step_ray_dir * (step_depth_min + global_position.distance_to(first_collision.position)))
			if !direct_state.intersect_ray(depth_check).is_empty():
				continue
			#The step is deep enough.
			#Last we need to find the top of the step so we can stand on it.
			#Inch the initial collision up by step_max and forward a tiny bit.
			#The to-position is just the initial position minus the step_max.
			var top_check : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
			top_check.exclude = obs_ray_info.exclude
			top_check.from = first_collision.position + Vector3(step_ray_dir.x, step_height_max, step_ray_dir.z)
			top_check.to = top_check.from - Vector3(0, step_height_max, 0)
			var stair_top_collision = direct_state.intersect_ray(top_check)
			if !stair_top_collision.is_empty():
					#move player up above step
					var pre_position = global_position
					position.y += stair_top_collision.position.y - obs_ray_info.from.y
					#move player forward onto step
					position += (step_ray_dir * (step_check_distance * 0.5))
					#interpolate_visual_position(pre_position - global_position)
					return
			#if gameManager.debugEnabled:
				#print("Couldn't climb up the step.")


func _on_health_component_health_depleted(dealer:BasePawn) -> void:
	await get_tree().process_frame
	if !isPawnDead and is_instance_valid(self):
		if is_instance_valid(dealer):
			die(dealer)
		else:
			die(null)


func applyRagdollImpulse(ragdoll:PawnRagdoll,currentVelocity:Vector3,impulseBone:int = 0)->void:
	for bones in ragdoll.physicalBoneSimulator.get_children():
		if bones is RagdollBone:
			bones.linear_velocity = currentVelocity
			bones.angular_velocity = currentVelocity
			bones.apply_central_impulse(currentVelocity)
			if bones.get_bone_id() == impulseBone:
				#ragdoll.startRagdoll()
				bones.apply_central_impulse(hitImpulse * randf_range(1.5,2))

func setRagdollPose(ragdoll:PawnRagdoll)->void:
	for bones in ragdoll.ragdollSkeleton.get_bone_count():
		ragdoll.ragdollSkeleton.set_bone_global_pose(bones, pawnSkeleton.get_bone_global_pose(bones))

func setRagdollPositionAndRotation(ragdoll:PawnRagdoll)->void:
	ragdoll.global_transform = pawnMesh.global_transform
	ragdoll.rotation = pawnMesh.rotation
	ragdoll.targetSkeleton = pawnSkeleton

func createRagdoll(impulse_bone : int = 0,killer = null)->PawnRagdoll:
	var currVel = velocity
	var ragdoll = ragdollScene.instantiate()
	collisionEnabled = false
	self.hide()
	gameManager.world.worldMisc.add_child(ragdoll)
	setRagdollPositionAndRotation(ragdoll)
	moveClothesToRagdoll(ragdoll)
	ragdoll.setPawnMaterial(currentPawnMat)
	setRagdollPose(ragdoll)
	ragdoll.startRagdoll()


	applyRagdollImpulse(ragdoll,currVel,impulse_bone)


	pawnDied.emit(ragdoll)
	ragdoll.checkClothingHider()
	#ragdoll.startRagdoll()


	for bones in ragdoll.physicalBoneSimulator.get_child_count():
		var child = ragdoll.physicalBoneSimulator.get_child(bones)
		if child is RagdollBone:
			if child.get_bone_id() == impulse_bone:
				child.canBleed = true
				if child.healthComponent and killer != null and killer.currentItem != null:
					child.healthComponent.damage(killer.currentItem.weaponResource.weaponDamage * randf_range(1.5,2),killer)


	if impulse_bone == 41:
		if killer != null:
			if killer.currentItem != null:
				if killer.currentItem.weaponResource.headDismember:
					ragdoll.doRagdollHeadshot()
			if killer.attachedCam != null:
				killer.attachedCam.doHeadshotEffect()
		headshottedPawn.emit()


	if !attachedCam == null:
		var cam = attachedCam
		cam.unposessObject()
		cam.posessObject(ragdoll, ragdoll.rootCameraNode)
		ragdoll.removeTimer.stop()
		for bones in ragdoll.physicalBoneSimulator.get_child_count():
			if ragdoll.physicalBoneSimulator.get_child(bones) is RagdollBone:
				cam.camSpring.add_excluded_object(ragdoll.physicalBoneSimulator.get_child(bones).get_rid())
		endAttachedCam()
		attachedCam = null


	if ragdoll.activeRagdollEnabled:
		if impulse_bone == 41:
			ragdoll.activeRagdollEnabled = false
		forceAnimation = true
		animationToForce = "PawnAnim/WritheRightKneeBack"


	if collisionShape != null:
		collisionShape.queue_free()

	return ragdoll

func checkItems()->void:
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

func checkClothes()->void:
	setBodyVisibility(true)
	clothingInventory.clear()
	for clothes in clothingHolder.get_children():
		if !clothingInventory.has(clothes):
			clothingInventory.append(clothes)
			clothes.itemSkeleton = pawnSkeleton.get_path()
			clothes.remapSkeleton()
	checkClothingHider()

func moveClothesToRagdoll(moveto:Node3D) -> void:
	for clothes in clothingHolder.get_children():
		clothes.itemSkeleton = moveto.ragdollSkeleton.get_path()
		clothes.reparent(moveto)
		clothes.remapSkeleton()
	return

func setBodyVisibility(value:bool):
	if value:
		head.show()
		rightUpperArm.show()
		leftUpperArm.show()
		shoulders.show()
		leftForearm.show()
		rightForearm.show()
		upperChest.show()
		lowerBody.show()
		leftUpperLeg.show()
		rightUpperLeg.show()
		rightLowerLeg.show()
		leftLowerLeg.show()
	else:
		head.hide()
		rightUpperArm.hide()
		leftUpperArm.hide()
		shoulders.hide()
		leftForearm.hide()
		rightForearm.hide()
		upperChest.hide()
		lowerBody.hide()
		leftUpperLeg.hide()
		rightUpperLeg.hide()
		rightLowerLeg.hide()
		leftLowerLeg.hide()

func checkClothingHider() -> void:
	setBodyVisibility(true)
	for clothes in clothingHolder.get_children():
		if clothes is ClothingItem:
			if clothes.head:
				head.hide()
			if clothes.rightUpperarm:
				rightUpperArm.hide()
			if clothes.leftUpperarm:
				leftUpperArm.hide()
			if clothes.shoulders:
				shoulders.hide()
			if clothes.leftForearm:
				leftForearm.hide()
			if clothes.rightForearm:
				rightForearm.hide()
			if clothes.upperChest:
				upperChest.hide()
			if clothes.lowerBody:
				lowerBody.hide()
			if clothes.leftUpperLeg:
				leftUpperLeg.hide()
			if clothes.rightUpperLeg:
				rightUpperLeg.hide()
			if clothes.rightLowerLeg:
				rightLowerLeg.hide()
			if clothes.leftLowerLeg:
				leftLowerLeg.hide()

func moveDecalsToRagdoll(ragdoll:PawnRagdoll)->bool:
	#Decal reparent..
	for hboxes in getAllHitboxes():
		for decals in hboxes.get_children():
			if decals is BulletHole:
				await get_tree().process_frame
				for bone in ragdoll.ragdollSkeleton.get_children():
					if bone is PhysicalBone3D:
						if bone.get_bone_id() == hboxes.boneId:
							decals.reparent(bone,true)
							#print(decals.get_parent())
							#Console.add_console_message("For %s, %s" %[self,getCurrentDecalBones()])
	return true

func getAllHitboxes() -> Array[Hitbox]:
	return hitboxes


func killAllTweens()->void:
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


func jump() -> void:
	playFootstepAudio()
	if !isJumping:
		isJumping = true
		canJump = false
		if is_on_floor():
			isJumping = false
	velocity.y = JUMP_VELOCITY

func setupWeaponAnimations() -> void:
	var blendSet
	if !currentItem == null:
		blendSet = currentItem.animationTree.tree_root
		if !currentItem.weaponAnimSet:
			#Swap out animationLibraries
			if animationPlayer != null:
				animationPlayer.remove_animation_library("weaponAnims")
				if currentItem.animationPlayer != null:
					var libraryToAdd = currentItem.animationPlayer.get_animation_library("weaponAnims").duplicate()
					animationPlayer.add_animation_library("weaponAnims", libraryToAdd)

			#Add the weapons stateMachine to the player
			(animationTree.tree_root as AnimationNodeBlendTree).disconnect_node("weaponBlend", 1)
			animationTree.tree_root.remove_node("weaponState")
			animationTree.tree_root.add_node("weaponState", blendSet)
			(animationTree.tree_root as AnimationNodeBlendTree).connect_node("weaponBlend", 1, "weaponState")
			currentItem.weaponRemoteState = animationTree.get("parameters/weaponState/weaponState/playback")
			##Left Hand
			(animationTree.tree_root as AnimationNodeBlendTree).disconnect_node("weaponBlend_Left_blend", 1)
			animationTree.tree_root.remove_node("weaponBlend_left")
			animationTree.tree_root.add_node("weaponBlend_left", blendSet)
			(animationTree.tree_root as AnimationNodeBlendTree).connect_node("weaponBlend_Left_blend", 1, "weaponBlend_left")
			currentItem.weaponRemoteStateLeft = animationTree.get("parameters/weaponBlend_left/weaponState/playback")
			lastLeftBlend = currentItem.weaponRemoteStateLeft
			currentItem.weaponAnimSet = true
			return
	else:
		print_rich("[color=red]You don't have a weapon![/color]")
		return

func setLeftHandFilter(value : bool = true) -> void:
	var filterBlend = animationTree.tree_root.get_node("weaponBlend_Left_blend")
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

func setRightHandFilter(value : bool = true) -> void:
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

func equipWeapon(index:int) -> void:
	await unequipWeapon()
	if !equipSound.playing:
		equipSound.play()
	currentItem = itemInventory[index]
	freeAimChanged.connect(currentItem.checkFreeAim)
	#weaponFireChanged.connect(checkWeaponBlend)
	currentItem.weaponOwner = self
	currentItem.isEquipped = true
	currentItem.visible = true
	await setupWeaponAnimations()

func unequipWeapon() -> void:
	animationTree.set("parameters/weaponBlend/blend_amount", 0)
	animationTree.set("parameters/weaponBlend_Left_blend/blend_amount", 0)
	if lastLeftBlend != null:
		lastLeftBlend.stop()
	for weapon in itemHolder.get_children():
		weapon.hide()
		weapon.resetToDefault()
	if currentItem:
		if freeAimChanged.is_connected(currentItem.checkFreeAim):
			freeAimChanged.disconnect(currentItem.checkFreeAim)
		if weaponFireChanged.is_connected(currentItem.checkWeaponBlend):
			weaponFireChanged.disconnect(currentItem.checkWeaponBlend)
		currentItem.resetToDefault()
		currentItem.weaponAnimSet = false
		currentItem.isEquipped = false
		currentItem.isAiming = false
		currentItem.hide()
		currentItem = null

func _on_free_aim_timer_timeout() -> void:
	freeAim = false

func removeComponents() -> void:
	if inputComponent:
		inputComponent.queue_free()
		inputComponent = null

func checkFootstepMateral() -> void:
	if footstepMaterialChecker.is_colliding():
		return

func playFootstepAudio(soundprofile : AudioStream = null) -> void:
	if !footstepSounds == null:
		if is_on_floor() and isMoving:
			if !soundprofile == null:
				footstepSounds.stream = soundprofile

			if !footstepSounds.playing:
				footstepSounds.play()

func _on_footsteps_finished() -> void:
	footstepSounds.stop()

func dropWeapon() -> void:
	if !isPawnDead:
		animationTree.set("parameters/weaponBlend/blend_amount", 0)
	if currentItem:
		currentItem.resetToDefault()
		currentItem.collisionEnabled = true
		currentItem.weaponAnimSet = false
		currentItem.isEquipped = false
		currentItem.show()
		currentItem.setInteractable()
		currentItem.apply_impulse(velocity)
		currentItem = null

func setFirstperson() -> void:
	isFirstperson = true
	rootCameraNode = $BoneAttatchments/Neck
	pawnCameraData = load("res://assets/resources/pawnRelated/pawnFPSCam.tres")
	attachedCam.posessObject(self,rootCameraNode)
	head.hide()
	upperChest.hide()

func setThirdperson() -> void:
	if freeAim and isFirstperson:
		freeAim = false
		isFirstperson = false
	isFirstperson = false
	rootCameraNode = $BoneAttatchments/UpperChest
	pawnCameraData = load("res://assets/resources/pawnRelated/pawnDefaultCamData.tres")
	attachedCam.posessObject(self,rootCameraNode)
	head.show()
	upperChest.show()
	checkClothes()

func fixRot() -> void:
	pawnMesh.rotation = self.rotation
	self.rotation = Vector3.ZERO

func playAnimation(animation:String) -> void:
	if !forceAnimation:
		forceAnimation = true
	animationPlayer.play(animation)

func getInteractionObject():
	if interactRaycast.is_colliding():
		var col = interactRaycast.get_collider()
		if col != null:
			if col.is_in_group("Interactable"):
				gameManager.getEventSignal("interactableFound").emit()
				return col

func getClothes():
	for clothes in clothingHolder.get_children():
		return clothes

func moveItemToWeapons(item:Weapon) -> void:
	item.reparent(itemHolder)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	checkItems()

func setPawnMaterial() -> void:
	currentPawnMat.albedo_color = pawnColor
	if pawnSkeleton != null:
		for mesh in pawnSkeleton.get_children():
			if mesh is MeshInstance3D:
				mesh.set_surface_override_material(0,currentPawnMat)

func setupPawnColor() -> void:
	if pawnColor != Color(1.0,0.76,0.00,1.0):
		if !currentPawnMat:
			currentPawnMat = defaultPawnMaterial.duplicate()
			setPawnMaterial()

func setupAnimationTree() -> void:
	if animationTree:
		var dupRoot = animationTree.tree_root.duplicate()
		animationTree.tree_root = dupRoot

func setRunBlendFilters(value:bool) -> void:
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
					meshRotationTween.tween_property(pawnMesh,"rotation:y",getShortTweenAngle(pawnMesh.rotation.y,atan2(-direction.x,-direction.z)),0.25)
		else:
			canJump = false
			bodyIKMarker.rotation.x = turnAmount
			#bodyIKMarker.rotation_degrees.y = lerpf(bodyIKMarker.rotation_degrees.y, to_local(Vector3(0,180,0)).y, 16*delta)
			meshRotationTweenMovement.tween_property(bodyIKMarker,"rotation:z",getShortTweenAngle(bodyIKMarker.rotation.z,0.0),0.05)
			meshRotationTween.tween_property(pawnMesh,"rotation:y",getShortTweenAngle(pawnMesh.rotation.y,meshRotation),0.02)
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

func flinch() -> void:
	animationTree.set("parameters/flinchSpace/blend_position",Vector2(randf_range(-1,1),randf_range(-0.25,1)))
	animationTree.set("parameters/flinchShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	##Old flinch
	#if flinchTween:
		#flinchTween.kill()
	#flinchTween = create_tween()
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

func _on_health_component_on_damaged(dealer:Node3D, hitDirection:Vector3)->void:
	if is_instance_valid(self) and !isPawnDead:
		flinch()

func armThrowable()->void:
	if canThrowThrowable and !isArmingThrowable and throwableAmount>0:
		animationTree.set("parameters/leftArmed_Throw/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE)
		isArmingThrowable = true
		isThrowing = false

func throwThrowable()->void:
	if isArmingThrowable:
		isThrowing = true
		canThrowThrowable = false
		animationTree.set("parameters/leftArmed_Throw/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		## Throw the actual throwable here
		await get_tree().create_timer(0.8).timeout
		canThrowThrowable = true
		isThrowing = false
		isArmingThrowable = false

func savePawnFile(pawnInfo:String,pawnFilename:String = "player")->String:
	Console.add_rich_console_message("[color=green]Saving Pawn to File..[/color]")
	var path = FileAccess.open("%s.pwn"%pawnFilename,FileAccess.WRITE)
	path.store_line(pawnInfo)
	Console.add_rich_console_message("[color=green]Saved Pawn info to file![/color]")
	return "%s.pwn"%pawnFilename


func savePawnInformation()->String:
	Console.add_rich_console_message("[color=green]Saving Pawn Info..[/color]")
	var saveWeapons : Array
	var saveWeaponAmmo : Array
	var saveWeaponMags : Array
	var saveClothes : Array
	var purchasedClothes : Array
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
		if clothingInventory[clothes] != null:
			saveClothes.append(clothingInventory[clothes].get_scene_file_path())
			if !purchasedClothes.has(clothingInventory[clothes].get_scene_file_path()):
				purchasedClothes.append(clothingInventory[clothes].get_scene_file_path())
	var pwnDict = {
		"clothes" : saveClothes,
		"purchasedClothes" : purchasedClothes,
		"items" : saveWeapons,
		"itemAmmo" : saveWeaponAmmo,
		"itemMags" : saveWeaponMags,
		"pawnColorR" : pawnColor.r,
		"pawnColorG" : pawnColor.g,
		"pawnColorB" : pawnColor.b,
	}
	var stringy = JSON.stringify(pwnDict)
	Console.add_rich_console_message("[color=green]Saved Pawn info![/color]")
	return stringy


func loadPawnFile(pawnFile:String = "player")->void:
	if not FileAccess.file_exists(pawnFile):
		Console.add_rich_console_message("[color=red]Pawn file doesn't exist![/color]")
		print(pawnFile)
		return

	var pwnFile = FileAccess.open(pawnFile,FileAccess.READ)
	while pwnFile.get_position() < pwnFile.get_length():
		var string = pwnFile.get_line()
		loadPawnInfo(string)


func loadPawnInfo(pawnInfo:String)->void:
	purchasedClothing.clear()
	clothingInventory.clear()
	itemInventory.clear()
	for clothes in clothingHolder.get_children():
		clothes.queue_free()
	for weapons in itemHolder.get_children():
		weapons.queue_free()
	setBodyVisibility(true)
	itemInventory.append(null)

	var json = JSON.new()
	var result = json.parse(pawnInfo)

	if not result == OK:
		Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%pawnInfo)
		return

	var nodeData : Variant = json.get_data()

	##Create Inventory Items/Clothes
	var itemAmmo : Array
	var itemMags : Array
	if nodeData["itemAmmo"] != null:
		itemAmmo = nodeData["itemAmmo"]
	if nodeData["itemMags"] != null:
		itemMags = nodeData["itemMags"]

	var items : Array = nodeData["items"]
	for item in items:
		var index : int = items.find(item)
		var inventoryItem : Weapon = load(item).instantiate()
		itemHolder.add_child(inventoryItem)
		if nodeData["itemAmmo"] != null and nodeData["itemMags"] != null:
			if itemAmmo.size() >0:
				inventoryItem.currentAmmo = itemAmmo[index]
			if itemMags.size() >0:
				inventoryItem.currentMagSize = itemMags[index]


	if nodeData["purchasedClothes"] != null:
		purchasedClothing = nodeData["purchasedClothes"]

	for clothing in nodeData["clothes"]:
			var clothingItem = load(clothing).instantiate()
			clothingHolder.add_child(clothingItem)

	checkClothes()
	checkItems()
	pawnColor = Color(nodeData["pawnColorR"],nodeData["pawnColorG"],nodeData["pawnColorB"],1)
	Console.add_rich_console_message("[color=green]Loaded Pawn File![/color]")

func setThrowableBlendValue(value:float)->void:
	animationTree.set("parameters/leftThrowableBlend/blend_amount",value)

func setRightHandBlendValue(value:float)->void:
	animationTree.set("parameters/weaponBlend/blend_amount",value)

func setLeftHandBlendValue(value:float)->void:
	animationTree.set("parameters/weaponBlend_Left_blend/blend_amount",value)

func enableRunBlend()->void:
	if runTween:
		runTween.kill()
	runTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/runBlend/blend_amount")
	runTween.tween_method(setRunBlendValue,currentBlend,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func disableRunBlend()->void:
	if runTween:
		runTween.kill()
	runTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/runBlend/blend_amount")
	runTween.tween_method(setRunBlendValue,currentBlend,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func enableFallBlend()->void:
	if fallTween:
		fallTween.kill()
	fallTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/fallBlend/blend_amount")
	fallTween.tween_method(setFallBlendValue,currentBlend,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func disableFallBlend()->void:
	if fallTween:
		fallTween.kill()
	fallTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/fallBlend/blend_amount")
	fallTween.tween_method(setFallBlendValue,currentBlend,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func enableIdleSpaceBlend()->void:
	if idleSpaceTween:
		idleSpaceTween.kill()
	idleSpaceTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/idleSpace/blend_position")
	idleSpaceTween.tween_method(setIdleBlend,currentBlend,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func disableIdleSpaceBlend()->void:
	if idleSpaceTween:
		idleSpaceTween.kill()
	idleSpaceTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/idleSpace/blend_position")
	idleSpaceTween.tween_method(setIdleBlend,currentBlend,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func enableLeftHand()->void:
	if leftHandTween:
		leftHandTween.kill()
	leftHandTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/weaponBlend_Left_blend/blend_amount")
	leftHandTween.tween_method(setLeftHandBlendValue,currentBlend,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	#tween.tween_callback(tween.kill)

func enableRightHand()->void:
	if rightHandTween:
		rightHandTween.kill()
	rightHandTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/weaponBlend/blend_amount")
	rightHandTween.tween_method(setRightHandBlendValue,currentBlend,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	#tween.tween_callback(tween.kill)

func disableLeftHand()->void:
	if leftHandTween:
		leftHandTween.kill()
	leftHandTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/weaponBlend_Left_blend/blend_amount")
	leftHandTween.tween_method(setLeftHandBlendValue,currentBlend,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	#tween.tween_callback(tween.kill)

func disableRightHand()->void:
	if rightHandTween:
		rightHandTween.kill()
	rightHandTween = create_tween().bind_node(animationTree)
	var currentBlend : float = animationTree.get("parameters/weaponBlend/blend_amount")
	rightHandTween.tween_method(setRightHandBlendValue,currentBlend,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	#rightHandTween.tween_callback(tween.kill)

func disableThrowableAnim()->void:
		if throwableTween:
			throwableTween.kill()
		throwableTween = create_tween().bind_node(animationTree)
		var currentBlend : float = animationTree.get("parameters/leftThrowableBlend/blend_amount")
		throwableTween.tween_method(setThrowableBlendValue,currentBlend,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func enableThrowableAnim()->void:
		enableLeftHand()
		if throwableTween:
			throwableTween.kill()
		throwableTween = create_tween().bind_node(animationTree)
		var currentBlend : float = animationTree.get("parameters/leftThrowableBlend/blend_amount")
		throwableTween.tween_method(setThrowableBlendValue,currentBlend,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)

func setFallBlendValue(value:float)->void:
	animationTree.set("parameters/fallBlend/blend_amount",value)

func setRunBlendValue(value:float)->void:
	animationTree.set("parameters/runBlend/blend_amount",value)

func setIdleBlend(value:float)->void:
	animationTree.set("parameters/idleSpace/blend_position", value)

func setBodyIKInterpolation(value:float)->void:
	bodyIK.interpolation = value

func disableBodyIK()->void:
	if bodyIKTween:
		bodyIKTween.kill()
	bodyIKTween = create_tween().bind_node(animationTree)
	await bodyIKTween.tween_method(setBodyIKInterpolation,bodyIK.interpolation,0,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
	bodyIK.stop()

func startBodyIK()->void:
	if bodyIKTween:
		bodyIKTween.kill()
	bodyIKTween = create_tween().bind_node(animationTree)
	bodyIK.start()
	bodyIKTween.tween_method(setBodyIKInterpolation,bodyIK.interpolation,1,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished

func checkMeshLookat()->void:
	if meshLookAt:
		startBodyIK()
		if !freeAim:
			if currentItem != null:
				if currentItem.isAiming != true:
					currentItem.isAiming = true
				else:
					if currentItem.isAiming != false:
						currentItem.isAiming = false
	else:
		disableBodyIK()

func getShortTweenAngle(currentAngle:float,targetAngle:float)->float:
	return currentAngle + wrapf(targetAngle-currentAngle,-PI,PI)

func isCurrentlyMoving()->bool:
	return abs(direction.x) > 0 or abs(direction.z) > 0

func isOnGround()->bool:
	return is_on_floor()

func dive()->void:
	isDiving = true
	#disableBodyIK()
	#bodyIKMarker.position += diveDirection * diveForce


func setBulletTime(value:bool)->void:
	if value:
		gameManager.enableBulletTime()
	else:
		gameManager.disableBulletTime()


func deleteAllHitboxes():
	for hb in getAllHitboxes():
		hb.queue_free()


func toggleBulletTime()->void:
	if gameManager.bulletTime:
		setBulletTime(false)
	else:
		if gameManager.canBulletTime:
			setBulletTime(true)

func playInteractAnimation()->void:
	animationTree.set("parameters/useType/transition_request", "interactL")
	animationTree.set("parameters/useShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func playUseAnimation()->void:
	animationTree.set("parameters/useType/transition_request", "useL")
	animationTree.set("parameters/useShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func playGrabAnimation()->void:
	animationTree.set("parameters/useType/transition_request", "grabL")
	animationTree.set("parameters/useShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
