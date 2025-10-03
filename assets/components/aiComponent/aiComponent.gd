@tool
class_name AIComponent
extends Node3D

@export var aimSpeed: float = 8
@export var aimTargetRecoil: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var aimRecoilStrength: float = 0.15
@export var recoilReturnSpeed: float = 5.5
@export var aimRecoil: Vector3 = Vector3.ZERO
@export_subgroup("Pawn")
## What team(s) the pawn is apart of, if the enemy is on the same team it will refrain from adding it to lists beyond "pawnCanSee"
@export var pawnTeam: Array[StringName] = [&"Default"]:
	set(value):
		pawnTeam = value
		if pawnOwner:
			pawnOwner.set_meta(&"teams", pawnTeam)
## What team(s) the pawn is apart of, if the enemy is on the same team it will refrain from adding it to lists beyond "pawnCanSee"
@export var hatedPawnTeams: Array[StringName] = []:
	set(value):
		hatedPawnTeams = value
		if pawnOwner:
			pawnOwner.set_meta(&"hatedTeams", hatedPawnTeams)
## Max detection range, how far it can seek the enemy
@export_range(2.0, 50.0) var maxDetectionRange: float = 15.0
## Maximum range the target can be in before it stops shooting
@export_range(1.0, 25.0) var maxAttackRange: float = 25.0:
	set(value):
		maxAttackRange = value
		if aimCast:
			aimCast.target_position.z = -maxAttackRange
## Maximum range the target can be in before it stops seeking them
@export_range(1.0, 25.0) var maxRange: float = 15.0
@export var pawnName: String = ""
@export var forceAnimation: bool = false
@export var animationToForce: String = ""
@export_enum("Idle", "Wander", "Patrol") var pawnType: int = 0
@export var pawnColor: Color = Color(1.0, 0.74, 0.44, 1.0):
	set(value):
		pawnColor = value
		pawnOwner.pawnColor = value
@export_subgroup("Pathing")
##The next position for the AI to go towards
var nextPosition: Vector3 = Vector3.ZERO
##AI's requested location
@export var targetPosition: Vector3 = Vector3.ZERO:
	set(value):
		targetPosition = value
		if navigationAgent.target_position != targetPosition:
			navigationAgent.target_position = Vector3(targetPosition.x, targetPosition.y + 0.03, targetPosition.z)

@export var safeVelocity: Vector3 = Vector3.ZERO
@export var targetedPawns: Array[BasePawn]
@export var pawnsCanSee: Array[BasePawn]
@export_category("Debug")
static var instances: Array[AIComponent]

var pawnOwner: BasePawn = null:
	set(value):
		pawnOwner = value
		aimCast.add_exception(pawnOwner)
		for i in pawnOwner.getAllHitboxes():
			i.damaged.connect(setToAttackState)
			aimCast.add_exception(i)
var lookTween: Tween
var castLerp: Transform3D
##AI Manager
##AI Manager runs AI logic if this is set to true
var ai_process_enabled: bool = true
var last_ai_process_tick: int

#signal targetPathReached
#signal pathPointReached
#signal targetUnreachable
#signal onScan
#signal canSeeSomething
#signal interactSpeakTrigger
#signal visibleObject(object:Node3D,visibleposition:Vector3)
##Onready
@onready var navigationAgent: NavigationAgent3D = $navigationAgent3d
@onready var aimCast: RayCast3D = $aiAimcast:
	set(value):
		aimCast = value
@onready var aimCastEnd: Marker3D = $aiAimcast/aiAimcastEnd
@onready var pawnDebugLabel: Label3D = $debugPawnStats
@onready var stateMachine: FiniteStateMachine = $pawnFSM


func _enter_tree() -> void:
	instances.append(self)


