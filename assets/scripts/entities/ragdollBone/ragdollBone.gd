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
		await get_tree().process_frame
		boneParent = ownerSkeleton.get_bone_parent(get_bone_id())
		physicsBoneParent = findPhysicsBone(boneParent)
var ragdoll : PawnRagdoll
var bloodSpurt = preload("res://assets/particles/bloodSpurt/bloodSpurt.tscn")
@export var healthComponent : HealthComponent:
	set(value):
		healthComponent = value
		if canBeDismembered:
			if !healthComponent.HPisDead.is_connected(pulverizeBone):
				healthComponent.HPisDead.connect(pulverizeBone)
var bonePhysicsServer = PhysicsServer3D
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
#@export var activeRagdollBone : bool = true
#@export var activeRagdollForce = 1
@export_subgroup("Impact Hits")
@export var canBeDismembered : bool = false
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

var boneParent
var physicsBoneParent

var audioCooldown : float = 0.0:
	set(value):
		audioCooldown = value
var exclusionArray : Array[RID]
var activeRagdollJoint : Generic6DOFJoint3D
# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	boneSetup()

func apply_spring_torque(
	bone: PhysicalBone3D,
	target_transform: Transform3D,
	stiffness: float = 20.0,
	damping: float = 2.0,
	epsilon: float = 1e-4,
	max_torque: float = 1000.0
) -> void:
	# Get current and target rotations as quaternions
	var cur_q: Quaternion = bone.global_transform.basis.get_rotation_quaternion()
	var tgt_q: Quaternion = target_transform.basis.get_rotation_quaternion()

	# Rotation that rotates current -> target
	var delta_q: Quaternion = (tgt_q * cur_q.inverse()).normalized()

	# Angle (radians) and axis from quaternion
	var angle: float = delta_q.get_angle()
	if angle <= epsilon:
		return # nothing to do for tiny angles

	var axis: Vector3 = delta_q.get_axis()
	if axis.length_squared() == 0.0:
		return

	axis = axis.normalized() # normalize because get_axis() can be unreliable near zero-angle
	# PD controller (proportional by angle, derivative by angular velocity)
	var _torque: Vector3 = axis * (angle * stiffness)
	_torque -= bone.angular_velocity * damping

	# safety clamp
	var t_len = torque.length()
	if t_len > max_torque and t_len > 0.0:
		_torque = _torque / t_len * max_torque

	angular_velocity = _torque

func apply_ragdoll_motor(b: PhysicalBone3D, target_basis: Basis, kp: float = 500, kd: float = 1, force_limit: float = 1.5) -> void:
# Apply ragdoll motor control to make a PhysicalBone3D follow a target orientation.
# - b: the PhysicalBone3D
# - target_basis: the desired orientation (Basis) from the animated Skeleton
# - kp: proportional gain (stiffness)
# - kd: derivative gain (damping)
# - force_limit: maximum torque the motor can apply
	if not b:
		return

	# Current and target orientations as quaternions
	var current_q: Quaternion = b.global_transform.basis.get_rotation_quaternion()
	var target_q: Quaternion = target_basis.get_rotation_quaternion()

	# Quaternion error (rotation from current -> target)
	var error_q: Quaternion = current_q.inverse() * target_q
	error_q = error_q.normalized()

	# Convert to axis-angle
	var angle: float = 2.0 * acos(clamp(error_q.w, -1.0, 1.0))
	if angle > PI:
		angle -= TAU

	var angular_error: Vector3 = Vector3.ZERO
	if abs(angle) > 0.0001:
		angular_error = error_q.get_axis() * angle

	# PD controller: target angular velocity
	var desired_velocity: Vector3 = angular_error * kp - b.angular_velocity * kd

	# Enable & configure motor
	ragdoll.setAngularMotor(b, true)
	ragdoll.setAngularMotorForceLimit(b, force_limit)
	ragdoll.setAngularMotorTargetVelocity(b, desired_velocity)

func _physics_process(delta: float) -> void:
	if ragdoll.activeRagdollEnabled:
		pass
		#var target_pose: Transform3D = ragdoll.targetSkeleton.get_bone_pose(get_bone_id())



