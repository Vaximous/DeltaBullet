@tool
extends PhysicalBoneSimulator3D

func _process_modification() -> void:
	pass

func _on_modification_processed() -> void:
	for bone in get_skeleton().get_bone_count():
		get_skeleton().set_bone_pose(bone,get_skeleton().get_bone_pose(bone))
