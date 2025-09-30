extends Area3D


@export var player_controlled_only : bool = true


signal pawn_entered(pawn : BasePawn)
signal pawn_exited(pawn : BasePawn)


func _on_body_entered(body: Node3D) -> void:
	if body is BasePawn:
		if player_controlled_only and not body.isPlayerPawn():
			return
		pawn_entered.emit(body)


func _on_body_exited(body: Node3D) -> void:
	if body is BasePawn:
		if player_controlled_only and not body.isPlayerPawn():
			return
		pawn_exited.emit(body)
