extends Node
const particles = {"BloodSpurt" : preload("res://assets/particles/bloodSpurt/bloodSpurt.tscn"),
					"BloodStream" : preload("res://assets/particles/bloodSpurt/bloodStream.tscn")
					}
const bulletHoles = {"Flesh": preload("res://assets/entities/bulletHoles/flesh/BulletHole_Flesh.tscn"),
"default":preload("res://assets/entities/bulletHoles/generic/BulletHoleGeneric.tscn") }

func detectMaterial(object:Object):
	if object:
		if object.is_in_group("Blood") or object.is_in_group("Flesh"):
			return "BloodSpurt"
	if object == null:
			return null

func createParticle(particle:String, pos:Vector3 = Vector3.ZERO, rot:Vector3 = Vector3.ZERO,parent:Node3D = null):
	if gameManager.world:
		if particle:
				var particleToCreate = particles[str(particle)].instantiate()
				if !parent:
					gameManager.world.worldParticles.add_child(particleToCreate)
				else:
					parent.add_child(particleToCreate)
				particleToCreate.global_position = pos
				particleToCreate.global_rotation = rot
				particleToCreate.emitting = true
				return particleToCreate


func spawnBulletHolePackedScene(scene : PackedScene, parent : Node, pos : Vector3 = Vector3.ONE, rot : float = 0.0, normal : Vector3 = Vector3.ONE,bulletVel : Vector3 = Vector3.ONE):
	if gameManager.world and parent != null:
		if scene != null:
			var bHole : BulletHole = scene.instantiate()
			bHole.normal = normal
			bHole.rot = rot
			bHole.colPoint = pos
			bHole.bulletVelocity = bulletVel
			parent.add_child(bHole)
			#bHole.global_position = pos

			#bHole.decal.rotate(normal,rot/PI)
			#if normal != Vector3.UP:
			#bHole.look_at(bHole.global_transform.origin + normal)
				#bHole.global_transform = bHole.global_transform.rotated_local(Vector3.RIGHT, PI/2.0)
			return bHole


func spawnBulletHole(hole:String,parent,pos:Vector3 = Vector3.ONE, rot:float = 0.0, normal:Vector3=Vector3.ONE ):
	if gameManager.world:
		var bHole = bulletHoles[str(hole)].instantiate()
		parent.add_child(bHole)
		bHole.global_position = pos
		bHole.rotate(normal,rot/PI)
		if normal != Vector3.UP:
			bHole.look_at(pos + normal, Vector3.UP)
			bHole.global_transform = bHole.global_transform.rotated_local(Vector3.RIGHT, PI/2.0)
		return bHole
