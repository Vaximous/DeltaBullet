extends Resource
class_name WaveSpawnerWaveParams


@export var wave_time_limit : float = 120.0
@export var spawn_parameters : Array[PawnSpawnParameters]
@export var time_between_spawns : float = 1.0
@export var next_spawn_index : int = 0
@export var wave_spawns : Array = []


func _init() -> void:
	resource_local_to_scene = true


#All waves done.
func is_finished() -> bool:
	return next_spawn_index > spawn_parameters.size()


#Spawns the next pawn and returns it.
func spawn_next_pawn(wave_spawner : Timer) -> Array:
	var next_params = spawn_parameters[next_spawn_index]
	var next_spawnpoint : PawnSpawn = wave_spawner.get_node(next_params.spawn_location)
	var _spawn_active : bool = next_spawnpoint.active
	next_spawnpoint.active = true
	var new_pawn = next_spawnpoint.spawnPawn(null, next_params)
	next_spawnpoint.active = _spawn_active
	wave_spawns.append(new_pawn)
	next_spawn_index += 1
	return [next_params, new_pawn]


# Helper to check if there are unspawned pawns left in this wave.
func has_unspawned_pawns() -> bool:
	return wave_spawns.size() < spawn_parameters.size()


#If everyone of this wave is dead, return true. Else, return false.
func is_wave_complete() -> bool:
	if wave_spawns.size() < spawn_parameters.size():
		return false
	for pawn in wave_spawns:
		if is_instance_valid(pawn):
			return false
	return true


func get_alive_pawns() -> Array[BasePawn]:
	var living : Array[BasePawn] = []
	for pawn in wave_spawns:
		if is_instance_valid(pawn):
			living.append(pawn)
	return living


#Returns the number of enemies that haven't been killed or spawned yet.
func get_remaining_in_wave() -> int:
	var count = spawn_parameters.size()
	for pawn in wave_spawns:
		if not is_instance_valid(pawn):
			count -= 1
	return count


func is_all_spawned() -> bool:
	return wave_spawns.size() >= spawn_parameters.size()
