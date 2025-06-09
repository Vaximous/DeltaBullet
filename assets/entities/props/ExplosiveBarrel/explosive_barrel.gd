extends PropRigidBody
@export_category("Barrel")
var _dealer
var exploded : bool = false
##Will this barrel set things on fire when exploded?
@export var burnChance : bool = true
@export var explosionRadius : float = 7.0
@export var explosionImpulse :float  = 20


func burn()->void:
	if !has_meta("isBurning"):
		gameManager.burnTarget(self,100000,15)


func createExplosion(burnchance:bool=true)->void:
	if exploded: queue_free()
	exploded = true
	var explo : ExplosionArea = ExplosionArea.createExplosionArea(explosionRadius,90,explosionImpulse,null)
	gameManager.world.worldMisc.add_child(explo)
	explo.explosionFalloff = load("res://assets/resources/defaultExplosionCurve.tres")
	explo.global_position = global_position
	explo.doesBurn = burnchance
	explo.explosionLOS = false
	explo.explode()


func _on_health_component_health_depleted(dealer: Node3D) -> void:
	_dealer = dealer
	if !exploded:
		createExplosion(burnChance)
	queue_free()


func _on_hitbox_damaged(amount: Variant, impulse: Variant, vector: Variant, dealer: Variant) -> void:
	apply_impulse(impulse,vector)
	if !_dealer:
		_dealer = dealer
