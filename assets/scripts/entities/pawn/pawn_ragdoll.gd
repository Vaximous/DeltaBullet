extends Node3D
class_name PawnRagdoll
signal activeRagdollChanged(value:bool)

var visibleOnScreen : bool = true
##Pawn Parts
@onready var headshotsound : AudioStreamPlayer3D = $headshotFlesh
@onready var headBone:PhysicalBone3D = $"Mesh/Male/MaleSkeleton/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Neck"
@onready var removeTimer:Timer = $remove_timer
@onready var head:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/MaleHead
@onready var upperChest:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_UpperBody
@onready var shoulders:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_Shoulders
@onready var leftUpperArm:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_LeftArm
@onready var rightUpperArm:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_RightArm
@onready var leftForearm:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_LeftForearm
@onready var rightForearm:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_RightForearm
@onready var lowerBody:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_LowerBody
@onready var leftUpperLeg:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_LeftThigh
@onready var rightUpperLeg:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_RightThigh
@onready var leftLowerLeg:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_LeftKnee
@onready var rightLowerLeg:MeshInstance3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Male_RightKnee
@onready var deathSound:AudioStreamPlayer3D = $"Mesh/Male/MaleSkeleton/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Neck/deathSound"
@onready var obliterateSound : AudioStreamPlayer3D = $"Mesh/Male/MaleSkeleton/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Neck/obliterateSound"

@onready var clothingHolder:Node3D = $Mesh/Male/MaleSkeleton/Skeleton3D/Clothing
@onready var ragdollSkeleton : Skeleton3D = $Mesh/Male/MaleSkeleton/Skeleton3D
@onready var physicalBoneSimulator : PhysicalBoneSimulator3D = $Mesh/Male/MaleSkeleton/Skeleton3D/PhysicalBoneSimulator3D:
	set(value):
		physicalBoneSimulator = value
@onready var ragdollMesh:Node3D = $Mesh
var physicsBones : Array[PhysicalBone3D]
@export_category("Ragdoll")
var savedPose :Array[Transform3D]
@export_subgroup("Active Ragdoll")
@export var activeRagdollEnabled:bool = false
@export var targetSkeleton : Skeleton3D
@export_subgroup("Behavior")
##Start simulation on create
@export var canTwitch:bool = true
@export var healthComponent : HealthComponent
@export var startOnInstance:bool = true
@export_subgroup("Camera Behavior")
##Root Follow Node
@export var rootCameraNode : Node3D
##Camera Data for a camera to follow
@export var pawnCameraData : CameraData
##If a camera were to be attached to this node, it would follow this.
@export var followNode : Node3D
##The current attached camera (if there is one)
signal cameraAttached
@export var attachedCam : CharacterBody3D:
	set(value):
		attachedCam = value
		emit_signal("cameraAttached")
	get:
		return attachedCam
# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	removeTimer.wait_time = UserConfig.game_ragdoll_remove_time
	removeTimer.start()
	appendPhysicalBoneArray()
	setBoneOwners()

	deathSound.play()

	if startOnInstance:
		startRagdoll()

	#physicalBoneSimulator.ragdoll = self
	checkClothingHider()

func setBoneOwners()->void:
	for pb in physicsBones:
		pb.exclusionArray.append(RID(pb))
		pb.ownerSkeleton = ragdollSkeleton
		pb.ragdoll = self

func appendPhysicalBoneArray()->void:
	for bones in physicalBoneSimulator.get_children().filter(func(x): return x is PhysicalBone3D):
		physicsBones.append(bones)

func startRagdoll()-> void:
	#ragdollSkeleton.animate_physical_bones = true
	physicalBoneSimulator.physical_bones_start_simulation()
	#checkClothingHider()

func ragTwitch(convulsionAmount : float = 10.0, bodyPartIDX : int = 0)-> void:
	pass

func checkClothingHider()-> void:
	for clothes in self.get_children():
		if clothes is ClothingItem:
			match clothes.head:
				true: head.hide()
			match clothes.rightUpperarm:
				true:
					rightUpperArm.hide()
			match clothes.leftUpperarm:
				true:
					leftUpperArm.hide()
			match clothes.shoulders:
				true:
					shoulders.hide()
			match clothes.leftForearm:
				true:
					leftForearm.hide()
			match clothes.rightForearm:
				true:
					rightForearm.hide()
			match clothes.upperChest:
				true:
					upperChest.hide()
			match clothes.lowerBody:
				true:
					lowerBody.hide()
			match clothes.leftUpperLeg:
				true:
					leftUpperLeg.hide()
			match clothes.rightUpperLeg:
				true:
					rightUpperLeg.hide()
			match clothes.rightLowerLeg:
				true:
					rightLowerLeg.hide()
			match clothes.leftLowerLeg:
				true:
					leftLowerLeg.hide()

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)


func _on_remove_timer_timeout()-> void:
	queue_free()

func doRagdollHeadshot()-> void:
	#var droplets : PackedScene = load("res://assets/entities/emitters/bloodDroplet/bloodDroplets.tscn")
	#for drop in randf_range(10,15):
		#if gameManager.world != null:
			#var blood : RigidBody3D = droplets.instantiate()
			#gameManager.world.worldMisc.add_child(blood)
			#blood.global_position = Vector3(headBone.global_position.x,headBone.global_position.y-1.4,headBone.global_position.z)
			#blood.apply_impulse(Vector3(randf_range(-10,10),randf_range(-10,10),randf_range(-10,10)) * randf_range(5,10))

	for x in randi_range(2,7):
		gameManager.createGib(headBone.global_position)
	var destroyedHeads : Array = [preload("res://assets/models/pawn/male/headDestroyed1.tres"),preload("res://assets/models/pawn/male/headDestroyed2.tres"),preload("res://assets/models/pawn/male/headDestroyed3.tres")]
	headshotsound.play()
	deathSound.stop()
	obliterateSound.play()
	#print_rich("[color=red]BOOM HEADSHOT!!!!!!")
	head.mesh = destroyedHeads.pick_random()
	var particle = globalParticles.createParticle("BloodSpurt",Vector3(headBone.global_position.x,headBone.global_position.y-1.4,headBone.global_position.z))
	particle.rotation = headBone.global_rotation
	particle.maxParticles = randi_range(8,10)
	for clothes in self.get_children():
		if clothes is ClothingItem:
			if clothes.clothingType == 0 or clothes.clothingType == 1:
				clothes.queue_free()
				checkClothingHider()
	gameManager.sprayBlood(headBone.global_position,randi_range(1,5),50,1.2)

