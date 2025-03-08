@tool
extends Area3D
var dealer = null
var explosionTween : Tween
@onready var explosionEffect = $explosionEffect
@onready var explosionPlayer : AudioStreamPlayer3D = $explosionSound
@onready var collisionShape : CollisionShape3D = $collisionShape3d
@export_category("Explosion")
##Line of Sight, Will the explosion use line of sight checking to explode objects?
@export var explosionLOS : bool = true
##How fast will this explosion expand?
@export var explosionSpeed : float = 0.05
##Explosion sound... Will play when the explosion is activated
@export var explosionSound : AudioStream
##How much damage will this explosion do?
@export var explosionDamage : float = 50.0
##What is the physics impulse of this explosion?
@export var explosionImpulse : float = 50.0
##How large is the radius of this explosion?
@export_range(0.1,1000) var explosionRadius : float = 10.0:
	set(value):
		explosionRadius = value
		if is_instance_valid(collisionShape):
			collisionShape.shape.radius = explosionRadius

func _ready() -> void:
	if !Engine.is_editor_hint():
		collisionShape.shape.radius = 0.01


func explosionRayCheck(object:Node3D):
	if !explosionLOS:
		return
	var directSpace : PhysicsDirectSpaceState3D = gameManager.world.worldMisc.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.new()
	var result : Dictionary
	ray = ray.create(Vector3(global_position.x,global_position.y+1,global_position.z),object.global_position,collision_layer)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	result = directSpace.intersect_ray(ray)
	if result:
		if gameManager.debugEnabled:
			var meshInstance : MeshInstance3D = MeshInstance3D.new()
			var mesh = ImmediateMesh.new()
			var meshMat : StandardMaterial3D = StandardMaterial3D.new()
			meshMat.albedo_color = Color.BLUE
			gameManager.world.worldMisc.add_child(meshInstance)
			meshInstance.mesh = mesh
			mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			mesh.surface_add_vertex(position)
			mesh.surface_add_vertex(result.position)
			mesh.surface_end()
			meshInstance.material_override = meshMat
	return result


func applyHit(object:Node3D):
	if is_instance_valid(object) and object is not FakePhysicsEntity:
		var burnChance : bool = [true,false].pick_random()
		if burnChance and object is not FakePhysicsEntity:
			randomize()
			gameManager.burnTarget(object,randf_range(3,30),0.8)

		if object.has_method("velocity"):
			object.velocity += -(global_position-object.global_position).normalized() * explosionImpulse

		if object.has_method("hit"):
			if object is RagdollBone:
				object.canBleed = false
				object.set_meta("exploded",true)
			object.hit(explosionDamage,dealer,-(global_position-object.global_position).normalized() * explosionImpulse,Vector3.ZERO)

func explode()->void:
	collisionShape.shape.radius = 0.01
	if explosionTween:
		explosionTween.kill()
	explosionTween = create_tween()
	explosionTween.tween_property(collisionShape.shape,"radius",explosionRadius,explosionSpeed).finished.connect(collisionShape.queue_free)

	explosionEffect.doRipple(explosionRadius,explosionSpeed,2.5)


	if is_instance_valid(explosionEffect):
		explosionEffect.explosionEffectPlay()

	if is_instance_valid(explosionSound):
		explosionPlayer.reparent(gameManager.world.worldMisc)
		explosionPlayer.finished.connect(explosionPlayer.queue_free)
		explosionPlayer.stream = explosionSound
		explosionPlayer.play()
		if explosionPlayer.playing:
			await explosionPlayer.finished
		while explosionEffect.is_emitting():
			await get_tree().create_timer(1.0).timeout



func _on_body_entered(body: Node3D) -> void:
	if !explosionLOS:
		applyHit(body)
	else:
		var ray = explosionRayCheck(body)
		if ray:
			applyHit(body)
			#print(explosionRayCheck(body))


func _on_area_entered(area: Area3D) -> void:
	if !explosionLOS:
		applyHit(area)
	else:
		var ray = explosionRayCheck(area)
		if ray:
			applyHit(area)
