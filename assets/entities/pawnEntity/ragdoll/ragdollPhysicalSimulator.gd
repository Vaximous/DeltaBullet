extends PhysicalBoneSimulator3D
var ragdoll : PawnRagdoll:
	set(value):
		ragdoll = value
		bones = value.physicsBones
var bones : Array[PhysicalBone3D]

func _process_modification() -> void:
	for bone in bones:
		var boneTarget = ragdoll.targetSkeleton.global_transform * ragdoll.ragdollSkeleton.get_bone_global_pose(bone.get_bone_id())
		var boneTargetRotation = ragdoll.targetSkeleton.quaternion * get_skeleton().get_bone_pose_rotation(bone.get_bone_id())
		get_skeleton().set_bone_pose_rotation(bone.get_bone_id(),boneTargetRotation)
		print("%s Rotation : %s"%[bone.name,boneTargetRotation])