func boneSetup()->void:
	excludeAllAI()
	set_meta(&"physics_material_override", preload("res://assets/resources/PhysicsMaterials/flesh_physics_material.tres"))
	setBoneCooldownTimer()
	audioCooldown = 0.0
	createAudioPlayer()
	body_entered.connect(boneCollision)
	#bonePhysicsServer.body_set_max_contacts_reported(RID(self), 1)
	isAsleep.connect(doBleed)
	if canBeDismembered:
		if is_instance_valid(healthComponent):
			if !healthComponent.HPisDead.is_connected(doPulverizeEffect):
				healthComponent.HPisDead.connect(doPulverizeEffect)
	else:
		if healthComponent.HPisDead.is_connected(doPulverizeEffect):
			healthComponent.HPisDead.disconnect(doPulverizeEffect)
#
	if is_instance_valid(ragdoll):
		if !ragdoll.ragdollSkeleton.skeleton_updated.is_connected(updateRagdollScale):
				ragdoll.ragdollSkeleton.skeleton_updated.connect(updateRagdollScale)


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
	boneCooldownTimer = Timer.new()
	add_child(boneCooldownTimer)
	boneCooldownTimer.stop()
	boneCooldownTimer.wait_time = 0.15
	boneCooldownTimer.autostart = false
	boneCooldownTimer.one_shot = false
	boneCooldownTimer.timeout.connect(subtractBoneCooldown)
	boneCooldownTimer.start()


func createAudioPlayer()->void:
	audioStreamPlayer = AudioStreamPlayer3D.new()
	add_child(audioStreamPlayer)
	audioStreamPlayer.max_polyphony = 2
	audioStreamPlayer.max_db = 15
	audioStreamPlayer.max_distance = 32
	audioStreamPlayer.unit_size = 0.5
	audioStreamPlayer.bus = &"Sounds"
	#audioStreamPlayer.attenuation_filter_db = 0
	audioStreamPlayer.attenuation_filter_cutoff_hz = 20500


func updateRagdollScale()->void:
	if healthComponent.isDead and canBeDismembered and is_instance_valid(healthComponent):
		pulverizeBone()
		#bonePulverized = true

func createSpurtInstance(globalPosition : Vector3)->void:
	var spurtInstance = bloodSpurt.instantiate()
	gameManager.world.worldMisc.add_child(spurtInstance)
	spurtInstance.global_position = globalPosition
	spurtInstance.global_rotation = global_rotation
	spurtInstance.emitting = true

func createContactBlood(state:PhysicsDirectBodyState3D)->void:
		gameManager.createDroplet(state.get_contact_collider_position(0),currentVelocity* 0.15)
		#var dec = gameManager.createSplat(state.get_contact_collider_position(0),state.get_contact_local_normal(0))
		#createSpurtInstance(state.get_contact_collider_position(0))
		#print(state.get_contact_local_normal(0))

func _integrate_forces(state:PhysicsDirectBodyState3D)->void:
	boneState = state.sleeping
	currentVelocity = state.get_velocity_at_local_position(position)



func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO, bullet:Projectile = null)->void:
	if !has_meta("exploded"):
		canBleed = true
	onHit.emit(hitImpulse,hitPoint)
	apply_impulse(hitImpulse,hitPoint)
	if get_bone_id() == 42:
		if get_owner().activeRagdollEnabled:
			get_owner().activeRagdollEnabled = false
	if is_instance_valid(healthComponent):
		#print("dmg:%s"%int(dmg))
		#print("hp:%s"%healthComponent.health)
		if is_instance_valid(dealer):
			healthComponent.damage(int(dmg),dealer)
		else:
			healthComponent.damage(int(dmg),null)

func excludeAllAI()->void:
	for i in gameManager.allPawns:
		if is_instance_valid(i):
			if !i .isPlayerPawn():
				add_collision_exception_with(i)


func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

func pulverizeBone()->void:
	#await get_tree().process_frame
	ragdoll.ragdollSkeleton.set_bone_pose_scale(get_bone_id(),Vector3(0.01,0.01,0.01))
	#ragdoll.ragdollSkeleton.force_update_bone_child_transform(get_bone_id())
	if bonePulverized != true:
		bonePulverized = true

func subtractBoneCooldown()->void:
	if audioCooldown > 0:
		audioCooldown -= 0.1

func getBoneChildren(skeleton3d:Skeleton3D,bone:PhysicalBone3D)->Array:
	return skeleton3d.get_bone_children(bone.get_bone_id())

func findPhysicsBone(id:int)->PhysicalBone3D:
	var foundBone : PhysicalBone3D
	for bones in ragdoll.physicsBones:
		if is_instance_valid(bones) and bones.get_bone_id() == id:
			foundBone = bones
	return foundBone


