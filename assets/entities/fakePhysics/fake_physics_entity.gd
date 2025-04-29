class_name FakePhysicsEntity
extends CharacterBody3D
signal bounced
@export_category("Fake Physics Entity")
@export var mesh : MeshInstance3D
@export var collisionSounds : Array[AudioStreamPlayer3D]
@export var continuousCollision : bool = false
var rotational_velocity : Vector3
var first_bounce = true
var colNormal : Vector3





func _ready() -> void:
	#gameManager.beginCleanup()
	rotational_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)) * 10.0

func playAudios()->void:
	for i in collisionSounds:
		i.play()

func _physics_process(delta: float) -> void:
	if mesh:
		mesh.rotation += rotational_velocity * delta
	velocity += get_gravity() * delta * 3
	#print(get_gravity())
	var col = move_and_collide(velocity * delta)
	if col is KinematicCollision3D:
		bounced.emit()
		colNormal = col.get_normal()
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