func _ready() -> void:
	setPawnType()

	#navigationAgent.velocity = nextPosition
	#print(pawnOwner.direction.move_toward((nextPosition-pawnOwner.global_transform.origin).normalized(),0.25))

	#pawnOwner.direction = pawnOwner.direction.move_toward(dir,0.25)
	#pawnOwner.movementController.movementDirection = nextPosition


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return

	if pawnOwner.forceAnimation: return

	#Pawn Recoil Work
	aimTargetRecoil.x = lerp(aimTargetRecoil.x, 0.01, recoilReturnSpeed * delta)
	aimTargetRecoil.y = lerp(aimTargetRecoil.y, 0.01, recoilReturnSpeed * delta)
	aimTargetRecoil.z = lerp(aimTargetRecoil.z, 0.01, recoilReturnSpeed * delta)

	##Add the pawns that the pawn currently has in their view
	for i in gameManager.allPawns:
		if canSeeObject(i) and i != pawnOwner and pawnOwner.global_position.distance_to(i.global_position) < maxDetectionRange:
			if !pawnsCanSee.has(i):
				pawnsCanSee.append(i)
			##For now just switch to searching
			if stateMachine.current_state != stateMachine.get_state("Attack"):
				if !checkIfTargetIsOnTeam(i) or checkIfTargetIsOnHostileTeam(i):
					if !targetedPawns.has(i):
						targetedPawns.append(i)
					stateMachine.change_state("Attack")
		elif !canSeeObject(i) or pawnOwner.global_position.distance_to(i.global_position) > maxDetectionRange:
			if pawnsCanSee.has(i):
				pawnsCanSee.erase(i)


##Returns ai_process_enabled
func is_ai_processing() -> bool:
	return ai_process_enabled


##Sets ai_process_enabled
func set_ai_processing(enabled: bool) -> void:
	ai_process_enabled = enabled


func removeAI() -> void:
	if gameManager.targetedEnemies.has(self):
		gameManager.targetedEnemies.erase(self)


##Returns time since last AI process in seconds
func get_and_update_ai_process_delta(time_msec: int) -> float:
	var delta_msec = last_ai_process_tick - time_msec
	last_ai_process_tick = time_msec
	return float(delta_msec / 1000)


func setPawnDirection(dir: Vector3) -> void:
	if pawnOwner.direction != dir:
		pawnOwner.global_position.direction_to(dir)


func setNextPosition(nextPos: Vector3) -> void:
	if nextPosition != nextPos:
		nextPosition = nextPos


func getDirFromAngle(angleInDeg: float) -> Vector3:
	return Vector3(sin(angleInDeg * deg_to_rad(angleInDeg)), 0, cos(angleInDeg * deg_to_rad(angleInDeg)))


func setPawnType() -> void:
	await get_tree().process_frame
	match pawnType:
		0:
			stateMachine.change_state("Idle")
		1:
			stateMachine.change_state("Wander")
		2:
			stateMachine.change_state("Patrol")


func setToAttackState(amount, impulse, vector, dealer: BasePawn) -> void:
	if !targetedPawns.has(dealer):
		targetedPawns.append(dealer)

	#print("%s is Changing to attack" %pawnOwner.name)
	stateMachine.change_state("Attack")
	if dealer:
		lookAtPosition(dealer.global_position)


