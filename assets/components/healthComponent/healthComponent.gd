extends Component
class_name HealthComponent
signal HPisDead
signal onDamaged(dealer:Node3D,hitDirection:Vector3)
signal healthChanged
signal healthDepleted(dealer:Node3D)
signal killedWithDismemberingWeapon
@export_category("Component")
var lastDealer : Node3D = null
@export var health:float = 100:
	set(value):
		healthChanged.emit()
		health = value
		if health <= 0:
			await get_tree().process_frame
			if lastDealer!=null:
				healthDepleted.emit(lastDealer)
			else:
				healthDepleted.emit(null)
			isDead = true
			#HPisDead.emit()
			#health = 0
	get:
		return health
@export var isDead:bool = false:
	set(value):
		isDead = value
		if isDead:
			HPisDead.emit()
var componentOwner : Node3D
var killerSignalEmitted :bool= false

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	componentOwner = get_owner()

func damage(amount:float, dealer:Node3D = null)->void:
	lastDealer = dealer
	onDamaged.emit(dealer, Vector3.ZERO)
	health = health - amount

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
