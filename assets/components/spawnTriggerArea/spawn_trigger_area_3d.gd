extends Area3D
@export var playerPawnOnly : bool = true
@export var triggerOnce : bool = true
var triggered : bool = false

func _init() -> void:
	body_entered.connect(_on_body_entered)


func _ready() -> void:
	for ch in get_children():
		if ch is PawnSpawn:
			ch.ignore_spawn_on_load = true


func createPawn()->void:
	for ch in get_children():
		if ch is PawnSpawn:
			ch.spawnPawn()


func _on_body_entered(body : Node3D) -> void:
	if body is BasePawn:
		if playerPawnOnly and !triggered:
			if body.isPlayerPawn():
				createPawn()
		else:
			if !triggered:
				createPawn()

	if triggerOnce:
		triggered = true
