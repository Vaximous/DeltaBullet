extends Area3D


@export var player_controlled_only : bool = true
@export var trigger_once : bool = false

var triggered : bool = false

signal pawn_entered(pawn : BasePawn)
signal pawn_exited(pawn : BasePawn)


func _on_body_entered(body: Node3D) -> void:
	if body is BasePawn:
		if triggered and trigger_once:
			return

		if player_controlled_only and not body.isPlayerPawn():
			return
		pawn_entered.emit(body)
		if trigger_once:
			triggered = true

func _on_body_exited(body: Node3D) -> void:
	if body is BasePawn:
		if player_controlled_only and not body.isPlayerPawn():
			return
		pawn_exited.emit(body)
