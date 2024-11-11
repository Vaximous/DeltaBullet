extends InteractiveObject
class_name Weapon

@onready var collisionObject : CollisionShape3D = $collisionObject
@onready var animationTree : AnimationTree = $AnimationTree
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
var weaponCast : RayCast3D
var weaponCastEnd
var weaponState
var leftArmSpeed = 16
var weaponRemoteState : AnimationNodeStateMachinePlayback
var weaponRemoteStateLeft : AnimationNodeStateMachinePlayback
var weaponAnimSet : bool = false
var weaponOwner : BasePawn = null:
	set(value):
		weaponOwner = value
var canReloadWeapon = false
var currentMagSize = 0:
	set(value):
		currentMagSize = value
		if currentMagSize <= 0:
			currentMagSize = 0
			canReloadWeapon = false
		else:
			if currentAmmo < weaponResource.ammoSize:
				canReloadWeapon = true
			else:
				canReloadWeapon = false
var currentAmmo = 0:
	set(value):
		currentAmmo = max(value, 0)
		if currentAmmo < weaponResource.ammoSize:
			if currentMagSize >= 1:
				canReloadWeapon = true
		if currentAmmo >= weaponResource.ammoSize:
			if currentMagSize >= 1:
				canReloadWeapon = false
@export_category("Weapon")
@export var weaponMesh : Node3D
@export var weaponResource : ItemData:
	set(value):
		weaponResource = value
		currentAmmo = weaponResource.ammoSize
		currentMagSize = weaponResource.weaponMagSize
		setWeaponRecoil()
@export_subgroup("Behavior")
var defaultBulletTrail = load("res://assets/entities/bulletTrail/bulletTrail.tscn")
@export var projectile : PackedScene = preload("res://assets/entities/projectiles/Bullet.tscn")
@export var muzzlePoint : Marker3D
@export var isReloading : bool = false:
	set(value):
		isReloading = value
		checkWeaponBlend()
		if isReloading:
			#weaponOwner.setLeftHandFilter(true)
			weaponOwner.setRightHandFilter(true)

@export var collisionEnabled : bool = true:
	set(value):
		collisionEnabled = value
		if collisionEnabled and collisionObject != null:
			collisionObject.disabled = false
		else:
			if collisionObject != null:
				collisionObject.disabled = true
@export var isEquipped : bool = false:
	set(value):
		isEquipped = value
		checkWeaponBlend()
		if value == true:
			#Weapon Orientation
			weaponMesh.position = weaponResource.weaponPositionOffset
			weaponMesh.rotation = weaponResource.weaponRotationOffset
			collisionEnabled = false
			setEquipVariables()
@export var isFiring :bool = false:
	set(value):
		isFiring = value
		checkWeaponBlend()
@export var isFreeAiming: bool = false:
	set(value):
		checkWeaponBlend()
		if weaponOwner:
			isFreeAiming = weaponOwner.freeAim
			#weaponOwner.setLeftHandFilter(weaponResource.useLeftHandFreeAiming)
			weaponOwner.setRightHandFilter(weaponResource.useRightHandFreeAiming)
@export var isAiming :bool = false:
	set(value):
		isAiming = value
		#print(isAiming)
		checkWeaponBlend()
		if weaponOwner != null:
			if value:
				#weaponOwner.setLeftHandFilter(weaponResource.useLeftHandAiming)
				weaponOwner.setRightHandFilter(weaponResource.useRightHandAiming)
			else:
			#	weaponOwner.setLeftHandFilter(weaponResource.useLeftHandIdle)
				weaponOwner.setRightHandFilter(weaponResource.useRightHandIdle)
		if value == true:
			weaponOwner.isRunning = false
@export var isBusy:bool  = false
@export var isWeaponBlocked :bool = false:
	set(value):
		isWeaponBlocked = value
		weaponBlockedChange.emit()
signal shot_fired
signal dry_fired
signal weaponBlockedChange

# Called when the node enters the scene tree for the first time.
func _ready()->void:
		#resetWeaponMesh()
		objectUsed.connect(equipToPawn)
		animationTree.tree_root = animationTree.tree_root.duplicate(true)
		weaponState = (animationTree.get("parameters/weaponState/playback") as AnimationNodeStateMachinePlayback)
		if get_parent().name == "Weapons":
			set("gravity_scale", 0)
			if weaponMesh:
				weaponMesh.position = weaponResource.weaponPositionOffset
				weaponMesh.rotation = weaponResource.weaponRotationOffset

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _physics_process(delta)->void:
	#if weaponResource:
		#if !weaponOwner == null:
			#if isEquipped:
				##Weapon Orientation
				#weaponMesh.position = weaponResource.weaponPositionOffset
				#weaponMesh.rotation = weaponResource.weaponRotationOffset
			#else:
				#collisionEnabled = false

