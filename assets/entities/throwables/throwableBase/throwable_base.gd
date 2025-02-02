class_name ThrowableBase
extends RigidBody3D
@export_category("Throwable")
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
