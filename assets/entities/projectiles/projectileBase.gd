class_name Projectile
extends RayCast3D

@export var max_distance: float = 100.0

var active : bool = false:
	set(value):
		active = value
		set_process(active)
		set_physics_process(active)
		#if active:
			#process_mode = Node.PROCESS_MODE_PAUSABLE
		#else:
			#process_mode = Node.PROCESS_MODE_DISABLED

var max_damage: float
var velocity: Vector3
var distance_traveled: float
var projectile_owner: Weapon:
	set = set_projectile_owner
var last_position: Vector3

func disable()->void:
	process_mode = Node.PROCESS_MODE_DISABLED
	active = false
	hide()
	velocity = Vector3.ONE
	clear_exceptions()
	if !is_inside_tree() : return
	#global_position = Vector3.ZERO


func reset(pposition: Vector3, vel: Vector3):
	#if !is_inside_tree() : return
	distance_traveled = 0

	active = true
	clear_exceptions()
	velocity = vel
	global_position = pposition
	show()
	process_mode = Node.PROCESS_MODE_INHERIT


func _physics_process(delta: float) -> void:
	if !active: return

	step(velocity * delta)


func set_projectile_owner(value: Weapon) -> void:
	projectile_owner = value
	if value.weaponOwner is BasePawn:
		if value.weaponOwner.isPlayerPawn():
			set_meta("isPlayerBullet", true)
		else:
			set_meta("isPlayerBullet", false)


func step(movement: Vector3) -> Dictionary:
	if active:
		update_target(movement)
		var hit: Dictionary = gather_collision_info()
		move(hit['end_position'])
		expire_by_distance()
		return hit
	else: return {}


func expire_by_distance() -> bool:
	if distance_traveled >= max_distance:
		velocity = Vector3.ZERO
		disable()
		return true
	return false


func move(to_position: Vector3) -> void:
	if !active: return
	global_position = to_position
	_add_distance(last_position.distance_to(global_position))


func update_target(target_p: Vector3) -> void:
	if !active: return
	last_position = global_position
	target_position = target_p
	force_raycast_update()


func gather_collision_info() -> Dictionary:
	var hit: Dictionary = {}
	if is_colliding():
		hit['velocity'] = velocity
		hit['col'] = get_collider()
		hit['col_point'] = get_collision_point()
		hit['col_normal'] = get_collision_normal()
		#print("Collision normal : %s, dot : %s" % [get_collision_normal(), velocity.normalized().dot(get_collision_normal())])
		hit['remainder'] = get_collision_point().distance_to(global_position + target_position)
	hit['end_position'] = hit.get("col_position", global_position + target_position)
	return hit


func get_travel_progress() -> float:
	if is_zero_approx(max_distance):
		return 1.0
	return distance_traveled / max_distance


func _add_distance(distance: float) -> void:
	distance_traveled += distance
