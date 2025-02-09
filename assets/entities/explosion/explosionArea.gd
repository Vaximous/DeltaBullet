@tool
extends Area3D
var dealer = null
var explosionTween : Tween
@onready var explosionEffect = $explosionEffect
@onready var explosionPlayer : AudioStreamPlayer3D = $explosionSound
@onready var collisionShape : CollisionShape3D = $collisionShape3d
@export_category("Explosion")
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

func applyHit(object:Node3D):
	if is_instance_valid(object) and !object is FakePhysicsEntity:
		var burnChance : bool = [true,false].pick_random()
		if burnChance:
			randomize()
			gameManager.burnTarget(object,randf_range(3,30),0.8)

		if object.has_method("velocity"):
			object.velocity += -(global_position-object.global_position).normalized() * explosionImpulse

		if object.has_method("hit"):
			object.hit(explosionDamage,dealer,-(global_position-object.global_position).normalized() * explosionImpulse,Vector3.ZERO)

func explode()->void:
	collisionShape.shape.radius = 0
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



	#await get_tree().process_frame
	#await get_tree().process_frame
	#collisionShape.disabled = true

func _on_body_entered(body: Node3D) -> void:
	#print("Bodies:%s" %get_overlapping_bodies())
	applyHit(body)

func _on_area_entered(area: Area3D) -> void:
	#print("Areas:%s" %get_overlapping_areas())
	applyHit(area)
