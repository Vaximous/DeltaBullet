extends ThrowableBase
var exploded : bool = false
@export var explosionRadius : float = 65.0
@export var explosionImpulse :float  = 10.0

func createExplosion()->void:
	if exploded: queue_free()
	exploded = true
	var explo : ExplosionArea
	if dealer:
		explo = ExplosionArea.createExplosionArea(explosionRadius,throwableResource.throwableDamage,explosionImpulse,dealer)
	else:
		explo = ExplosionArea.createExplosionArea(explosionRadius,throwableResource.throwableDamage,explosionImpulse,null)
	gameManager.world.worldMisc.add_child(explo)
	explo.explosionFalloff = load("res://assets/resources/defaultExplosionCurve.tres")
	explo.global_position = global_position
	explo.doesBurn = false
	explo.explosionLOS = false
	explo.explode()
	if dealer:
		if dealer is BasePawn and !dealer.isPawnDead:
			dealer.resetThrowables()



func activateThrowable()->void:
	super()
	if !exploded:
		createExplosion()
	queue_free()


func _on_health_component_health_depleted(_dealer: Node3D) -> void:
	if _dealer is BasePawn and dealer.isPlayerPawn() and is_instance_valid(dealer):
		activateThrowable()