func checkWeaponBlend()->void:
	if weaponAnimSet and isEquipped:
		if weaponRemoteState != null and weaponRemoteStateLeft != null:
			if weaponResource.useWeaponSprintAnim:
				if weaponOwner.isRunning and !isFiring and !isAiming and !weaponOwner.freeAim:
						weaponRemoteState.travel("sprint")
						weaponRemoteStateLeft.travel("sprint")

			if !isFiring and !isAiming and !weaponOwner.freeAim and !isReloading:
				if weaponRemoteState != null and weaponRemoteStateLeft != null:
					weaponRemoteState.travel("idle")
					weaponRemoteStateLeft.travel("idle")
					if weaponResource.useLeftHandIdle and !weaponOwner.isArmingThrowable:
						weaponOwner.enableLeftHand()
					else:
						weaponOwner.disableLeftHand()
					if weaponResource.useRightHandIdle:
						weaponResource.useRightHand = true
					else:
						weaponResource.useRightHand = false

			elif isReloading:
				weaponRemoteState.travel("reload")
				weaponRemoteStateLeft.travel("reload")
				weaponOwner.enableLeftHand()
				weaponOwner.setRightHandFilter(true)

			#elif isAiming:
				#if !weaponOwner.preventWeaponFire:
					#if !isReloading:
						#if !weaponRemoteState.get_current_node() == "aim":
							#weaponRemoteState.travel("aim")
							#weaponRemoteStateLeft.travel("aim")
				#weaponOwner.isRunning = false
				#if weaponResource.useLeftHandAiming:
					#weaponOwner.enableLeftHand()
				#else:
					#weaponOwner.disableLeftHand()
				#if weaponResource.useRightHandAiming:
					#weaponResource.useRightHand = true
				#else:
					#weaponResource.useRightHand = false
				#if !weaponOwner.meshLookAt:
					#weaponOwner.meshLookAt = true
				#elif weaponOwner.preventWeaponFire and !isReloading:
					#weaponRemoteState.travel("idle")
					#weaponRemoteStateLeft.travel("idle")

			elif weaponOwner.freeAim or isAiming:
				if !weaponOwner.preventWeaponFire:
					if !isReloading:
						if !weaponRemoteState.get_current_node() == "aim":
							weaponRemoteState.travel("aim")
							weaponRemoteStateLeft.travel("aim")
					if weaponOwner.freeAim:
						if weaponResource.useLeftHandFreeAiming and !weaponOwner.isArmingThrowable:
							weaponOwner.enableLeftHand()
						else:
							weaponOwner.disableLeftHand()
						if weaponResource.useRightHandFreeAiming:
							weaponResource.useRightHand = true
						else:
							weaponResource.useRightHand = false
					elif isAiming:
						weaponOwner.isRunning = false
						if weaponResource.useLeftHandAiming:
							weaponOwner.enableLeftHand()
						else:
							weaponOwner.disableLeftHand()
						if weaponResource.useRightHandAiming:
							weaponResource.useRightHand = true
						else:
							weaponResource.useRightHand = false
						if !weaponOwner.meshLookAt:
							weaponOwner.meshLookAt = true
				elif weaponOwner.preventWeaponFire and !isReloading:
					weaponRemoteState.travel("idle")
					weaponRemoteStateLeft.travel("idle")
	else:
		if weaponOwner != null:
			weaponOwner.disableLeftHand()

