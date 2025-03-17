extends PropRigidBody
@export_category("Barrel")
var _dealer
##Will this barrel set things on fire when exploded?
@export var burnChance : bool = true
@export var explosionRadius : float = 7.0
@export var explosionImpulse :float  = 35.0


func burn()->void:
	if !get_meta("isBurning") or !has_meta("isBurning"):
		gameManager.burnTarget(self,100000,15)


func createExplosion(burnchance:bool=true)->void:
	var explo = preload("res://assets/entities/explosion/explosionArea.tscn").instantiate()
	gameManager.world.worldMisc.add_child(explo)
	explo.doesBurn = burnchance
	explo.explosionLOS = true
	explo.global_position = global_position
	explo.explosionRadius = explosionRadius
	explo.explosionImpulse = explosionImpulse
	explo.dealer = _dealer
	explo.explode()


func _on_health_component_health_depleted(dealer: Node3D) -> void:
	_dealer = dealer
	createExplosion(burnChance)
	queue_free()


func _on_hitbox_damaged(amount: Variant, impulse: Variant, vector: Variant, dealer: Variant) -> void:
	apply_impulse(impulse,vector)
	if !_dealer:
		_dealer = dealer
