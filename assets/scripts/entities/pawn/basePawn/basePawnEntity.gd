extends CharacterBody3D
class_name BasePawn

##Signals
signal directionChanged
signal controllerAssigned
signal clothingChanged
signal itemChanged
signal forcingAnimation
signal killedPawn
signal hitboxAssigned(hitbox)
signal headshottedPawn

#Threading
var thread1 : Thread = Thread.new()
var thread2 : Thread = Thread.new()
var duplicated : Array
#Sounds
@onready var soundHolder : Node3D = $Sounds
@onready var equipSound : AudioStreamPlayer3D = $Sounds/equipSound
@onready var footstepSounds : AudioStreamPlayer3D = $Sounds/footsteps
##Onready
@onready var onScreenNotifier : VisibleOnScreenNotifier3D = $visibleOnScreenNotifier3d
@onready var footstepMaterialChecker : RayCast3D = $Misc/footstepMaterialChecker
@onready var componentHolder : Node3D = $Components
@onready var boneAttatchementHolder : Node = $BoneAttatchments
@onready var interactRaycast : RayCast3D = $Mesh/interactRaycast

##IK
@onready var bodyIK : SkeletonIK3D= $Mesh/MaleSkeleton/Skeleton3D/bodyIK
@onready var bodyIKMarker : Marker3D = $Mesh/bodyIKMarker:
	set(value):
		bodyIKMarker = value
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
var step_climb_count : int = 0
var direction : Vector3 = Vector3.ZERO:
	set(value):
		direction = value
		directionChanged.emit()
		if value != Vector3.ZERO:
			direction = direction.normalized()
			isMoving = true
		else:
			isMoving = false
var meshRotation : float = 0.0
##Component Setup
@export_category("Pawn")
var defaultPawnMaterial = load("res://assets/materials/pawnMaterial/MALE.tres")
var currentPawnMat : StandardMaterial3D
@export var pawnColor : Color = Color(1.0,0.76,0.00,1.0):
	set(value):
		pawnColor = value
		setupPawnColor()
var raycaster : RayCast3D
#Base Components - Components required for this entity to even be used
@export_subgroup("Base Components")
@export var velocityComponent : VelocityComponent
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
@export var freeAim : bool = false
@export var pawnEnabled : bool = true
@export var collisionEnabled : bool = true:
	set(value):
		collisionEnabled = value
	get:
		return collisionEnabled

@export_subgroup("Variables")
signal pawnDied(pawnRagdoll)
@export var turnAmount : float
@export var turnSpeed : float = 18.0
var preventWeaponFire : bool = false
@export var isPawnDead : bool = false:
	set(value):
		isPawnDead = value
	get:
		return isPawnDead
@export var isMoving : bool = false:
	set(value):
		isMoving = value
		if !isMoving:
			if footstepSounds.playing:
				footstepSounds.stop()
@export_subgroup("Movement")
var goingUpHill : bool = false
var goingDownHill : bool = false
var oldPos : float = 0.0
@export var canRun : bool = true
@export var isRunning : bool = false:
	set(value):
		if velocityComponent:
			isRunning = value
			if isRunning:
				velocityComponent.vMaxSpeed = defaultRunSpeed
			else:
				velocityComponent.vMaxSpeed = defaultWalkSpeed
@export var JUMP_VELOCITY : float = 4.5
@export var defaultWalkSpeed : float = 3.0
@export var defaultRunSpeed : float = 6.0
@export var canJump : bool = true
@export var isJumping : bool = false
@export_subgroup("Inventory")
var throwableInventory : Array = []
var isArmingThrowable : bool = false
var canThrowThrowable : bool = true
var pawnCash : int = 0
var itemNames : Array
@export var itemInventory : Array
var currentItem = null
@export var currentItemIndex = 0:
	set(value):
		currentItemIndex = clamp(value, 0, itemInventory.size()-1)
		currentItem = itemInventory[currentItemIndex]
		if !currentItem == null:
			emit_signal("itemChanged")
			equipWeapon(currentItemIndex)
			if currentItem.weaponResource != null:
				await get_tree().process_frame
				if currentItem.weaponResource.leftHandParent:
					itemHolder.reparent(leftHandBone)
					itemHolder.position = Vector3.ZERO
				if currentItem.weaponResource.rightHandParent:
					itemHolder.reparent(rightHandBone)
					itemHolder.position = Vector3.ZERO

			if attachedCam:
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
				Dialogic.VAR.set('playerHasWeaponEquipped',true)
				#attachedCam.resetCamCast()
		else:
			for weapon in itemHolder.get_children():
				weapon.hide()
			if attachedCam:
				Dialogic.VAR.set('playerHasWeaponEquipped',false)
				attachedCam.itemEquipOffsetToggle = false
				attachedCam.hud.getCrosshair().setCrosshair(null)
				#attachedCam.resetCamCast()