func fire()->void:
	if !isFireReady():
		return
	setWeaponRecoil()
	if currentAmmo < weaponResource.ammoConsumption and !isBusy:
		#The weapon is dry. Do the dry fire and wait a bit.
		isBusy = true
		dry_fired.emit()
		await get_tree().create_timer(weaponResource.weaponFireRate).timeout
		isBusy = false
		return

	#Weapon is capable of firing.
	if !isFiring:
		shot_fired.emit()
		isFiring = true

		#var shot_cast : RayCast3D = weaponCast
		#if checkShooter():
			#if weaponOwner.attachedCam.camCast != null:
				#shot_cast = weaponOwner.attachedCam.camCast

		if weaponRemoteState and weaponRemoteStateLeft and isEquipped:
			weaponRemoteState.start("fire")
			weaponRemoteStateLeft.start("fire")
		if weaponOwner.attachedCam:
			if weaponResource.useFOV:
				weaponOwner.attachedCam.camera.fov += weaponResource.fovShotAmount
			weaponOwner.attachedCam.fireRecoil(0.0,0.0,0.0,false)

		for b in weaponResource.weaponShots:
			currentAmmo -= weaponResource.ammoConsumption
			#var bullet = createMuzzle()
			#if weaponResource.weaponShots > 1:
				##randomize the muzzle pos?
				#bullet.position.x += randf_range(-0.09,0.09)
				#bullet.position.y += randf_range(-0.05,0.05)

			if weaponCast != null:
				spawnProjectile(weaponCast)
				applyCameraRecoil()
					#raycastHit(shot_cast)
					#var hit = globalParticles.detectMaterial(getHitObject(shot_cast))
					#if hit != null:
						#var pt = globalParticles.createParticle(globalParticles.detectMaterial(getHitObject(shot_cast)), getRayColPoint(shot_cast))
						#if !pt == null:
							#pt.look_at(getRayColPoint(shot_cast) + getRayNormal(shot_cast))
		await get_tree().create_timer(weaponResource.weaponFireRate).timeout
		isFiring = false
	return


func spawnProjectile(raycaster : RayCast3D) -> void:
	#print(raycaster.get_path())
	var bulletTrail : BulletTrail
	if weaponResource.useBulletTrail:
		bulletTrail = weaponResource.defaultBulletTrail.instantiate()
	var p : Projectile = projectile.instantiate() as Projectile

	var ray_target_point := get_hit_target(raycaster)

	p.projectile_owner = self
	gameManager.world.worldMisc.add_child(p)
	p.global_transform.origin = muzzlePoint.global_transform.origin
	p.add_exception(weaponOwner)
	for hitbox in weaponOwner.getAllHitboxes():
		p.add_exception(hitbox)
	#print("%s == %s : %s" % [raycaster.get_collision_point(), ray_target_point, raycaster.get_collision_point() == ray_target_point])
	p.velocity = -(muzzlePoint.global_transform.origin - ray_target_point).normalized() * weaponResource.bulletSpeed
	if bulletTrail != null:
		gameManager.world.worldMisc.add_child(bulletTrail)
		bulletTrail.initTrail(muzzlePoint.global_position, ray_target_point)
	return


func get_hit_target(raycast : RayCast3D) -> Vector3:
	var ray_target_point : Vector3 = raycast.global_position + (-raycast.global_transform.basis.z * 5000)

	var state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var rayq : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(raycast.global_position, ray_target_point, 0b10000, [])
	if state != null:
		rayq.collide_with_areas = true
		rayq.hit_back_faces = true
		rayq.hit_from_inside = false
		rayq.exclude.append(RID(weaponOwner))
		for hitbox in weaponOwner.getAllHitboxes():
			rayq.exclude.append(RID(hitbox))
		var intersect = state.intersect_ray(rayq)
		if !intersect.is_empty():
			if weaponOwner and !ray_target_point.z > weaponOwner.global_position.z:
				ray_target_point = intersect['position']
			else:
				ray_target_point = intersect['position']
		else:
			rayq.collide_with_areas = false
			rayq.collision_mask = raycast.collision_mask
			intersect = state.intersect_ray(rayq)
			if !intersect.is_empty():
				ray_target_point = intersect['position']
	return ray_target_point


func isFireReady() -> bool:
	if weaponOwner.preventWeaponFire or isReloading or isFiring or isBusy:
		#Cancel if it can't fire. Conditions it can't fire:
		#1 - Owner blocks firing
		#2 - Gun is reloading
		#3 - Gun is already firing
		#4 - Gun is busy
		return false
	return true


func applyCameraRecoil()->void:
	if !weaponOwner.get(&"attachedCam") is CharacterBody3D:
		return
	if isAiming:
		weaponOwner.attachedCam.camRecoilStrength = weaponResource.weaponRecoilStrengthAim
		weaponOwner.attachedCam.applyWeaponSpread(weaponResource.weaponSpreadAim)
	else:
		weaponOwner.attachedCam.camRecoilStrength = weaponResource.weaponRecoilStrength
		weaponOwner.attachedCam.applyWeaponSpread(weaponResource.weaponSpread)


