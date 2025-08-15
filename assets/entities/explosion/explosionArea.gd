@tool
class_name ExplosionArea
extends Area3D
var dealer = null
var explosionTween : Tween
const explosion : PackedScene = preload("res://assets/entities/explosion/explosionArea.tscn")
@onready var explosionEffect = $explosionEffect
@onready var explosionPlayer : AudioStreamPlayer3D = $explosionSound
@onready var collisionShape : CollisionShape3D = $collisionShape3d
@onready var shakerArea : Area3D = %shakerArea
@export_category("Explosion")
##Does this explosion burn objects?
@export var doesBurn : bool = true
##Line of Sight, Will the explosion use line of sight checking to explode objects?
@export var explosionLOS : bool = true
##How fast will this explosion expand?
@export var explosionSpeed : float = 0.08
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
@export var explosionFalloff : Curve


static func createExplosionArea(radius : float = 10,dmg : float = 50, impulse:float = 10,dealer:Node3D = null,losEnabled:bool = true,falloff:Curve = load("res://assets/resources/defaultExplosionCurve.tres")):
	var _explosion : Area3D = explosion.instantiate()
	_explosion.explosionRadius = radius
	_explosion.explosionDamage = dmg
	_explosion.explosionImpulse = impulse
	_explosion.explosionFalloff = falloff
	_explosion.explosionLOS = losEnabled
	if is_instance_valid(dealer):
		_explosion.dealer = dealer
	else:
		_explosion.dealer = null
	return _explosion

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
	if is_instance_valid(object) and object is not FakePhysicsEntity and object is not BloodDroplet and object is not Projectile:
		var distance : float = global_position.distance_to(object.global_position)
		var dmgAmnt: float = lerpf(2,explosionDamage,distance/explosionRadius*2)
		var dmgClamped : float = clampf(dmgAmnt,2,dmgAmnt)
		var burnChance : bool = [true,false].pick_random()
		if burnChance and object is not FakePhysicsEntity and doesBurn:
			randomize()
			gameManager.burnTarget(object,randf_range(3,30),0.8)

		if object.has_method("velocity"):
			object.velocity += -(global_position-object.global_position).normalized() * explosionImpulse

		if object.has_method("hit"):
			if object is RagdollBone:
				object.canBleed = false
				if object.get_bone_id() == 42:
					object.ragdoll.doRagdollHeadshot(null,true,Vector3.ONE,Vector3.ZERO,false)
				#object.set_meta("exploded",true)
			#print(dmgClamped)
			object.hit(dmgClamped*randf_range(1.1,1.8),null,-(global_position-object.global_position).normalized() * explosionImpulse * randf_range(1.3,1.8),Vector3.ZERO)

func explode()->void:
	var explosionRadiusTo = explosionRadius
	%shakerCollider.shape.radius = explosionRadiusTo*2.7

	if explosionTween:
		explosionTween.kill()
	explosionTween = create_tween()
	explosionRadius = 0.1
	explosionTween.tween_property(self,"explosionRadius",explosionRadiusTo,explosionSpeed)

	explosionEffect.doRipple(explosionRadiusTo*4,0.25,0.5).finished.connect(collisionShape.queue_free)
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
		await get_tree().create_timer(0.05).timeout
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body is FakePhysicsEntity or body is BloodDroplet or body is Projectile:
		body.queue_free()

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


func _on_shaker_area_body_entered(body: Node3D) -> void:
	if body is BasePawn:
		var distance = global_position.distance_to(body.global_position + Vector3.DOWN * 1.2) / %shakerCollider.shape.radius
		if body.isPlayerPawn() and is_instance_valid(body.attachedCam):
			%cameraShakerComponent.shakeCam(distance,body.attachedCam,global_position.direction_to(body.attachedCam.camera.global_position))


func _on_timer_timeout() -> void:
	%shakerArea.monitoring = false
