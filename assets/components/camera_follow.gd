extends Node3D


##set to 0 to disable an axis, set to 1 to follow an axis
@export var scale_factor : Vector3 = Vector3.ONE
@export var follow_pawn : bool = false


func _process(delta: float) -> void:
	if follow_pawn:
		var pawn : BasePawn = gameManager.getCurrentPawn()
		if pawn != null:
			global_position = lerp(global_position,pawn.global_position * scale_factor,5*delta)
			return
	var cam : Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		global_position = lerp(global_position,cam.global_position * scale_factor,5*delta)
