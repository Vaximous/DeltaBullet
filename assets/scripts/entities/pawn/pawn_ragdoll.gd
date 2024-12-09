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
@export var activeRagdollEnabled:bool = false:
	set(value):
		activeRagdollEnabled = value
		activeRagdollChanged.emit(value)
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
	for bones in physicalBoneSimulator.get_children().filter(func(x): return x is PhysicalBone3D):
		physicsBones.append(bones)
	for pb in physicsBones:
		if pb.get_script() != null:
			for b in physicsBones:
				pb.exclusionArray.append(RID(b))
				b.ownerSkeleton = ragdollSkeleton
				b.ragdoll = self

	deathSound.play()
	if startOnInstance:
		startRagdoll()

	#physicalBoneSimulator.ragdoll = self
	checkClothingHider()

func startRagdoll()-> void:
	ragdollSkeleton.animate_physical_bones = true
	physicalBoneSimulator.physical_bones_start_simulation()
	checkClothingHider()

func ragTwitch(convulsionAmount : float = 10.0, bodyPartIDX : int = 0)-> void:
	pass

func checkClothingHider()-> void:
	for clothes in self.get_children():
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

	var destroyedHeads : Array = [preload("res://assets/models/pawn/male/headDestroyed1.tres"),preload("res://assets/models/pawn/male/headDestroyed2.tres"),preload("res://assets/models/pawn/male/headDestroyed3.tres")]
	headshotsound.play()
	deathSound.stop()
	obliterateSound.play()
	#print_rich("[color=red]BOOM HEADSHOT!!!!!!")
	head.mesh = destroyedHeads.pick_random()
	var particle = globalParticles.createParticle("BloodSpurt",Vector3(headBone.global_position.x,headBone.global_position.y-1.4,headBone.global_position.z))
	particle.rotation = headBone.global_rotation
	particle.amount = randi_range(25,75)
	for clothes in self.get_children():
		if clothes is ClothingItem:
			if clothes.clothingType == 0 or clothes.clothingType == 1:
				clothes.queue_free()
				checkClothingHider()
	gameManager.sprayBlood(headBone.global_position,particle.amount,150,1.2)

func setPawnMaterial(material)-> void:
	for mesh in ragdollSkeleton.get_children():
		if mesh is MeshInstance3D:
			mesh.set_surface_override_material(0,material)


func _on_visible_on_screen_notifier_3d_screen_entered()-> void:
	visibleOnScreen = true
	show()

func _on_visible_on_screen_notifier_3d_screen_exited()-> void:
	visibleOnScreen = false
	hide()


func _on_skeleton_3d_skeleton_updated() -> void:
	for bones in ragdollSkeleton.get_bone_count():
		#ragdollSkeleton.set_bone_rest(bones, savedPose[bones])
		ragdollSkeleton.set_bone_pose(bones, savedPose[bones])

func getBoneChildren(skeleton3d:Skeleton3D,bone:PhysicalBone3D)->Array:
	return skeleton3d.get_bone_children(bone.get_bone_id())
