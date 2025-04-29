extends CharacterBody3D
class_name BloodDroplet
const framesRecalculation : int = 2
var framesSinceRecalc : int = 0
var meshDraw = ImmediateMesh.new()

func _ready() -> void:
	get_tree().create_timer(2.5).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	var col
	if framesSinceRecalc >= framesRecalculation:
		col = move_and_collide(velocity * delta)
		velocity += get_gravity() * delta * 16
		#updateLine(delta)
		%bloodMesh.rotate_z(velocity.y)
		%bloodMesh.global_position = self.global_position
		if col is KinematicCollision3D:
			#print(col.get_collider())
			gameManager.createSplat(col.get_position(),col.get_normal())
			var audio : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			gameManager.world.worldMisc.add_child(audio)
			audio.global_position = global_position
			audio.stream = load("res://assets/entities/emitters/bloodDroplet/dropletStream.tres")
			audio.finished.connect(audio.queue_free)
			audio.attenuation_filter_cutoff_hz = 20500
			audio.volume_db = -15
			audio.max_distance = 0.5
			audio.bus = &"Sounds"
			audio.play()
			queue_free()
		framesSinceRecalc = 0
	else:
		framesSinceRecalc += 1
