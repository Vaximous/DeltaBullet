extends CharacterBody3D
class_name BloodDroplet
const framesRecalculation : int = 2
var framesSinceRecalc : int = 0


func _physics_process(delta: float) -> void:
	var col
	if framesSinceRecalc >= framesRecalculation:
		col = move_and_collide(velocity * delta)
		velocity += get_gravity() * delta * 16
		if col is KinematicCollision3D:
			#print(col.get_collider())
			gameManager.createSplat(col.get_position(),col.get_normal())
			queue_free()

		framesSinceRecalc = 0
	else:
		framesSinceRecalc += 1


func _ready()->void:
	get_tree().create_timer(2.5).timeout.connect(queue_free)
	pass