@export var clothingInventory : Array:
	set(value):
		clothingInventory = value
		emit_signal("clothingChanged")

@export_subgroup("Mesh")
##Ragdoll to spawn when the pawn dies
@export var ragdollScene : PackedScene
##Makes the mesh look at a certain thing, mainly used for aiming
@export var meshLookAt : bool = false
@export var lastHitPart : int:
	set(value):
		lastHitPart = value
		await get_tree().create_timer(0.5).timeout
		lastHitPart = 0
@export var hitImpulse : Vector3 = Vector3.ZERO:
	set(value):
		hitImpulse = value
		await get_tree().create_timer(0.5).timeout
		hitImpulse = Vector3.ZERO
@export var hitVector : Vector3 = Vector3.ZERO
@export_subgroup("Misc")
## First-person, just for shits and giggles
var isFirstperson : bool = false:
	set(value):
		isFirstperson = value
		meshLookAt = value
		freeAim = value
var hitboxes : Array[Hitbox]

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	itemInventory.append(null)
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
	#getAllHitboxes()
func _physics_process(delta) -> void:
	if pawnEnabled:
		if !isPawnDead:
#region AimBlocking
			preventWeaponFire = aimBlockRaycast.is_colliding()
#endregion
		if fallDamageEnabled:
			if floorcheck.is_colliding():
				if velocity.y <= -15:
					if !isPawnDead:
						die(null)

#region FreeAim
			if freeAim:
				if !isFirstperson:
					meshLookAt = true
					bodyIK.start()
					bodyIK.interpolation = lerpf(bodyIK.interpolation, 1, turnSpeed * delta)
				else:
					meshLookAt = true
					if currentItem:
						bodyIK.start()
						bodyIK.interpolation = lerpf(bodyIK.interpolation, 1, turnSpeed * delta)
					else:
						bodyIK.interpolation = lerpf(bodyIK.interpolation, 0, turnSpeed * delta)
#endregion

