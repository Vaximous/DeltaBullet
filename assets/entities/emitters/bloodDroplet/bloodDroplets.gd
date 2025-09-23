extends CharacterBody3D
class_name BloodDroplet
@onready var mesh:MeshInstance3D = %bloodMesh
const framesRecalculation : int = 5
var framesSinceRecalc : int = 0
var meshDraw = ImmediateMesh.new()
var tween : Tween
var alive : bool = false:
	set(value):
		alive = value
		set_physics_process(value)
var norm : Vector3 = Vector3.UP
var params : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()

func _ready() -> void:
	#gameManager.registerPhysicsEntity(self)
	if mesh:
		var dup = mesh.mesh.duplicate()
		mesh.mesh = mesh.mesh.duplicate()

func reset(position: Vector3, vel: Vector3, n: Vector3):
	global_position = position
	velocity = vel
	norm = n
	alive = true

func _physics_process(delta: float) -> void:
	if not alive:
		return


	global_position  += velocity * delta
	velocity += get_gravity() * delta * 10

	if mesh:
		mesh.position = global_position
		mesh.mesh.size.x = velocity.length() * 0.008
		mesh.look_at(global_position + velocity,norm,true)
		mesh.global_position = global_position

	params.from = global_position
	params.to = global_position + velocity * delta
	params.collide_with_areas = false
	params.collision_mask = collision_mask

	var space = get_world_3d().direct_space_state
	var hit = space.intersect_ray(params)
	if hit:
		gameManager.createSplat(hit.position, hit.normal)
		alive = false
		hide()
	#OLD DROPLET

	#var col
	#if Engine.get_physics_frames() % 2 == 0:
		#col = move_and_collide((velocity * randf_range(0.25,0.35)) * delta)
		#velocity += get_gravity() * delta * 16
		##var tgt = mesh.transform.looking_at(mesh.transform.origin - velocity, Vector3.MODEL_TOP)
		##tween.parallel().tween_method(meshInterpRot,mesh.rotation,velocity * Vector3.DOWN,0.05).set_trans(Tween.TRANS_LINEAR)
		##updateLine(delta)
		##%bloodMesh.look_at(velocity * Vector3.FORWARD)
		#if col is KinematicCollision3D:
			##print(col.get_collider())
			#gameManager.createSplat(col.get_position(),col.get_normal())
			#var audio : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			#gameManager.world.worldMisc.add_child(audio)
			#audio.global_position = global_position
			#audio.stream = load("res://assets/entities/emitters/bloodDroplet/dropletStream.tres")
			#audio.finished.connect(audio.queue_free)
			#audio.attenuation_filter_cutoff_hz = 20500
			#audio.volume_db = -15
			#audio.max_distance = 0.5
			#audio.bus = &"Sounds"
			#audio.play()
			#%bloodSpurt.finished.connect(%bloodSpurt.queue_free)
			#%bloodSpurt.restart()
			#%bloodSpurt.reparent(gameManager.world.worldParticles)
			#queue_free()
#
#
		#if tween:
			#tween.kill()
		#tween = create_tween()
		#tween.parallel().tween_method(meshInterpPos,mesh.position,global_position,0.05).set_trans(Tween.TRANS_LINEAR)


func meshInterpRot(rot:Vector3)->void:
	if mesh:
		mesh.rotation = rot

func meshInterpPos(pos:Vector3)->void:
	if mesh:
		mesh.position = pos
