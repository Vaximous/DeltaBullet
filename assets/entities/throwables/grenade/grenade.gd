extends ThrowableBase
@export var explosionRadius : float = 65.0
@export var explosionImpulse :float  = 20.0

func createExplosion()->void:
	var explo : ExplosionArea = ExplosionArea.createExplosionArea(explosionRadius,throwableResource.throwableDamage,explosionImpulse,get_node_or_null(dealer.get_path()))
	gameManager.world.worldMisc.add_child(explo)
	explo.explosionFalloff = load("res://assets/resources/defaultExplosionCurve.tres")
	explo.global_position = global_position
	explo.doesBurn = false
	explo.explode()


func activateThrowable()->void:
	super()
	createExplosion()
	queue_free()


func _on_health_component_health_depleted(dealer: Node3D) -> void:
	if dealer is BasePawn and dealer.isPlayerPawn():
		activateThrowable()
