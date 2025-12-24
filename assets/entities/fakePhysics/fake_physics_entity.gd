class_name FakePhysicsEntity
extends CharacterBody3D
signal bounced(p,norm)
var tween : Tween
@export_category("Fake Physics Entity")
@export var mesh : MeshInstance3D
@export var impact_particles : Array[GPUParticles3D]
@export var collisionSounds : Array[AudioStreamPlayer3D]
@export var continuousCollision : bool = false
var decalTimer: float = 0.5
var rotational_velocity : Vector3
var first_bounce = true
var colNormal : Vector3
var alive : bool = false:
	set(value):
		alive = value
		if alive:
			process_mode = Node.PROCESS_MODE_INHERIT
			PoolingManager.active_entities.append(self)
		else:
			process_mode = Node.PROCESS_MODE_DISABLED
			PoolingManager.active_entities.erase(self)

func _enter_tree() -> void:
	set_physics_process(false)
	set_process(false)
	await get_tree().process_frame
	#gameManager.registerPhysicsEntity(self)
	rotation = Vector3(randf_range(-360, 360), randf_range(-360, 360), randf_range(-360, 360))
	get_tree().create_timer(UserConfig.game_decal_remove_time).timeout.connect(remove_entity)

func playImpactParticles()->void:
	for i in impact_particles:
		if is_instance_valid(i):
			i.restart()

func _exit_tree() -> void:
	if PoolingManager.active_entities.has(self):
		PoolingManager.active_entities.erase(self)

func _ready() -> void:
	#gameManager.beginCleanup()
	alive = false
	if mesh:
		mesh.transparency = 0
		mesh.show()
		#fadeInMesh()
		mesh.position = global_position
		#mesh.global_transform = self.get_global_transform_interpolated()
		mesh.top_level = true
	rotational_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)) * 10.0

func reset(pposition: Vector3, vel: Vector3):
	decalTimer = 0.5
	rotational_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)) * 10.0
	get_tree().create_timer(UserConfig.game_decal_remove_time).timeout.connect(remove_entity)
	global_position = pposition
	velocity = vel
	alive = true
	rotation = Vector3(randf_range(-360, 360), randf_range(-360, 360), randf_range(-360, 360))
	show()

func playAudios()->void:
	for i in collisionSounds:
		i.play()

func process_entity(delta: float) -> void:
	if not alive:
		return

	if Engine.get_physics_frames() % 2 == 0:
		if mesh:
			mesh.position = global_position
			mesh.rotation += rotational_velocity * delta
		velocity += get_gravity() * delta * 3
		#print(get_gravity())

		if decalTimer > 0:
			decalTimer -= delta
		if decalTimer <= 0:
			decalTimer = 0

		var col = move_and_collide(velocity * delta)
		if col is KinematicCollision3D:
			colNormal = col.get_normal()
			playImpactParticles()
			bounced.emit(global_position,colNormal)
			decalTimer = 0.5
			if first_bounce and !continuousCollision:
				playAudios()
				first_bounce = false
			elif continuousCollision:
				playAudios()
			velocity = velocity.bounce(col.get_normal())
			velocity += (rotational_velocity.bounce(col.get_normal()) * 0.25)
			velocity *= 0.35
			rotational_velocity *= randf_range(0.5, 1.2)
			if velocity.length() < 1.0:
				alive = false
				set_physics_process(false)
				#print("Stap")

		if is_instance_valid(mesh):
			if tween:
				tween.kill()
			tween = create_tween()
			tween.parallel().tween_method(meshInterpRot,mesh.rotation,rotational_velocity * delta,0.05).set_trans(Tween.TRANS_LINEAR)
			tween.parallel().tween_method(meshInterpPos,mesh.position,global_position,0.05).set_trans(Tween.TRANS_LINEAR)

func meshInterpRot(rot:Vector3)->void:
	if mesh:
		mesh.rotation = rot

func meshInterpPos(pos:Vector3)->void:
	if mesh:
		mesh.position = pos

func remove_entity()->void:
	alive = false
	hide()
	set_physics_process(false)

func set_gib_mesh(_mesh:Mesh)->void:
	if mesh:
		mesh.mesh = _mesh

func fadeInMesh()->void:
	mesh.transparency = 1
	var _tween : Tween
	_tween = create_tween()
	_tween.tween_property(mesh,"transparency",0,1.25).set_trans(Tween.TRANS_LINEAR).set_ease(gameManager.defaultEaseType)
