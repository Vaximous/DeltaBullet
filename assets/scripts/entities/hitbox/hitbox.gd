extends Area3D
class_name Hitbox
var setup:bool = false
signal damaged(amount,impulse,vector, dealer)
@export_category("Hitbox")
@export var healthComponent : HealthComponent:
	set(value):
		healthComponent = value
		addException(self)
@export var hitboxDamageMult:float = 1.0
var boneId:int
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	if healthComponent.componentOwner != null:
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

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	if healthComponent.componentOwner is BasePawn:
		healthComponent.componentOwner.lastHitPart = boneId
		healthComponent.componentOwner.hitImpulse = hitImpulse
		healthComponent.componentOwner.hitVector = hitPoint

	if is_in_group("Flesh"):
		if dealer:
			if dealer.attachedCam:
				dealer.attachedCam.hud.getCrosshair().tintCrosshair(Color.RED)
				dealer.attachedCam.hud.getCrosshair().addTilt(randf_range(-1,1))
				dealer.attachedCam.camera.fov += 1.5
		#if hitImpulse:
			#var rayTest = RayCast3D.new()
			#gameManager.world.worldMisc.add_child(rayTest)
			#rayTest.global_position = hitPoint
			#rayTest.target_position = hitImpulse/10
			#await get_tree().process_frame
			#if rayTest.is_colliding():
				#var normal = rayTest.get_collision_normal()
				#var colPoint = rayTest.get_collision_point()
				##Create Splatter
				#if normal != Vector3.UP:
					#var splatter = preload("res://assets/entities/bloodSplat/bloodSplat1.tscn")
					#var splatterInstance = splatter.instantiate()
					#gameManager.world.worldMisc.add_child(splatterInstance)
					#splatterInstance.global_position = rayTest.get_collision_point()
					##print("blood landed on wall")
					#splatterInstance.rotation_degrees.z = randf_range(-180,180)
					#splatterInstance.look_at(colPoint-normal,Vector3(0,1,0))
				#rayTest.queue_free()
			#else:
				#rayTest.queue_free()

	if healthComponent.componentOwner:
		if healthComponent.componentOwner is BasePawn:
			if healthComponent.componentOwner.attachedCam != null:
				healthComponent.componentOwner.attachedCam.camera.fov -= randf_range(1.8,4.8)
				healthComponent.componentOwner.attachedCam.fireRecoil(randf_range(8,14),randf_range(1,4),randf_range(9,13),true)
				healthComponent.componentOwner.attachedCam.fireVignette(1.2,Color.RED)
				Dialogic.end_timeline()

	if dealer:
		emit_signal("damaged",dmg,hitImpulse,hitPoint, dealer)
	else:
		damaged.emit(dmg,hitImpulse,hitPoint,null)

	healthComponent.onDamaged.emit(dealer,hitImpulse)
	healthComponent.damage(dmg * hitboxDamageMult, dealer)



func getCollisionObject():
	if get_child(0) is CollisionObject3D:
		return get_child(0)
	else:
		return null

func addException(exception)->void:
	if is_in_group("Flesh"):
		if healthComponent.componentOwner:
			if healthComponent.componentOwner.attachedCam:
				healthComponent.componentOwner.attachedCam.camCast.add_exception(exception)
			else:
				if healthComponent.componentOwner.raycaster:
					healthComponent.componentOwner.raycaster.add_exception(exception)
