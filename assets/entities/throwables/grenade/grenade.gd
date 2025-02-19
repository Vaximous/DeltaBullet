extends ThrowableBase
@export var explosionRadius : float = 65.0
@export var explosionImpulse :float  = 10.0

func createExplosion()->void:
	var explo = preload("res://assets/entities/explosion/explosionArea.tscn").instantiate()
	gameManager.world.worldMisc.add_child(explo)
	explo.explosionLOS = true
	explo.global_position = global_position
	explo.explosionRadius = explosionRadius
	explo.explosionImpulse = explosionImpulse
	explo.explosionDamage = throwableResource.throwableDamage
	explo.dealer = dealer
	explo.explode()


func activateThrowable()->void:
	super()
	createExplosion()
	queue_free()


func _on_health_component_health_depleted(dealer: Node3D) -> void:
	if dealer is BasePawn and dealer.isPlayerPawn():
		activateThrowable()
