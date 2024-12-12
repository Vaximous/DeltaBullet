extends PhysicalBone3D
class_name RagdollBone
signal isAsleep
signal isAwake
signal onHit(impulse,vector)
@export_category("Ragdoll Bone")
var boneCooldownTimer : Timer
var ownerSkeleton : Skeleton3D:
	set(value):
		ownerSkeleton = value
		#if !get_owner().physicalBoneSimulator.modification_processed.is_connected(doActiveRagdoll):
			#get_owner().physicalBoneSimulator.modification_processed.connect(doActiveRagdoll)
			#print("connected")
var ragdoll : PawnRagdoll:
	set(value):
		ragdoll = value
		if !ragdoll.ragdollSkeleton.skeleton_updated.is_connected(updateRagdollScale):
			ragdoll.ragdollSkeleton.skeleton_updated.connect(updateRagdollScale)
@export var healthComponent : HealthComponent:
	set(value):
		healthComponent = value
		if canBeDismembered:
			if !healthComponent.HPisDead.is_connected(pulverizeBone):
				healthComponent.HPisDead.connect(pulverizeBone)
var bonePhysicsServer = PhysicsServer3D
@export var canBeDismembered : bool = false:
	set(value):
		canBeDismembered = value
		if canBeDismembered:
			if healthComponent != null:
				healthComponent.HPisDead.connect(pulverizeBone)
		else:
			healthComponent.HPisDead.disconnect(pulverizeBone)
var bonePulverized : bool = false:
	set(value):
		if bonePulverized != value:
			bonePulverized = value
			if value == true:
				doPulverizeEffect()
var torque : Vector3
var boneState:bool:
	set(value):
		boneState = value
		if boneState == true:
			isAsleep.emit()
		else:
			isAwake.emit()
var whirrSound : bool = false
var canBleed : bool = false
var hasBled : bool = false
@export var activeRagdollBone : bool = true
@export var activeRagdollForce = 1
@export_subgroup("Impact Hits")
@export var canBePulverized = false
@export var hardImpactEffectEnabled : bool = true
@export var impactEffectHard : PackedScene
@export var mediumImpactEffectEnabled : bool = true
@export var impactEffectMedium : PackedScene
@export var lightImpactEffectEnabled : bool = true
@export var impactEffectLight : PackedScene
@export_subgroup("Sounds")
@export var inAirSound : AudioStream
@export var lightImpactSounds : AudioStreamRandomizer
@export var mediumImpactSounds : AudioStreamRandomizer
@export var heavyImpactSounds : AudioStreamRandomizer
@export_subgroup("Thresholds")
@export var lightImpactThreshold : float = 4
@export var mediumImpactThreshold : float = 12
@export var heavyImpactThreshold : float = 32
@export_range(-1.0, 1.0) var impact_dot_min : float
@export_subgroup("Collision Information")
@export var collisionSound : AudioStream
var bonePhysics : PhysicsDirectBodyState3D
@export_subgroup("Information")
@export var currentVelocity : Vector3
@export var contactCount : int
var initialRotation = get("joint_rotation")

var audioStreamPlayer : AudioStreamPlayer3D
var inAirStreamPlayer : AudioStreamPlayer3D

var audioCooldown : float = 0.0:
	set(value):
		audioCooldown = value
		if audioCooldown > 0.0:
			boneCooldownTimer.start(0.15)
		else:
			boneCooldownTimer.stop()
var exclusionArray : Array[RID]

# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	bonePhysicsServer.body_set_max_contacts_reported(RID(self), 1)
	if canBeDismembered and healthComponent:
		if !healthComponent.HPisDead.is_connected(pulverizeBone):
			healthComponent.HPisDead.connect(pulverizeBone)
	setBoneCooldownTimer()
	createAudioPlayer()
	#isAsleep.connect(doBleed)


func createInAirAudio()->void:
	if inAirSound != null:
		inAirStreamPlayer = AudioStreamPlayer3D.new()
		add_child(inAirStreamPlayer)
		inAirStreamPlayer.stream = inAirSound
		inAirStreamPlayer.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
		inAirStreamPlayer.panning_strength = 3.0
		inAirStreamPlayer.volume_db = -80.0
		inAirStreamPlayer.max_db = 0
		inAirStreamPlayer.max_distance = 32
		inAirStreamPlayer.unit_size = 0.25
		inAirStreamPlayer.attenuation_filter_db = -30
		inAirStreamPlayer.attenuation_filter_cutoff_hz = 6000
		inAirStreamPlayer.play()


