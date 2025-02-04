extends Resource
class_name PawnSpawnParameters

@export_node_path("PawnSpawn") var spawn_location

@export var pawn_name : String = "Guy"
@export_enum("Player","Pawn") var pawn_type : int = 1
@export_enum("High","Normal","Retarded") var ai_skill = 1
@export_enum("Idle","Wander","Patrol") var ai_type = 1
@export var weaponEquip : int = 1
@export var clothes : Array[PackedScene]
@export var weapons : Array[PackedScene]
