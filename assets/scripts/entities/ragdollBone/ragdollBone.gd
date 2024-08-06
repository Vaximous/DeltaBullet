extends PhysicalBone3D
class_name RagdollBone
signal isAsleep
signal isAwake
signal onHit(impulse,vector)
@export_category("Ragdoll Bone")
var bonePhysicsServer = PhysicsServer3D
var torque : Vector3
var boneState:bool:
	set(value):
		boneState = value
		if boneState == true:
			isAsleep.emit()
		else:
			isAwake.emit()
var whirrSound : bool = false
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

var audioStreamPlayer : AudioStreamPlayer3D
var inAirStreamPlayer : AudioStreamPlayer3D

var audioCooldown : float = 0.0
var exclusionArray : Array[RID]

# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	bonePhysicsServer.body_set_max_contacts_reported(RID(self), 1)
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _integrate_forces(state:PhysicsDirectBodyState3D)->void:
	if get_owner().activeRagdollEnabled:
		if get_owner().targetSkeleton != null:
			if activeRagdollBone:
				var bonerot : Basis = get_owner().global_transform.basis * get_owner().ragdollSkeleton.get_bone_global_pose(get_bone_id()).basis
				var bone2tr : Basis = bonerot.inverse() * self.transform.basis
				var boneglobalpose_targskel :Transform3D= get_owner().targetSkeleton.get_bone_global_pose(get_bone_id())
				var boneglobalpose_ragskel:Transform3D = get_owner().ragdollSkeleton.get_bone_global_pose(get_bone_id())
				#get_owner().ragdollSkeleton.set_bone_pose_position(get_bone_id(),bone2tr.get_euler())
				get_owner().ragdollSkeleton.set_bone_pose_position(get_bone_id(), get_owner().targetSkeleton.get_bone_pose_position(get_bone_id()))
				get_owner().ragdollSkeleton.set_bone_pose_rotation(get_bone_id(), get_owner().targetSkeleton.get_bone_pose_rotation(get_bone_id()))
				#var targtransfrm: Quaternion = get_owner().targetSkeleton.get_bone_pose_rotation(get_bone_id())
				#var currtransform : Quaternion = get_owner().ragdollSkeleton.get_bone_pose_rotation(get_bone_id()).inverse()
				#var rotdif = (targtransfrm.get_euler() * currtransform.get_euler().inverse() * activeRagdollForce)
				#var targrot = boneglobalpose_targskel.basis.inverse() * boneglobalpose_ragskel.basis

				var targetTransform : Transform3D = get_owner().targetSkeleton.get_bone_pose(get_bone_id())
				var currentTransform : Transform3D = get_owner().ragdollSkeleton.get_bone_global_pose(get_bone_id()) * get_owner().targetSkeleton.get_bone_global_pose(get_bone_id()).inverse()
				var rotationDifference : Basis = (targetTransform.basis * currentTransform.basis.inverse())
				get_owner().ragdollSkeleton.set_bone_global_pose_override(get_bone_id(),get_owner().ragdollSkeleton.global_transform.affine_inverse() * targetTransform,1.0,true)
				#var torque = hookes_law(rotationDifference.get_euler(),state.angular_velocity,500,10)
				#state.apply_torque(rotationDifference.get_euler() * activeRagdollForce* state.step)

	if bonePhysics == null:
		bonePhysics = state
	boneState = state.sleeping
	currentVelocity = state.get_linear_velocity()
	contactCount = state.get_contact_count()
	if audioCooldown > 0:
			return
	#print(bonePhysics)
	if state.get_contact_count() > 0:
		if exclusionArray.has(state.get_contact_collider(0)):
			return
		var contactNormal = state.get_contact_local_normal(0)
		var contactDot = state.get_contact_local_velocity_at_position(0).normalized().dot(contactNormal)
		var contactForce = state.get_contact_local_velocity_at_position(0).length()

		audioStreamPlayer.attenuation_filter_db = lerp(-20, 0, clamp(abs(contactDot) * contactForce, 0, 1))
		if contactForce > heavyImpactThreshold:
			audioStreamPlayer.stream = heavyImpactSounds
			audioStreamPlayer.play()
			audioCooldown = 0.05
			if hardImpactEffectEnabled:
				if impactEffectHard == null:
					await get_tree().process_frame
					var particle = globalParticles.createParticle("BloodSpurt",self.position)
					particle.rotation = self.rotation
					particle.amount = randi_range(25,75)
					createBlood()
			return
		elif contactForce > mediumImpactThreshold:
			audioStreamPlayer.stream = mediumImpactSounds
			audioStreamPlayer.play()
			audioCooldown = 0.25
			if mediumImpactEffectEnabled:
				if impactEffectMedium == null:
					await get_tree().process_frame
					var particle = globalParticles.createParticle("BloodSpurt",self.position)
					particle.rotation = self.rotation
					particle.amount = randi_range(25,40)
					createBlood()
			return
		elif contactForce > lightImpactThreshold:
			audioStreamPlayer.stream = lightImpactSounds
			var fac = (contactForce - lightImpactThreshold) / (mediumImpactThreshold - lightImpactThreshold)
			audioStreamPlayer.volume_db = lerp(-2, 5, fac)
			audioStreamPlayer.play()
			audioCooldown = 0.25
			if lightImpactEffectEnabled:
				if impactEffectLight == null:
					await get_tree().process_frame
					var particle = globalParticles.createParticle("BloodSpurt",self.position)
					particle.rotation = self.rotation
					createBlood()
		return

func _physics_process(delta)->void:
	if get_owner().visibleOnScreen:
		if boneState and whirrSound:
			audioCooldown -= delta
			if inAirStreamPlayer != null:
				var fac = clamp(linear_velocity.length() * angular_velocity.length_squared() / 1000.0, 0.0, 1.0)
				if linear_velocity.length() < 2.0:
					fac *= 0
				#Realistically it would only play the sound as its whipping towards the viewer
				inAirStreamPlayer.volume_db = lerp(inAirStreamPlayer.volume_db, -80 + (fac * 80), delta * 6)
				inAirStreamPlayer.pitch_scale = lerp(inAirStreamPlayer.pitch_scale, (angular_velocity.length() / 500.0) + 2.0, delta * 4)

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	emit_signal("onHit",hitImpulse,hitPoint)
	apply_impulse(hitImpulse, hitPoint)
	if get_bone_id() == 41:
		if get_owner().activeRagdollEnabled:
			get_owner().activeRagdollEnabled = false

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

func createBlood()->void:
	var droplets : PackedScene = load("res://assets/entities/emitters/bloodDroplet/bloodDroplets.tscn")
	var blood = droplets.instantiate()
	gameManager.world.worldMisc.add_child(blood)
	blood.global_position = global_position
