extends RigidBody3D
class_name PropRigidBody
signal onHit(hitImpulse,hitPoint)
@export_category("Prop RigidBody")
##If enabled, the prop will have an impulse applied when shot
@export var hitImpulseEnabled : bool = true
@export_subgroup("Prop")
@export var healthComponent : HealthComponent
@export var propMaterial:DB_PhysicsMaterial:
	set(value):
		propMaterial = value
		if is_instance_valid(propMaterial):
			setMaterial(propMaterial)
		else:
			setMaterial(load("res://assets/resources/PhysicsMaterials/generic_physics_material.tres"))

func setMaterial(resource:DB_PhysicsMaterial)->void:
	set_meta(&"physics_material_override", resource)

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	if hitImpulseEnabled:
		onHit.emit(hitImpulse,hitPoint)
		apply_impulse(hitImpulse, hitPoint)
	if is_instance_valid(healthComponent):
		healthComponent.damage(int(dmg),dealer)
