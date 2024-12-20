extends Component
class_name HealthComponent
signal HPisDead
signal onDamaged(dealer:Node3D,hitDirection:Vector3)
signal healthChanged
signal healthDepleted(dealer:Node3D)
signal killedWithDismemberingWeapon
@export_category("Component")
var lastDealer : Node3D = null
@export var health:float = 100
@export var isDead:bool = false

var componentOwner : Node3D
var killerSignalEmitted :bool= false

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	if is_instance_valid(get_owner()):
		componentOwner = get_owner()


func setHealth(value:float)->float:
	healthChanged.emit()
	health = value
	healthCheck()
	return health


func healthCheck()->void:
	if health <= 0 and is_instance_valid(self):
		await get_tree().process_frame
		setHealth(0)
		if lastDealer!=null and is_instance_valid(self) and is_instance_valid(lastDealer):
			healthDepleted.emit(lastDealer)
		else:
			if is_instance_valid(self):
				healthDepleted.emit(null)
		isDead = true
		HPisDead.emit()

func damage(amount:float, dealer:Node3D = null)->void:
	if is_instance_valid(self):
		lastDealer = dealer
		onDamaged.emit(dealer, Vector3.ZERO)
		setHealth(health - amount)

#func _on_health_depleted(dealer: Node3D) -> void:
	#print("Dealer is %s"%dealer)
	#lastDealer = dealer
	#if lastDealer != null:
		#if lastDealer.currentItem != null:
			#if lastDealer.currentItem.weaponResource.headDismember:
				#killedWithDismemberingWeapon.emit()
		#if !killerSignalEmitted:
			#if componentOwner is BasePawn:
				#lastDealer.emit_signal("killedPawn")
				#killerSignalEmitted = true