func lookAtPosition(pos: Vector3, snap: bool = false) -> void:
	if pos == Vector3.ZERO:
		print("AI is looking zero, abort.")
		return
	var lookModifier = aimTargetRecoil * aimRecoilStrength
	var completePosition = pos + aimTargetRecoil * aimRecoilStrength

	if completePosition == Vector3.ZERO:
		print("AI is looking zero, abort.")
		return

	aimCast.look_at(completePosition)
	var dir = (aimCast.global_position - pos) + aimTargetRecoil * aimRecoilStrength
	if lookTween:
		lookTween.kill()
	lookTween = create_tween()
	if !pawnOwner.meshLookAt and !pawnOwner.isStaggered:
		pawnOwner.meshLookAt = true

	castLerp = castLerp.looking_at(-dir)
	pawnOwner.turnAmount = (-aimCast.rotation.x) + 0.1
	pawnOwner.meshRotation = gameManager.getShortTweenAngle(pawnOwner.meshRotation, aimCast.global_transform.basis.get_euler().y)
	pawnOwner.movementController.onSetCamRot(pawnOwner.meshRotation)
	lookTween.tween_property(pawnOwner, "meshRotation", gameManager.getShortTweenAngle(pawnOwner.meshRotation, aimCast.global_transform.basis.get_euler().y), aimSpeed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

	if snap:
		aimCast.transform = castLerp
		pawnOwner.meshRotation = aimCast.global_transform.basis.get_euler().y


func rayTest(from: Vector3, to: Vector3) -> Dictionary:
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = from
	ray.to = to
	ray.exclude.append(pawnOwner.get_rid())
	ray.collision_mask = aimCast.collision_mask
	var result = get_world_3d().direct_space_state.intersect_ray(ray)
	return result


func getCurrentWeapon() -> Weapon:
	return pawnOwner.currentItem


func canSeeObject(object: Node3D) -> bool:
	if !is_instance_valid(object): return false

	var pawnRID: Array[RID] = []
	pawnRID.append(pawnOwner.get_rid())
	var dist = pawnOwner.global_position.direction_to(object.global_position)
	var dotProd = dist.dot(-pawnOwner.pawnMesh.global_transform.basis.z)
	if dotProd > 0:
		var rayParams: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		rayParams.hit_from_inside = false
		rayParams.exclude = pawnRID
		rayParams.from = Vector3(pawnOwner.global_position.x, pawnOwner.global_position.y + 1, pawnOwner.global_position.z)
		rayParams.to = Vector3(object.global_position.x, object.global_position.y + 1, object.global_position.z)
		rayParams.collision_mask = aimCast.collision_mask
		var rayResults = get_world_3d().direct_space_state.intersect_ray(rayParams)
		#print(rayResults)
		if rayResults.is_empty():
			return true
		else:
			return false
	else:
		return false


func stopMoving(crouch: bool = false) -> void:
	targetPosition = pawnOwner.global_position
	pawnOwner.direction = Vector3.ZERO
	nextPosition = pawnOwner.global_position

	pawnOwner.isCrouching = crouch
	#pawnOwner.direction = pawnOwner.direction.move_toward(safe_velocity,0.25)
	#print(safe_velocity)


func checkIfTargetIsOnTeam(target: BasePawn) -> bool:
	if !is_instance_valid(target): return false
	var verdict: bool = false
	for team in pawnOwner.get_meta(&"teams"):
		if target.get_meta(&"teams").has(team): verdict = true
	return verdict


func checkIfTargetIsOnHostileTeam(target: BasePawn) -> bool:
	if !is_instance_valid(target): return false
	var verdict: bool = false
	for team in pawnOwner.get_meta(&"hatedTeams"):
		if target.get_meta(&"teams").has(team): verdict = true
	return verdict


func fireRecoil(setRecoilX: float = 0.0, setRecoilY: float = 0.0, setRecoilZ: float = 0.0, useSetRecoil: bool = false) -> void:
	if setRecoilX:
		aimRecoil.x += setRecoilX
	if setRecoilY:
		aimRecoil.y += setRecoilY
	if setRecoilZ:
		aimRecoil.z += setRecoilZ
	if !useSetRecoil:
		aimTargetRecoil += Vector3(randf_range(-2, aimRecoil.x), randf_range(-2, aimRecoil.y), randf_range(-aimRecoil.z, aimRecoil.z))
	else:
		aimTargetRecoil += Vector3(setRecoilX, randf_range(-setRecoilY, setRecoilY), randf_range(-setRecoilZ, setRecoilZ))


func _exit_tree() -> void:
	if instances.has(self):
		instances.erase(self)


func _ai_process(physics_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if pawnOwner.forceAnimation: return

	aimCast.global_position = Vector3(pawnOwner.global_position.x, pawnOwner.global_position.y + 1.5, pawnOwner.global_position.z)
	aimCast.target_position.z = -maxAttackRange
	var ai_process_delta = get_and_update_ai_process_delta(Time.get_ticks_msec())
	stateMachine._ai_process(physics_delta, ai_process_delta)

	nextPosition = navigationAgent.get_next_path_position()

	var dir = pawnOwner.global_position.direction_to(nextPosition)

	navigationAgent.velocity = dir

	#if !navigationAgent.is_navigation_finished():
	pawnOwner.direction = safeVelocity


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	safeVelocity = safe_velocity
