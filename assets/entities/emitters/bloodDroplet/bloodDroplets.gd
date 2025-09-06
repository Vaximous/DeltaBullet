extends CharacterBody3D
class_name BloodDroplet
@onready var mesh:MeshInstance3D = %bloodMesh
const framesRecalculation : int = 5
var framesSinceRecalc : int = 0
var meshDraw = ImmediateMesh.new()
var tween : Tween

func _ready() -> void:
	get_tree().create_timer(2.5).timeout.connect(queue_free)
	%bloodMesh.global_position = self.global_position


func _physics_process(delta: float) -> void:
	var col
	if tween:
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_method(meshInterpPos,mesh.global_position,global_position,0.02).set_trans(Tween.TRANS_LINEAR)
	mesh.look_at(velocity,Vector3.UP,true)
	if framesSinceRecalc >= framesRecalculation:
		col = move_and_collide(velocity * delta)
		velocity += get_gravity() * delta * 16
		#var tgt = mesh.transform.looking_at(mesh.transform.origin - velocity, Vector3.MODEL_TOP)
		#tween.parallel().tween_method(meshInterpRot,mesh.rotation,velocity * Vector3.DOWN,0.05).set_trans(Tween.TRANS_LINEAR)
		#updateLine(delta)
		#%bloodMesh.look_at(velocity * Vector3.FORWARD)
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

func meshInterpRot(rot:Vector3)->void:
	if mesh:
		mesh.rotation = rot

func meshInterpPos(pos:Vector3)->void:
	if mesh:
		mesh.position = pos
