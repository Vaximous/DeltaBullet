extends Area3D
class_name Hitbox
signal damagedFront
signal damagedBack
@export var crosshairHitEffect : bool = true
@export var enabled : bool = true
var setup:bool = false
signal damaged(amount,impulse,vector, dealer,bone)
@export_category("Hitbox")
@export var healthComponent : HealthComponent:
	set(value):
		healthComponent = value
		addException(self)
@export var hitboxDamageMult:float = 1.0
var boneId:int
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	if enabled:
		if is_instance_valid(healthComponent.componentOwner):
			if healthComponent.componentOwner is BasePawn:
				await healthComponent.componentOwner.ready
				healthComponent.componentOwner.hitboxes.append(self)
				set_meta(&"physics_material_override", preload("res://assets/resources/PhysicsMaterials/flesh_physics_material.tres"))
		if !get_parent() == null:
			if get_parent() is BoneAttachment3D:
				boneId = get_parent().get_bone_idx()



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta)->void:
	#if healthComponent:
		#if !setup:
			#addException(self)
			#setup = true

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO, bullet:Projectile = null)->void:
	if enabled:
		if healthComponent.componentOwner is BasePawn:
			healthComponent.componentOwner.lastHitPart = boneId
			healthComponent.componentOwner.hitImpulse = hitImpulse
			healthComponent.componentOwner.hitVector = hitPoint

			if bullet:
				if Vector3(bullet.global_position.x,0,bullet.global_position.z) < Vector3(healthComponent.componentOwner.pawnMesh.global_position.x,0,healthComponent.componentOwner.pawnMesh.global_position.z):
					#print("hit from front")
					damagedFront.emit()
				else:
					damagedBack.emit()
					#print("hit from back")

			if is_instance_valid(healthComponent.componentOwner.attachedCam) and crosshairHitEffect:
				healthComponent.componentOwner.attachedCam.camera.fov -= randf_range(1.8,4.8)
				healthComponent.componentOwner.attachedCam.fireRecoil(randf_range(0,1),randf_range(0,1),randf_range(2,5),true)
				healthComponent.componentOwner.attachedCam.fireVignette(1.2,Color.RED)

		if is_in_group("Flesh") and crosshairHitEffect:
			if dealer:
				if dealer.attachedCam:
					dealer.attachedCam.hud.getCrosshair().tintCrosshair(Color.RED)
					dealer.attachedCam.hud.getCrosshair().addTilt(randf_range(-1,1))
					dealer.attachedCam.camera.fov += 1.5

					#Dialogic.end_timeline()

		if dealer:
			damaged.emit(dmg,hitImpulse,hitPoint, dealer)
		else:
			damaged.emit(dmg,hitImpulse,hitPoint,null)
	if is_instance_valid(dealer):
		healthComponent.damage(dmg * hitboxDamageMult, dealer,hitImpulse)
	else:
		healthComponent.damage(dmg * hitboxDamageMult, null,hitImpulse)

func getCollisionObject()->CollisionObject3D:
	if get_child(0) is CollisionObject3D:
		return get_child(0)
	else:
		return null

func addException(exception)->void:
	if enabled:
		if is_in_group("Flesh"):
			if is_instance_valid(healthComponent.componentOwner):
				if healthComponent.componentOwner is BasePawn:
					if healthComponent.componentOwner.attachedCam:
						healthComponent.componentOwner.attachedCam.camCast.add_exception(exception)
					else:
						if healthComponent.componentOwner.raycaster:
							healthComponent.componentOwner.raycaster.add_exception(exception)