func createMuzzle() -> Node:
	var bulletTrail = defaultBulletTrail.instantiate()
	bulletTrail.bulletColor = weaponResource.bulletColor
	#var btInstance = bulletTrail.instantiate()
	if !muzzlePoint == null:
		if checkShooter():
			if weaponOwner.attachedCam.camCast != null:
				if weaponOwner.attachedCam.camCast.is_colliding():
					bulletTrail.initTrail(muzzlePoint.global_position, getRayColPoint())
				else:
					bulletTrail.initTrail(muzzlePoint.global_position, weaponOwner.attachedCam.camCastEnd.global_position)
				gameManager.world.worldMisc.add_child(bulletTrail)
				return bulletTrail
		else:
			if weaponCast != null:
				if weaponCast.is_colliding():
					bulletTrail.initTrail(muzzlePoint.global_position, getRayColPoint(weaponCast))
				else:
					bulletTrail.initTrail(muzzlePoint.global_position, weaponCastEnd.global_position)
				gameManager.world.worldMisc.add_child(bulletTrail)
				return bulletTrail
	else:
		assert(false, "This weapon doesn't have a muzzle point! Add one now fucker.")
	return null


func checkShooter():
	if weaponOwner.attachedCam:
		return true
	else:
		return false


func raycastHit(raycaster : RayCast3D = null):
	var colliding
	var hitPoint
	var hitNormal
	var raycast : RayCast3D
	if raycaster != null:
		raycast = raycaster
	else:
		raycast = weaponOwner.attachedCam.camCast
	colliding = raycast.get_collider()
	hitPoint = raycast.get_collision_point()
	hitNormal = raycast.get_collision_normal()
	if colliding != null:
		var phys_mat : DB_PhysicsMaterial = gameManager.getColliderPhysicsMaterial(colliding)
		#Create the bullet hole
		globalParticles.spawnBulletHolePackedScene(phys_mat.bullet_hole, colliding, hitPoint, randf_range(0, 2), hitNormal)
		#if colliding.is_in_group("Flesh"):
			#var fleshHole = globalParticles.spawnBulletHole("Flesh",colliding,hitPoint,randf_range(0, 2),hitNormal)
		#else:
			#var bhole = globalParticles.spawnBulletHole("default",colliding,hitPoint,randf_range(0, 2),hitNormal)
		#if colliding.has_method(&"hit"):
			#colliding.hit(weaponResource.weaponDamage,weaponOwner,raycaster.basis.z * weaponResource.weaponImpulse,to_global(to_local(hitPoint)-position))


func getHitObject(raycaster : RayCast3D = null):
	var raycast : RayCast3D
	if raycaster:
		raycast = raycaster
	else:
		raycast = weaponOwner.attachedCam.camCast
	var hitObject = raycast.get_collider()
	if raycast.is_colliding():
		return hitObject


func getRayNormal(raycaster : RayCast3D = null):
	var raycast : RayCast3D
	if raycaster:
		raycast = raycaster
	else:
		raycast = weaponOwner.attachedCam.camCast
	var hitNormal = raycast.get_collision_normal()
	if raycast.is_colliding():
		return hitNormal


func getRayColPoint(raycaster : RayCast3D = null):
	var raycast : RayCast3D
	if raycaster:
		raycast = raycaster
	else:
		raycast = weaponOwner.attachedCam.camCast
	var hitPoint = raycast.get_collision_point()
	if raycast.is_colliding():
		return hitPoint

func resetWeaponMesh()->void:
	if weaponMesh:
		weaponMesh.position = position
		weaponMesh.rotation = rotation
		collisionObject.rotation = weaponMesh.rotation

func resetToDefault()->void:
	#resetWeaponMesh()
	if weaponOwner:
		if weaponOwner.weaponFireChanged.is_connected(checkWeaponBlend):
			weaponOwner.weaponFireChanged.disconnect(checkWeaponBlend)
	if weaponRemoteState != null:
		weaponRemoteState.stop()
	if weaponRemoteStateLeft != null:
		weaponRemoteStateLeft.stop()
	weaponAnimSet = false
	weaponOwner = null
	isFiring = false
	isAiming = false
	isEquipped = false
	collisionEnabled = false

