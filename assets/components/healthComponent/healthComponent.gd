extends Component
class_name HealthComponent
signal HPisDead
signal onDamaged(dealer:Node3D,hitDirection:Vector3)
signal healthChanged(value:float)
signal healthDepleted(dealer:Node3D)
signal killedWithDismemberingWeapon
@export_category("Component")
var lastDealer : Node3D = null
@export var health:float = 100
@export var isDead:bool = false
var defaultHP : float:
	set(value):
		defaultHP = value
		setHealth(value)

var componentOwner : Node3D
var killerSignalEmitted :bool= false

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	if is_instance_valid(get_owner()):
		componentOwner = get_owner()

func addHealth(value:float)->float:
	if is_instance_valid(self) and is_instance_valid(componentOwner):
		healthChanged.emit(value)
		health += value
		healthCheck()
	return health

func setHealth(value:float)->float:
	if is_instance_valid(self) and is_instance_valid(componentOwner):
		healthChanged.emit(value)
		health = value
		healthCheck()
		return health
	else:
		return 0.0

func healthCheck()->void:
	if health <= 0 and is_instance_valid(self):
		if has_meta(&"god"):
			if get_meta(&"god") == true:
				return
		if !isDead:
			isDead = true
			HPisDead.emit()
		if lastDealer!=null and is_instance_valid(self) and is_instance_valid(lastDealer):
			healthDepleted.emit(lastDealer)
		else:
			if is_instance_valid(self):
				healthDepleted.emit(null)

func damage(amount:float, dealer:Node3D = null,hitDirection:Vector3 = Vector3.ZERO)->void:
	if is_instance_valid(self) and is_instance_valid(componentOwner):
		if has_meta(&"god"):
			if get_meta(&"god") == true:
				return

		lastDealer = dealer
		onDamaged.emit(dealer, hitDirection)
		setHealth(health - amount)