#region Item Equipping
			if !currentItem == null:
				#Weapon Aiming
				if meshLookAt and !freeAim:
					if currentItem.isAiming != true:
						currentItem.isAiming = true
				else:
					if currentItem.isAiming != false:
						currentItem.isAiming = false
				if isMoving and isRunning and is_on_floor() and !meshLookAt and !currentItem.weaponResource.useWeaponSprintAnim and !currentItem.isReloading and animationTree.active or currentItem == null:
					animationTree.set("parameters/weaponBlend/blend_amount", lerpf(animationTree.get("parameters/weaponBlend/blend_amount"), 0, 4*delta))
					animationTree.set("parameters/weaponBlend_Left_blend/blend_amount", lerpf(animationTree.get("parameters/weaponBlend_Left_blend/blend_amount"), 0, 12*delta))
				else:
					animationTree.set("parameters/weaponBlend/blend_amount", lerpf(animationTree.get("parameters/weaponBlend/blend_amount"), 1, 12*delta))
			else:
				animationTree.set("parameters/weaponBlend/blend_amount", lerpf(animationTree.get("parameters/weaponBlend/blend_amount"), 0, 12*delta))
				animationTree.set("parameters/weaponBlend_Left_blend/blend_amount", lerpf(animationTree.get("parameters/weaponBlend_Left_blend/blend_amount"), 0, 12*delta))

			#Mesh Rotation
			doMeshRotation(delta)
			# Add the gravity
			if !is_on_floor():
				canJump = false
				velocity.y -= gravity * delta

			if is_on_floor():
				isJumping = false
				animationTree.set("parameters/fallBlend/blend_amount", lerpf(animationTree.get("parameters/fallBlend/blend_amount"), 0.0, delta * 12))
				#animationTree.set("parameters/jumpBlend/blend_amount", lerpf(animationTree.get("parameters/jumpBlend/blend_amount"), 0.0, delta * 12))
				if !meshLookAt:
					canJump = true
				elif meshLookAt and isFirstperson and animationTree.active:
					canJump = true

			if !velocityComponent == null:
				velocity.x = velocityComponent.accelerateToVel(direction, delta, true, false, false).x
				velocity.z = velocityComponent.accelerateToVel(direction, delta, false, false, true).z

		#Jump Animation
			if animationTree.active:
				if !is_on_floor():
					if velocity.y > 0:
						if animationTree.get("parameters/jumpshot/active") == false:
							animationTree.set("parameters/jumpshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					else:
						animationTree.set("parameters/jumpshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
						animationTree.set("parameters/fallBlend/blend_amount", lerpf(animationTree.get("parameters/fallBlend/blend_amount"), 1.0, delta * 12))

				animationTree.set("parameters/aimSprintStrafe/blend_position",Vector2(-velocity.x, -velocity.z).rotated(meshRotation))
				animationTree.set("parameters/strafeSpace/blend_position",animationTree.get("parameters/aimSprintStrafe/blend_position"))
				if meshLookAt:
					bodyIK.start()
					bodyIK.interpolation = lerpf(bodyIK.interpolation, 1, turnSpeed * delta)
					if is_on_floor():
						animationTree.set("parameters/aimTransition/transition_request", "aiming")
						if !isRunning:
							animationTree.set("parameters/strafeType/transition_request", "walking")
						else:
							animationTree.set("parameters/strafeType/transition_request", "running")
					else:
						animationTree.set("parameters/aimTransition/transition_request", "notAiming")
				else:
					animationTree.set("parameters/aimTransition/transition_request", "notAiming")
					bodyIK.interpolation = lerpf(bodyIK.interpolation, 0, turnSpeed * delta)
					if bodyIK.interpolation <= 0:
						bodyIK.stop()
					if isMoving:
						if !isRunning:
							if !velocityComponent == null:
								animationTree.set("parameters/runBlend/blend_amount", lerpf(animationTree.get("parameters/runBlend/blend_amount"), 0.0, delta * velocityComponent.getAcceleration()))
								animationTree.set("parameters/idleSpace/blend_position", lerpf(animationTree.get("parameters/idleSpace/blend_position"), 1, delta * velocityComponent.getAcceleration()))
						if isRunning:
							if !velocityComponent == null:
								animationTree.set("parameters/runBlend/blend_amount", lerpf(animationTree.get("parameters/runBlend/blend_amount"), 1.0, delta * velocityComponent.getAcceleration()))
					else:
						if !velocityComponent == null:
							animationTree.set("parameters/runBlend/blend_amount", lerpf(animationTree.get("parameters/runBlend/blend_amount"), 0.0, delta * velocityComponent.getAcceleration()))
							animationTree.set("parameters/idleSpace/blend_position", lerp(animationTree.get("parameters/idleSpace/blend_position"), 0.0, delta * velocityComponent.getAcceleration()))
		#Move the pawn accordingly
		move_and_slide()

		#Player movement
		if inputComponent:
			if inputComponent is Component:
				if inputComponent.movementEnabled:
					if Dialogic.current_timeline == null:
						direction = inputComponent.getInputDir().rotated(Vector3.UP, meshRotation)
					else:
						direction = Vector3.ZERO

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



	if velocityComponent == null or healthComponent == null:
		return null
	else:
		return OK

func die(killer:Node3D = null) -> void:
	if !attachedCam == null:
		attachedCam.cameraRotationUpdated.disconnect(doMeshRotation)
		gameManager.getEventSignal("playerDied").emit()
		attachedCam.lowHP = false
		attachedCam.hud.hudEnabled = false
		attachedCam.resetCamCast()
		Dialogic.end_timeline()
	isPawnDead = true
	var ragdoll = await createRagdoll(lastHitPart, killer)
	await moveDecalsToRagdoll(ragdoll)
	killedPawn.emit()
	await get_tree().process_frame
	for hb in getAllHitboxes():
		hb.queue_free()
	pawnDied.emit(ragdoll)
	removeComponents()
	dropWeapon()
	if currentItem:
		currentItem.weaponOwner = null
	currentItemIndex = 0
	currentItem = null
	pawnEnabled = false
	collisionEnabled = false
	$remover.start()
	footstepSounds.queue_free()
	queue_free()

func _on_health_component_health_depleted(dealer) -> void:
	await get_tree().process_frame
	if dealer != null:
		die(dealer)
	else:
		die(null)


func createRagdoll(impulse_bone : int = 0,killer:Node3D = null):
	var currVel = velocity
	await get_tree().process_frame
	if !ragdollScene == null:
		collisionEnabled = false
		self.hide()
		var ragdoll = ragdollScene.instantiate()
		moveDecalsToRagdoll(ragdoll)
		ragdoll.global_transform = pawnMesh.global_transform
		ragdoll.rotation = pawnMesh.rotation
		ragdoll.targetSkeleton = pawnSkeleton
		gameManager.world.worldMisc.add_child(ragdoll)
		ragdoll.setPawnMaterial(currentPawnMat)
		for bones in ragdoll.ragdollSkeleton.get_bone_count():
			ragdoll.ragdollSkeleton.set_bone_pose_position(bones, pawnSkeleton.get_bone_pose_position(bones))
			ragdoll.ragdollSkeleton.set_bone_pose_rotation(bones, pawnSkeleton.get_bone_pose_rotation(bones))
		for bones in ragdoll.ragdollSkeleton.get_child_count():
			var child = ragdoll.ragdollSkeleton.get_child(bones)
			if child is RagdollBone:
				child.linear_velocity = currVel
				child.angular_velocity = currVel
				ragdoll.startRagdoll()
				child.apply_central_impulse(currVel)
				if child.get_bone_id() == impulse_bone:
					ragdoll.startRagdoll()
					child.apply_impulse(hitImpulse * randf_range(1.5,2), hitVector)
		emit_signal("pawnDied",ragdoll)
		moveClothesToRagdoll(ragdoll)
		ragdoll.checkClothingHider()

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
			await get_tree().process_frame
			await cam.unposessObject()
			await cam.posessObject(ragdoll, ragdoll.rootCameraNode)
			ragdoll.removeTimer.stop()
			for bones in ragdoll.ragdollSkeleton.get_child_count():
				if ragdoll.ragdollSkeleton.get_child(bones) is RagdollBone:
					cam.camSpring.add_excluded_object(ragdoll.ragdollSkeleton.get_child(bones).get_rid())
			attachedCam = null
		if ragdoll.activeRagdollEnabled:
			if impulse_bone == 41:
				ragdoll.activeRagdollEnabled = false
			forceAnimation = true
			animationToForce = "PawnAnim/WritheRightKneeBack"
		if collisionShape != null:
			collisionShape.queue_free()
		return ragdoll


func checkItems():
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

func checkClothes():
	for clothes in clothingHolder.get_children():
		if !clothingInventory.has(clothes):
			clothingInventory.append(clothes)
			clothes.itemSkeleton = pawnSkeleton.get_path()
			clothes.remapSkeleton()

	checkClothingHider()

func moveClothesToRagdoll(moveto) -> void:
	for clothes in clothingHolder.get_children():
		clothes.itemSkeleton = moveto.ragdollSkeleton.get_path()
		clothes.reparent(moveto)
		clothes.remapSkeleton()
	return


func checkClothingHider() -> void:
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

func moveDecalsToRagdoll(ragdoll:PawnRagdoll):
	#Decal reparent..
	for hboxes in getAllHitboxes():
		for decals in hboxes.get_children():
			if decals is BulletHole:
				await get_tree().process_frame
				for bone in ragdoll.ragdollSkeleton.get_children():
					if bone is PhysicalBone3D:
						if bone.get_bone_id() == hboxes.boneId:
							decals.reparent(bone,true)
							print(decals.get_parent())
							#Console.add_console_message("For %s, %s" %[self,getCurrentDecalBones()])
	return true

func getAllHitboxes() -> Array[Hitbox]:
	return hitboxes

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
			currentItem.weaponAnimSet = true
			return
	else:
		print_rich("[color=red]You don't have a weapon![/color]")
		return

func setLeftHandFilter(value : bool = true) -> void:
	var filterBlend = animationTree.tree_root.get_node("weaponBlend")
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

func equipWeapon(index) -> void:
	await unequipWeapon()
	if !equipSound.playing:
		equipSound.play()
	currentItem = itemInventory[index]
	currentItem.weaponOwner = self
	currentItem.isEquipped = true
	currentItem.visible = true
	await setupWeaponAnimations()


func unequipWeapon() -> void:
	animationTree.set("parameters/weaponBlend/blend_amount", 0)
	animationTree.set("parameters/weaponBlend_Left_blend/blend_amount", 0)
	for weapon in itemHolder.get_children():
		weapon.hide()
		weapon.resetToDefault()
	if currentItem:
		currentItem.resetToDefault()
		currentItem.weaponAnimSet = false
		currentItem.isEquipped = false
		currentItem.isAiming = false
		currentItem.hide()
		currentItem = null


func _on_free_aim_timer_timeout() -> void:
	freeAim = false

func _on_remover_timeout() -> void:
	queue_free()

func removeComponents() -> void:
	velocityComponent = null
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

func interpolate_visual_position(offset : Vector3) -> void:
	var new_step = step_climb_count + 1
	step_climb_count = new_step
	var camera_destination : Vector3 = Vector3.UP * 1.466
	while !offset.is_equal_approx(Vector3.ZERO) and step_climb_count == new_step:
		offset = offset.move_toward(Vector3.ZERO, get_process_delta_time() * 4)
		if attachedCam:
			attachedCam.camPivot.position = camera_destination + offset
		pawnMesh.position = offset
		await get_tree().process_frame
	if attachedCam:
		attachedCam.camPivot.position = camera_destination
	pawnMesh.position  = Vector3.ZERO

func setPawnMaterial() -> void:
	currentPawnMat.albedo_color = pawnColor
	for mesh in pawnSkeleton.get_children():
		if mesh is MeshInstance3D:
			mesh.set_surface_override_material(0,currentPawnMat)

func setupPawnColor() -> void:
	if pawnColor != Color(1.0,0.76,0.00,1.0):
		if !currentPawnMat:
			currentPawnMat = defaultPawnMaterial.duplicate()
			duplicated.append(currentPawnMat)
			setPawnMaterial()

func setupAnimationTree() -> void:
	if animationTree:
		var dupRoot = animationTree.tree_root.duplicate()
		animationTree.tree_root = dupRoot
		duplicated.append(dupRoot)

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

func doMeshRotation(delta:float = get_physics_process_delta_time()) -> void:
#region Mesh Rotation
			if !is_on_wall():
				if is_on_floor():
					pawnMesh.rotation.x = clamp(lerp_angle(pawnMesh.rotation.x, (Vector3(velocity.x, 0.0, velocity.z) * pawnMesh.global_transform.basis).z * 0.015, delta * 16), -7, 7)
				else:
					pawnMesh.rotation.x = clamp(lerp_angle(pawnMesh.rotation.x, (Vector3(velocity.y, velocity.y, velocity.y) * pawnMesh.global_transform.basis).y * 0.030, delta * 8), -1, 1)
				pawnMesh.rotation.z = clamp(lerpf(pawnMesh.rotation.z, -(Vector3(velocity.x,0.0, velocity.z) * pawnMesh.global_transform.basis).x * 0.035, 16 * delta), -3, 3)
			else:
				pawnMesh.rotation.x = lerpf(pawnMesh.rotation.x, 0, 12*delta)
				pawnMesh.rotation.z = lerpf(pawnMesh.rotation.z, 0, 12*delta)
			if !meshLookAt:
				if isMoving:
					if !is_on_wall():
						pawnMesh.rotation.y = lerp_angle(pawnMesh.rotation.y, atan2(-velocity.x,-velocity.z), 8 * delta)
					else:
						isMoving = false
			if meshLookAt:
				canJump = false
				bodyIKMarker.rotation.x = turnAmount
				#bodyIKMarker.rotation_degrees.y = lerpf(bodyIKMarker.rotation_degrees.y, to_local(Vector3(0,180,0)).y, 16*delta)
				bodyIKMarker.rotation.z = lerpf(bodyIKMarker.rotation.z, 0.0, 16*delta)
				pawnMesh.rotation.y = lerp_angle(pawnMesh.rotation.y, meshRotation, 23 * delta)
#endregion

func flinch() -> void:
	if !healthComponent.health <= 10 or !lastHitPart == 41:
		bodyIK.start()
		bodyIK.interpolation = 1
		bodyIKMarker.rotation.x += randf_range(-0.1,0.35)
		#bodyIKMarker.rotation.y += randf_range(-0.5,0.5)
		bodyIKMarker.rotation.z += randf_range(-0.25,0.35)

func _on_health_component_on_damaged(dealer, hitDirection)->void:
	flinch()

func _exit_tree()->void:
	for i in duplicated.size():
		if duplicated[i] is Node:
			duplicated[i].queue_free()

func armThrowable()->void:
	if canThrowThrowable:
		isArmingThrowable = true

func throwThrowable()->void:
	if isArmingThrowable:
		canThrowThrowable = false
		isArmingThrowable = false
		## Throw the actual throwable here
		canThrowThrowable = true
		isArmingThrowable = true