extends Area3D


func _init() -> void:
	body_entered.connect(_on_body_entered)


func _ready() -> void:
	for ch in get_children():
		if ch is PawnSpawn:
			ch.ignore_spawn_on_load = true


func _on_body_entered(body : Node3D) -> void:
	for ch in get_children():
		if ch is PawnSpawn:
			ch.spawnPawn()