func setBoneCooldownTimer()->void:
	await get_tree().process_frame
	boneCooldownTimer = Timer.new()
	add_child(boneCooldownTimer)
	boneCooldownTimer.stop()
	boneCooldownTimer.wait_time = 0.15
	boneCooldownTimer.autostart = false
	boneCooldownTimer.one_shot = false
	boneCooldownTimer.timeout.connect(subtractBoneCooldown)


func createAudioPlayer()->void:
	await get_tree().process_frame
	audioStreamPlayer = AudioStreamPlayer3D.new()
	add_child(audioStreamPlayer)
	set_meta(&"physics_material_override", preload("res://assets/resources/PhysicsMaterials/flesh_physics_material.tres"))
	audioStreamPlayer.max_polyphony = 2
	audioStreamPlayer.max_db = 15
	audioStreamPlayer.max_distance = 32
	audioStreamPlayer.unit_size = 0.5
	audioStreamPlayer.bus = &"Sounds"
	audioStreamPlayer.attenuation_filter_db = 0
	audioStreamPlayer.attenuation_filter_cutoff_hz = 3000


func updateRagdollScale()->void:
	if healthComponent.isDead and canBeDismembered:
		pulverizeBone()
		#bonePulverized = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _integrate_forces(state:PhysicsDirectBodyState3D)->void:
	boneState = state.sleeping
	if audioCooldown > 0 or boneState == true:
			return

	if state.get_contact_count() > 0 and !boneState and ragdoll != null:
		if exclusionArray.has(state.get_contact_collider(0)):
			return
		#var contactNormal = state.get_contact_local_normal(0)
		#var contactDot = state.get_contact_local_velocity_at_position(0).normalized().dot(contactNormal)
		var contactForce = state.get_contact_local_velocity_at_position(0).length()
		#contactForce = clampf(contactForce,0,heavyImpactThreshold)
		if gameManager.debugEnabled:
			print("%s Contact Force : %s"%[name,contactForce])
		#audioStreamPlayer.attenuation_filter_db = lerp(-20, 0, clamp(abs(contactDot) * contactForce, 0, 1))
		if contactForce > heavyImpactThreshold:
			audioStreamPlayer.stream = heavyImpactSounds
			audioStreamPlayer.play()
			audioCooldown = 0.45
			if healthComponent:
				healthComponent.damage(contactForce + randi_range(0,16))
			if hardImpactEffectEnabled:
				if impactEffectHard == null:
					if canBeDismembered:
						healthComponent.damage(900,null)
						pulverizeBone()
					var particle = globalParticles.createParticle("BloodSpurt",self.position)
					particle.rotation = self.rotation
					#particle.amount = randi_range(25,75)
					gameManager.sprayBlood(global_position,randi_range(1,3),10,1.2)
		elif contactForce > mediumImpactThreshold:
			audioStreamPlayer.stream = mediumImpactSounds
			audioStreamPlayer.play()
			audioCooldown = 0.45
			if healthComponent:
				healthComponent.damage(contactForce + randi_range(0,10))
			if mediumImpactEffectEnabled:
				if impactEffectMedium == null:
					#await get_tree().process_frame
					var particle = globalParticles.createParticle("BloodSpurt",self.position)
					particle.rotation = self.rotation
					#particle.amount = randi_range(25,40)
					gameManager.sprayBlood(global_position,randi_range(1,3),10,1.2)
		elif contactForce > lightImpactThreshold:
			audioStreamPlayer.stream = lightImpactSounds
			#var fac = (contactForce - lightImpactThreshold) / (mediumImpactThreshold - lightImpactThreshold)
			#audioStreamPlayer.volume_db = lerp(-2, 5, fac)
			audioStreamPlayer.play()
			audioCooldown = 0.45
			if lightImpactEffectEnabled:
				if impactEffectLight == null:
					#await get_tree().process_frame
					var particle = globalParticles.createParticle("BloodSpurt",self.position)
					particle.rotation = self.rotation
					gameManager.sprayBlood(global_position,randi_range(1,3),10,1.2)