func createActiveRagdollJoint()->void:
	var activeRagJoint : Generic6DOFJoint3D = Generic6DOFJoint3D.new()
	var boneParent = ownerSkeleton.get_bone_parent(get_bone_id())
	var physicsBoneParent = findPhysicsBone(boneParent)
	if boneParent and physicsBoneParent:
		add_child(activeRagJoint)
		activeRagJoint.position = (self.position - physicsBoneParent.position)
		activeRagJoint.node_a = findPhysicsBone(boneParent).get_path()
		activeRagJoint.node_b = self.get_path()
		activeRagJoint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
		activeRagJoint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
		activeRagJoint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
		#if joint_type == PhysicalBone3D.JOINT_TYPE_6DOF:
			#activeRagJoint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,findPhysicsBone(boneParent).get("joint_constraints/x/angular_limit_upper"))
			#activeRagJoint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,findPhysicsBone(boneParent).get("joint_constraints/x/angular_limit_lower"))
			#activeRagJoint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,findPhysicsBone(boneParent).get("joint_constraints/y/angular_limit_upper"))
			#activeRagJoint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,findPhysicsBone(boneParent).get("joint_constraints/y/angular_limit_lower"))
			#activeRagJoint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,findPhysicsBone(boneParent).get("joint_constraints/z/angular_limit_upper"))
			#activeRagJoint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,findPhysicsBone(boneParent).get("joint_constraints/z/angular_limit_lower"))
		#joint_type = PhysicalBone3D.JOINT_TYPE_NONE
		activeRagJoint.name = "AR_%s"%ownerSkeleton.get_bone_name(get_bone_id())
		activeRagdollJoint = activeRagJoint


func doPulverizeEffect()->void:
	if canBeDismembered and !has_meta("exploded"):
		var gib = gameManager.createGib(global_position)
		gib.velocity += linear_velocity
		#doBleed()
		gameManager.createPulverizeSound(global_position)
		gameManager.createBloodPuff(global_position,randi_range(1,3),randi_range(4,10))
		collision_layer = 0
		collision_mask = 1
		joint_type = JOINT_TYPE_NONE
		for childrenIDs in getBoneChildren(ragdoll.ragdollSkeleton,self):
			var bone
			bone = findPhysicsBone(childrenIDs)
			if is_instance_valid(bone):
				bone.doPulverizeEffect()
				#bone.collision_layer = 0
				#bone.collision_mask = 0
				#bone.queue_free()
				#findPhysicsBone(childrenIDs).mass = 0
		#for i in randi_range(1,6):
			#gameManager.createDroplet(global_position,currentVelocity*0.25)
		#gameManager.sprayBlood(global_position,randi_range(1,5),20,1.2)
		#mass = 0.01
		queue_free()
		#createBurstOfBlood(10,15,25)

func doBleed()->void:
	if !hasBled and canBleed and !has_meta("exploded"):
		gameManager.createBloodPool(global_position,randf_range(0.3,1.6))
		hasBled = true

func boneCollision(body:Node)->void:
	var colliders : Array = get_colliding_bodies()
	var velocityHit : float = linear_velocity.length() *2

	if audioCooldown > 0 or boneState == true:
			return

	for i in colliders:
		if i is not PhysicalBone3D and i != self:
			if velocityHit >= heavyImpactThreshold:
				if is_instance_valid(audioStreamPlayer):
					audioStreamPlayer.stream = heavyImpactSounds
					audioStreamPlayer.play()
					audioCooldown = 0.25
					healthComponent.damage(velocityHit * 7)
			elif velocityHit >= mediumImpactThreshold:
				if is_instance_valid(audioStreamPlayer):
					audioStreamPlayer.stream = mediumImpactSounds
					audioStreamPlayer.play()
					audioCooldown = 0.45
			elif velocityHit >= lightImpactThreshold:
				if is_instance_valid(audioStreamPlayer):
					audioStreamPlayer.stream = lightImpactSounds
					audioStreamPlayer.play()
					audioCooldown = 0.55

			##Create Blood
			if velocityHit > 8.8:
				if is_instance_valid(healthComponent):
					gameManager.createDroplet(global_position,currentVelocity* 0.15)
					healthComponent.damage(velocityHit * 2)

#func doActiveRagdoll(value:bool)->void:
	#if get_owner().targetSkeleton != null:
		#var boneTarget = get_owner().targetSkeleton.global_transform * get_owner().targetSkeleton.get_bone_global_pose(get_bone_id())
		#var boneTargetRotation = get_owner().targetSkeleton.quaternion * get_owner().targetSkeleton.get_bone_pose_rotation(get_bone_id())
		#print("%s Rotation : %s"%[name,boneTargetRotation])
