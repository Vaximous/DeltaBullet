extends CharacterBody3D



@onready var mesh : MeshInstance3D = $meshInstance3d
var rotational_velocity : Vector3
var first_bounce = true


func _ready() -> void:
	rotational_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)) * 10.0


func _physics_process(delta: float) -> void:
	mesh.rotation += rotational_velocity * delta
	velocity += get_gravity() * delta * 3
	print(get_gravity())
	var col = move_and_collide(velocity * delta)
	if col is KinematicCollision3D:
		if first_bounce:
			$audioStreamPlayer3d.play()
			first_bounce = false
		velocity = velocity.bounce(col.get_normal())
		velocity += (rotational_velocity.bounce(col.get_normal()) * 0.25)
		velocity *= 0.35
		rotational_velocity *= randf_range(0.5, 1.2)
		if velocity.length() < 1.0:
			set_physics_process(false)
			print("Stap")
