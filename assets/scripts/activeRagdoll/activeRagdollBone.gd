extends RigidBody3D
class_name ActiveRagdollBone
@export var doActive = false
"""
	Active Ragdolls - Ragdoll Bone
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	This is the script which transfers the rotation from the RigidBody
	to the Skeleton3D.
"""

"""
	INIT
"""
func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)


"""
	APPLY OWN ROTATION TO THE RESPECTIVE BONE IN PARENT Skeleton3D
"""
func _physics_process(_delta: float) -> void:
	if doActive:
		var bone_global_rotation : Basis = get_parent().global_transform.basis * get_parent().get_bone_global_pose(get_parent().get_bone_id()).basis
		var b2t_rotation : Basis = bone_global_rotation.inverse() * self.transform.basis
		#get_parent().set_bone_pose_rotation(get_bone_id(), (get_parent().get_bone_pose_rotation(get_bone_id()) * b2t_rotation.get_rotation_quaternion()))