func equipToPawn(pawn:BasePawn):
	if pawn:
		if !pawn.itemNames.has(objectName):
			collisionEnabled = false
			collisionObject.disabled = true
			pawn.moveItemToWeapons(self)
			pawn.playGrabAnimation()
			#pawn.freeAimChanged.connect(checkFreeAim)
			if objectUsed.is_connected(equipToPawn):
				objectUsed.disconnect(equipToPawn)
			if !pawn.weaponFireChanged.is_connected(checkWeaponBlend):
				pawn.weaponFireChanged.connect(checkWeaponBlend)
			if pawn.attachedCam:
				var _notification = load("res://assets/scenes/ui/generalNotif/generalNotification.tscn").instantiate()
				pawn.attachedCam.hud.gameNotifications.add_child(_notification)
				_notification.doNotification(null,"New Item Acquired","%s Added to inventory." %objectName)
				#gameManager.notifyFade("%s Added to inventory." %objectName)
				pawn.equipSound.play()
				pawn.attachedCam.fireRecoil(0,3.7,5.4,true)
		else:
			pawn.playGrabAnimation()
			for weaponIndex in pawn.itemInventory.size():
				if pawn.itemInventory[weaponIndex] != null:
					if pawn.itemInventory[weaponIndex].objectName == self.objectName:
						if currentMagSize >= 1:
							pawn.itemInventory[weaponIndex].currentMagSize += currentMagSize
							self.queue_free()
							if pawn.attachedCam:
								var _notification = load("res://assets/scenes/ui/generalNotif/generalNotification.tscn").instantiate()
								pawn.attachedCam.hud.gameNotifications.add_child(_notification)
								_notification.doNotification(null,objectName,"+%s Ammo has been added." %currentMagSize)
								#gameManager.notifyFade("+%s %s Ammo has been added" %[currentMagSize,objectName])
								#pawn.equipSound.play()
								pawn.attachedCam.fireRecoil(0,3.7,5.4,true)
						else:
							if pawn.attachedCam:
								gameManager.notifyFade("This %s has no ammo, I have no use for it." %[objectName])
								pawn.equipSound.play()
								pawn.attachedCam.fireRecoil(0,3.7,5.4,true)

func setInteractable()->void:
		reparent(gameManager.world.worldProps)
		set("gravity_scale", 1)
		add_to_group("Interactable")
		interactType = 0
		canBeUsed = true
		freeze = false

func setEquipVariables()->void:
	if is_in_group("Interactable"):
		remove_from_group("Interactable")
	canBeUsed = false
	collisionEnabled = false
	setWeaponRecoil()

func setWeaponRecoil()->void:
	if weaponOwner != null:
		if weaponOwner.attachedCam != null:
			weaponOwner.attachedCam.camRecoil = weaponResource.weaponRecoil

func reloadWeapon()->void:
	#await get_tree().process_frame
	weaponRemoteState.stop()
	weaponRemoteStateLeft.stop()
	if canReloadWeapon and !isReloading and weaponResource.canBeReloaded and isEquipped and !weaponOwner.isArmingThrowable:
		var firedShots = weaponResource.ammoSize - currentAmmo
		weaponRemoteState.travel("reload")
		weaponRemoteState.next()
		weaponRemoteStateLeft.travel("reload")
		weaponRemoteStateLeft.next()
		isReloading = true
		var timer = get_tree().create_timer(weaponResource.reloadTime)
		canReloadWeapon = false
		await timer.timeout
		isReloading = false
		currentMagSize -= firedShots
		currentAmmo += firedShots
		if weaponOwner != null:
			if isAiming:
				if weaponOwner != null:
					#weaponOwner.setLeftHandFilter(weaponResource.useLeftHandAiming)
					weaponOwner.setRightHandFilter(weaponResource.useRightHandAiming)
			elif weaponOwner.freeAim:
				if weaponOwner != null:
					#weaponOwner.setLeftHandFilter(weaponResource.useLeftHandFreeAiming)
					weaponOwner.setRightHandFilter(weaponResource.useRightHandFreeAiming)
			elif !isFiring and !isAiming and !weaponOwner.freeAim and !isReloading and weaponOwner != null:
				#weaponOwner.setLeftHandFilter(weaponResource.useLeftHandIdle)
				weaponOwner.setRightHandFilter(weaponResource.useRightHandIdle)

func checkFreeAim()->void:
	if weaponOwner:
		isFreeAiming = weaponOwner.freeAim
