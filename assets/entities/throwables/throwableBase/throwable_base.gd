class_name ThrowableBase
extends RigidBody3D
signal onHit(impulse,vector)
var dealer : Node3D = null
@export_category("Throwable")
@export var healthComponent : HealthComponent
@onready var collsionShape : CollisionShape3D = $collisionShape3d
@onready var throwableTimer : Timer = $throwableActivateTimer
var isActive : bool = false
## The throwable item resource
@export var throwableResource : ThrowableResource

func _ready() -> void:
	startThrowable()

func startThrowable()->void:
	if throwableResource.canCook:
		throwableTimer.wait_time = throwableResource.cookTime
		throwableTimer.start()

func activateThrowable()->void:
	pass

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	onHit.emit(hitImpulse,hitPoint)
	apply_impulse(hitImpulse,hitPoint)
	if is_instance_valid(healthComponent):
		#print("dmg:%s"%int(dmg))
		#print("hp:%s"%healthComponent.health)
		healthComponent.damage(int(dmg),dealer)
