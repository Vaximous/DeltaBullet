class_name FakePhysicsEntity
extends CharacterBody3D
signal bounced
var tween : Tween
@export_category("Fake Physics Entity")
@export var mesh : MeshInstance3D
@export var collisionSounds : Array[AudioStreamPlayer3D]
@export var continuousCollision : bool = false
var rotational_velocity : Vector3
var first_bounce = true
var colNormal : Vector3

func _enter_tree() -> void:
	await get_tree().process_frame
	gameManager.registerPhysicsEntity(self)

func _ready() -> void:
	#gameManager.beginCleanup()
	if mesh:
		mesh.transparency = 0
		mesh.show()
		#fadeInMesh()
		mesh.position = global_position
		#mesh.global_transform = self.get_global_transform_interpolated()
		mesh.top_level = true
	rotational_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)) * 10.0

func playAudios()->void:
	for i in collisionSounds:
		i.play()

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 2 == 0:
		if mesh:
			mesh.position = global_position
			mesh.rotation += rotational_velocity * delta
		velocity += get_gravity() * delta * 3
		#print(get_gravity())
		var col = move_and_collide(velocity * delta)
		if col is KinematicCollision3D:
			colNormal = col.get_normal()
			bounced.emit()
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
				set_physics_process(false)
				#print("Stap")

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

func fadeInMesh()->void:
	mesh.transparency = 1
	var _tween : Tween
	_tween = create_tween()
	_tween.tween_property(mesh,"transparency",0,1.25).set_trans(Tween.TRANS_LINEAR).set_ease(gameManager.defaultEaseType)