#func _physics_process(delta)->void:
	#if audioCooldown > 0:
		#audioCooldown -= delta

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	canBleed = true
	emit_signal("onHit",hitImpulse,hitPoint)
	apply_central_impulse(hitImpulse)
	if get_bone_id() == 41:
		if get_owner().activeRagdollEnabled:
			get_owner().activeRagdollEnabled = false
	if healthComponent != null:
		#print("dmg:%s"%int(dmg))
		#print("hp:%s"%healthComponent.health)
		healthComponent.damage(int(dmg),dealer)


func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)


func pulverizeBone()->void:
	#await get_tree().process_frame
	ragdoll.ragdollSkeleton.set_bone_pose_scale(get_bone_id(),Vector3.ZERO)
	ragdoll.ragdollSkeleton.force_update_bone_child_transform(get_bone_id())
	if bonePulverized != true:
		bonePulverized = true

func subtractBoneCooldown()->void:
	audioCooldown -= 0.1

func getBoneChildren(skeleton3d:Skeleton3D,bone:PhysicalBone3D)->Array:
	return skeleton3d.get_bone_children(bone.get_bone_id())

func findPhysicsBone(id:int)->PhysicalBone3D:
	var foundBone : PhysicalBone3D
	for bones in ragdoll.physicsBones:
		if bones.get_bone_id() == id and bones != null:
			foundBone = bones
	return foundBone

func createBurstOfPhysicsBlood(amountMin:int,amountMax:int,maxImpulse:int)->void:
	var droplets : PackedScene = load("res://assets/entities/emitters/bloodDroplet/bloodDroplets.tscn")
	for drop in randf_range(amountMin,amountMax):
		if gameManager.world != null:
			var blood : RigidBody3D = droplets.instantiate()
			gameManager.world.worldMisc.add_child(blood)
			blood.global_position = Vector3(global_position.x,global_position.y-1.4,global_position.z)
			blood.apply_impulse(Vector3(randf_range(-maxImpulse,maxImpulse),randf_range(-maxImpulse,maxImpulse),randf_range(-maxImpulse,maxImpulse)) * randf_range(5,maxImpulse))


func doPulverizeEffect()->void:
	canBleed = true
	var pulverizeSound : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	pulverizeSound.stream = load("res://assets/misc/obliterateStream.tres")
	pulverizeSound.bus = &"Sounds"
	pulverizeSound.attenuation_filter_db = 0
	pulverizeSound.volume_db = -5
	add_child(pulverizeSound)
	pulverizeSound.play()
	var bloodSpurt : GPUParticles3D = load("res://assets/particles/bloodSpurt/bloodSpurt.tscn").instantiate()
	gameManager.world.worldMisc.add_child(bloodSpurt)
	bloodSpurt.global_position = global_position
	bloodSpurt.amount = randi_range(50,85)
	bloodSpurt.emitting = true
	collision_layer = 0
	collision_mask = 1
	joint_type = JOINT_TYPE_NONE
	gameManager.sprayBlood(global_position,randi_range(3,15),500,1.2)
	#mass = 0.01
	for childrenIDs in getBoneChildren(ragdoll.ragdollSkeleton,self):
		var bone
		bone = findPhysicsBone(childrenIDs)
		if bone != null:
			bone.collision_layer = 0
			bone.collision_mask = 0
			#findPhysicsBone(childrenIDs).mass = 0
	#createBurstOfBlood(10,15,25)

func doBleed()->void:
	if !hasBled and canBleed:
		gameManager.createBloodPool(global_position,randf_range(0.3,1.6))
		hasBled = true


func doActiveRagdoll(value:bool)->void:
	if get_owner().targetSkeleton != null:
		var boneTarget = get_owner().targetSkeleton.global_transform * get_owner().targetSkeleton.get_bone_global_pose(get_bone_id())
		var boneTargetRotation = get_owner().targetSkeleton.quaternion * get_owner().targetSkeleton.get_bone_pose_rotation(get_bone_id())
		print("%s Rotation : %s"%[name,boneTargetRotation])