func setPawnMaterial(material)-> void:
	for mesh in ragdollSkeleton.get_children():
		if mesh is MeshInstance3D:
			mesh.set_surface_override_material(0,material)


func moveClothesToRagdoll(pawn:BasePawn) -> void:
	if is_instance_valid(pawn):
		for clothes in pawn.clothingHolder.get_children():
			clothes.itemSkeleton = ragdollSkeleton.get_path()
			clothes.reparent(self)
			clothes.remapSkeleton()
		return


func setRagdollPose(pawn:BasePawn)->void:
	for bones in ragdollSkeleton.get_bone_count():
		ragdollSkeleton.set_bone_global_pose(bones, pawn.pawnSkeleton.get_bone_global_pose(bones))


func applyRagdollImpulse(pawn:BasePawn,currentVelocity:Vector3,impulseBone:int = 0,hitImpulse:Vector3 = Vector3.ZERO)->void:
	for bones in physicalBoneSimulator.get_children():
		if bones is RagdollBone:
			bones.linear_velocity = currentVelocity
			bones.angular_velocity = currentVelocity
			bones.apply_central_impulse(currentVelocity)
			if bones.get_bone_id() == impulseBone:
				#ragdoll.startRagdoll()
				bones.canBleed = true
				bones.apply_central_impulse(hitImpulse * randf_range(1.5,2))


func createActiveJoints()->void:
	if activeRagdollEnabled:
		for pb in physicsBones:
			pb.createActiveRagdollJoint()


func initializeRagdoll(pawn:BasePawn,pawnvelocity:Vector3 = Vector3.ZERO,lastHit:int=0,impulse:Vector3 = Vector3.ZERO,killer = null)->void:
	if is_instance_valid(pawn):
		name = "%s's Ragdoll"%pawn.name
		setRagdollPositionAndRotation(pawn)
		moveClothesToRagdoll(pawn)
		setRagdollPose(pawn)
		startRagdoll()
		checkClothingHider()
		damageBoneHitboxes(lastHit,killer)
		headshotCheck(lastHit,killer,pawn)
		attachedCamCheck(pawn)
		activeRagdollDeathCheck(lastHit,pawn)
		applyRagdollImpulse(pawn,pawnvelocity,lastHit,impulse)
		if is_instance_valid(pawn.currentPawnMat):
			setPawnMaterial(pawn.currentPawnMat.duplicate())


func attachedCamCheck(pawn:BasePawn)->void:
	if is_instance_valid(pawn.attachedCam):
		var cam = pawn.attachedCam
		cam.unposessObject()
		cam.posessObject(self, rootCameraNode)
		removeTimer.stop()
		for bones in physicalBoneSimulator.get_child_count():
			if physicalBoneSimulator.get_child(bones) is RagdollBone:
				cam.camSpring.add_excluded_object(physicalBoneSimulator.get_child(bones).get_rid())
		pawn.endAttachedCam()
		pawn.attachedCam = null


func activeRagdollDeathCheck(impulse_bone:int,pawn:BasePawn)->void:
	if activeRagdollEnabled:
		if impulse_bone == 41:
			activeRagdollEnabled = false
		pawn.forceAnimation = true
		pawn.animationToForce = "PawnAnim/WritheRightKneeBack"


func headshotCheck(impulse_bone:int,killer,pawn:BasePawn)->void:
	if impulse_bone == 41:
		if is_instance_valid(killer):
			if is_instance_valid(killer.currentItem):
				if killer.currentItem.weaponResource.headDismember:
					doRagdollHeadshot()
			if is_instance_valid(killer.attachedCam):
				killer.attachedCam.doHeadshotEffect()
		pawn.headshottedPawn.emit()



func damageBoneHitboxes(impulse_bone:int,killer)->void:
	for bones in physicalBoneSimulator.get_child_count():
		var child = physicalBoneSimulator.get_child(bones)
		if child is RagdollBone:
			if child.get_bone_id() == impulse_bone:
				child.canBleed = true
				if child.healthComponent and killer != null and killer.currentItem != null:
					var dmgAmount = killer.currentItem.weaponResource.weaponDamage
					child.healthComponent.damage(dmgAmount,killer)


func setRagdollPositionAndRotation(pawn:BasePawn)->void:
	if is_instance_valid(pawn):
		global_transform = pawn.pawnMesh.global_transform
		rotation = pawn.pawnMesh.rotation
		targetSkeleton = pawn.pawnSkeleton

func _on_skeleton_3d_skeleton_updated() -> void:
	for bones in ragdollSkeleton.get_bone_count():
		#ragdollSkeleton.set_bone_rest(bones, savedPose[bones])
		ragdollSkeleton.set_bone_pose(bones, savedPose[bones])

func getBoneChildren(skeleton3d:Skeleton3D,bone:PhysicalBone3D)->Array:
	return skeleton3d.get_bone_children(bone.get_bone_id())
