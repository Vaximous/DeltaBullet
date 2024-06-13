extends Component
class_name HealthComponent
signal onDamaged(dealer,hitDirection)
signal healthChanged
signal healthDepleted(dealer:Node3D)
signal killedWithDismemberingWeapon
@export_category("Component")
var lastDealer
@export var health:float = 100:
	set(value):
		health = value
		emit_signal("healthChanged")
	get:
		return health
@export var isDead:bool = false
var componentOwner
var killerSignalEmitted :bool= false

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	componentOwner = get_owner()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta)->void:
	if !isDead:
		if health <= 0:
			health = 0
			emit_signal("healthDepleted",lastDealer)
			isDead = true
			if lastDealer != null:
				if lastDealer.currentItem != null:
					if lastDealer.currentItem.weaponResource.headDismember:
						killedWithDismemberingWeapon.emit()
				if !killerSignalEmitted:
					if componentOwner is BasePawn:
						lastDealer.emit_signal("killedPawn")
						killerSignalEmitted = true

func damage(amount, dealer:Node3D = null)->void:
	emit_signal("onDamaged",dealer)
	health = health - amount
	lastDealer = dealer


