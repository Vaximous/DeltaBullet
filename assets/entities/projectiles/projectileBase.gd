extends RayCast3D
class_name Projectile


var velocity : Vector3
var distance_traveled : float
@export var max_distance : float = 100.0
var projectile_owner : Weapon:
	set = set_projectile_owner
func set_projectile_owner(value : Weapon) -> void:
	projectile_owner = value
var last_position : Vector3


func _physics_process(delta: float) -> void:
	step(velocity * delta)


func step(movement : Vector3) -> Dictionary:
	update_target(movement)
	var hit : Dictionary = gather_collision_info()
	move(hit['end_position'])
	expire_by_distance()
	return hit


func expire_by_distance() -> bool:
	if distance_traveled >= max_distance:
		queue_free()
		return true
	return false


func move(to_position : Vector3) -> void:
	global_position = to_position
	_add_distance(last_position.distance_to(global_position))


func update_target(target_p : Vector3) -> void:
	last_position = global_position
	target_position = target_p
	force_raycast_update()


func gather_collision_info() -> Dictionary:
	var hit : Dictionary = {}
	if is_colliding():
		hit['col'] = get_collider()
		hit['col_point'] = get_collision_point()
		hit['col_normal'] = get_collision_normal()
		#print("Collision normal : %s, dot : %s" % [get_collision_normal(), velocity.normalized().dot(get_collision_normal())])
		hit['remainder'] = get_collision_point().distance_to(global_position + target_position)
	hit['end_position'] = hit.get("col_position", global_position + target_position)
	return hit


func _add_distance(distance : float) -> void:
	distance_traveled += distance


func get_travel_progress() -> float:
	if is_zero_approx(max_distance):
		return 1.0
	return distance_traveled / max_distance
