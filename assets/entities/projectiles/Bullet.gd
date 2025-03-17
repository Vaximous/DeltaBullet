extends Projectile

var max_damage : float
@export var falloff : Curve = preload("res://assets/entities/projectiles/linear_falloff_curve.tres")
@export var penetration_power : float = 1.0:
	set(value):
		penetration_power = max(0.1, value)
var inside_material : DB_PhysicsMaterial
var last_hit_data : Dictionary

func set_projectile_owner(value : Node) -> void:
	if value is Weapon:
		max_damage = value.weaponResource.weaponDamage
		penetration_power = value.weaponResource.bulletPenetration
		falloff = value.weaponResource.damageFalloff
	projectile_owner = value

func _ready() -> void:
	hit_back_faces = false

func _physics_process(delta: float) -> void:
	var hit_data = step(velocity * delta)

	while hit_data.has("col"):
		var col : Object = hit_data['col']
		#print(col)
		var col_point : Vector3 = hit_data['col_point']
		var col_normal : Vector3 = hit_data['col_normal']
		var remainder : float = hit_data['remainder']
		last_hit_data = hit_data

		var collision_material : DB_PhysicsMaterial = gameManager.getColliderPhysicsMaterial(col)
		if collision_material != inside_material:
			enter_material(collision_material, hit_data)
		else:
			exit_material(hit_data)
		#tiny step to move past the collider
		global_position += velocity.normalized()
		hit_data = step(velocity.normalized() * remainder)

func enter_material(material : DB_PhysicsMaterial, hit_data : Dictionary) -> void:
	#print(">> Entered material %s" % material)
	inside_material = material
	#print(material)
	globalParticles.spawnBulletHolePackedScene(material.bullet_hole, hit_data['col'], hit_data['col_point'], randf_range(0, TAU), hit_data['col_normal'],hit_data['velocity'])
	var col : Object = hit_data['col']
	get_damage()
	if col.has_method(&"hit"):
		if is_instance_valid(projectile_owner):
			if projectile_owner is Weapon:
				col.hit(get_damage(),projectile_owner.weaponOwner,velocity.normalized() * (falloff.sample(get_travel_progress()*3) * projectile_owner.weaponResource.weaponImpulse),to_global(to_local(hit_data['col_point'])-position))
		else:
			return
	if penetration_power > 0:
		#var hit = gather_collision_info()
		#if hit:
			#var trail = preload("res://assets/entities/bulletTrail/bulletTrail.tscn").instantiate()
			#gameManager.world.worldMisc.add_child(trail)
			#trail.initTrail(global_position,velocity)
			#globalParticles.spawnBulletHolePackedScene(material.bullet_hole, hit['col'], velocity, randf_range(0, TAU), hit['col_normal'],hit['velocity'])
		distance_traveled += (material.penetration_entry_cost / penetration_power)
		#print("Power reduction = %s" % [material.penetration_entry_cost / penetration_power])
	else:
		distance_traveled = max_distance
	expire_by_distance()

func exit_material(hit_data : Dictionary) -> void:
	if expire_by_distance():
		return
	#print("<< Exited material %s" % inside_material)
	globalParticles.spawnBulletHolePackedScene(inside_material.bullet_hole, hit_data['col'], hit_data['col_point'], randf_range(0, TAU), -last_hit_data['col_normal'])
	inside_material = null

func _add_distance(distance : float) -> void:
	if inside_material:
		distance *= (1.0 + (inside_material.penetration_resistance / penetration_power))
		#print("distance increased!!! %s, %s" % [distance_traveled, distance])
	distance_traveled += distance

func get_damage() -> float:
	var _falloff = falloff.sample(get_travel_progress()*3) * max_damage
	#print("Falloff damage : %s (travel : %s)" % [_falloff, get_travel_progress()])
	return _falloff


func _on_flyby_area_body_entered(body: Node3D) -> void:
	if body is BasePawn:
		if body.isPlayerPawn():
			if !%flybySound.playing:
				%flybySound.play()
