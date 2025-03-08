class_name ThrowableBase
extends RigidBody3D
signal onHit(impulse,vector)
signal thrown
var isThrown : bool = false:
	set(value):
		isThrown = value
		if value:
			fadeVisual()
var throwTween : Tween
var dealer : Node3D = null
@onready var countdownVisual : Marker3D = $countdown
@onready var countdownProgress : TextureProgressBar = $countdown/textureProgressBar
@export_category("Throwable")
@export var healthComponent : HealthComponent
@onready var collsionShape : CollisionShape3D = $collisionShape3d
@onready var throwableTimer : Timer = $throwableActivateTimer
var isActive : bool = false
## The throwable item resource
@export var throwableResource : ThrowableResource

func fadeVisual()->void:
	if throwableResource.countdownVisual:
		if throwTween:
			throwTween.kill()
		throwTween = create_tween()
		throwTween.parallel().tween_property(countdownProgress,"modulate",Color.TRANSPARENT,0.15)

func _ready() -> void:
	startThrowable()

func startThrowable()->void:
	if throwableResource.canCook:
		throwableTimer.wait_time = throwableResource.cookTime
		throwableTimer.start()
		if throwableResource.countdownVisual:
			if throwTween:
				throwTween.kill()
			throwTween = create_tween()
			countdownVisual.show()
			countdownProgress.value = 100
			throwTween.tween_property(countdownProgress,"value",0,throwableResource.cookTime)
			throwTween.parallel().tween_property(countdownProgress,"modulate",Color.DARK_RED,throwableResource.cookTime)

func activateThrowable()->void:
	pass


func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	onHit.emit(hitImpulse,hitPoint)
	apply_impulse(hitImpulse,hitPoint)
	if is_instance_valid(healthComponent):
		#print("dmg:%s"%int(dmg))
		#print("hp:%s"%healthComponent.health)
		healthComponent.damage(int(dmg),dealer)
