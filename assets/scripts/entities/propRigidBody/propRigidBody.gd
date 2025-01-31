extends RigidBody3D
class_name PropRigidBody
signal onHit(hitImpulse,hitPoint)
@export_category("Prop RigidBody")
var audioStreamPlayer : AudioStreamPlayer3D
var audioCooldown : float = 0.0
var exclusionArray : Array[RID]
var cooldownTimer:Timer
##If enabled, the prop will have an impulse applied when shot
@export var hitImpulseEnabled : bool = true
@export_category("Thresholds")
@export var heavyImpactThreshold :float = 14
@export var mediumImpactThreshold :float = 4
@export var lightImpactThreshold :float = 0.5
@export_category("Sounds")
##Light impact sounds
@export var lightImpactSounds : AudioStream
##Medium impact sounds
@export var mediumImpactSounds : AudioStream
##Heavy impact sounds
@export var heavyImpactSounds : AudioStream
@export_subgroup("Prop")
@export var healthComponent : HealthComponent
@export var propMaterial:DB_PhysicsMaterial:
	set(value):
		propMaterial = value
		if is_instance_valid(propMaterial):
			setMaterial(propMaterial)
		else:
			setMaterial(load("res://assets/resources/PhysicsMaterials/generic_physics_material.tres"))

func createAudioPlayer()->void:
	audioStreamPlayer = AudioStreamPlayer3D.new()
	add_child(audioStreamPlayer)
	audioStreamPlayer.max_polyphony = 2
	audioStreamPlayer.max_db = 15
	audioStreamPlayer.max_distance = 32
	audioStreamPlayer.unit_size = 0.5
	audioStreamPlayer.bus = &"Sounds"
	audioStreamPlayer.attenuation_filter_db = 0
	audioStreamPlayer.attenuation_filter_cutoff_hz = 3000

func _ready() -> void:
	setupPhysicsProp()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if audioCooldown > 0:
			return

	if state.get_contact_count() > 0:
		if exclusionArray.has(state.get_contact_collider(0)):
			return
		#var contactNormal = state.get_contact_local_normal(0)
		#var contactDot = state.get_contact_local_velocity_at_position(0).normalized().dot(contactNormal)
		var contactForce = state.get_contact_impulse(0).length()*2
		##contactForce = clampf(contactForce,0,heavyImpactThreshold)
		##audioStreamPlayer.attenuation_filter_db = lerp(-20, 0, clamp(abs(contactDot) * contactForce, 0, 1))

		if contactForce >= heavyImpactThreshold:
			if is_instance_valid(audioStreamPlayer):
				audioStreamPlayer.stream = heavyImpactSounds
				audioStreamPlayer.play()
				audioCooldown = 0.25
			if is_instance_valid(healthComponent):
				healthComponent.damage(contactForce * randi_range(2,16))

		elif contactForce >= mediumImpactThreshold:
			if is_instance_valid(audioStreamPlayer):
				audioStreamPlayer.stream = mediumImpactSounds
				audioStreamPlayer.play()
				audioCooldown = 0.25
			if is_instance_valid(healthComponent):
				healthComponent.damage(contactForce * randi_range(2,3))

		elif contactForce >= lightImpactThreshold:
			if is_instance_valid(audioStreamPlayer):
				audioStreamPlayer.stream = lightImpactSounds
				audioStreamPlayer.play()
				audioCooldown = 0.35
			if is_instance_valid(healthComponent):
				healthComponent.damage(contactForce + randi_range(0,5))

func setCooldownTimer()->void:
	cooldownTimer = Timer.new()
	add_child(cooldownTimer)
	cooldownTimer.stop()
	cooldownTimer.wait_time = 0.15
	cooldownTimer.autostart = false
	cooldownTimer.one_shot = false
	cooldownTimer.timeout.connect(subtractCooldown)
	cooldownTimer.start()

func subtractCooldown()->void:
	if audioCooldown > 0:
		audioCooldown -= 0.1

func setupPhysicsProp()->void:
	createAudioPlayer()
	setCooldownTimer()

func setMaterial(resource:DB_PhysicsMaterial)->void:
	set_meta(&"physics_material_override", resource)

func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	if hitImpulseEnabled:
		onHit.emit(hitImpulse,hitPoint)
		apply_impulse(hitImpulse, hitPoint)
	if is_instance_valid(healthComponent):
		healthComponent.damage(int(dmg),dealer)
