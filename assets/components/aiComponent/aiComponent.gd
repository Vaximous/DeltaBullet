@tool
class_name AIComponent
extends Node3D

signal alert_to(alert_type:AlertComponent.ALERT_TYPE,alert_node:Node3D,alert_position:Vector3,perp:Node3D)

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
			navigationAgent.target_position = targetPosition

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
			#i.damaged.connect(setToAttackState)
			aimCast.add_exception(i)
var lookTween: Tween
var castLerp: Transform3D
##AI Manager
##AI Manager runs AI logic if this is set to true
var ai_process_enabled: bool = true
var last_ai_process_tick: int
var detection_amount : float = 0
var sprint : bool = false


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

	if Engine.get_physics_frames() % 16 == 0:
		evaluate_body()

	if navigationAgent.is_navigation_finished():
		pawnOwner.direction = Vector3.ZERO
		return

	if !navigationAgent.is_target_reachable(): return

	if NavigationServer3D.map_get_iteration_id(navigationAgent.get_navigation_map()) == 0:
		return

	var dist_to_final = navigationAgent.distance_to_target()
	#print(dist_to_final)
	if dist_to_final >= 1:
		sprint = true
	else:
		sprint = false

	_updateMovementState(pawnOwner)
	nextPosition = navigationAgent.get_next_path_position()
	var dir = pawnOwner.global_position.direction_to(nextPosition)
	navigationAgent.velocity = dir
	pawnOwner.direction = safeVelocity

	#print(nextPosition)

	#if !navigationAgent.is_navigation_finished():

func _updateMovementState(pawn: BasePawn) -> void:
	if !pawn.isCurrentlyMoving():
		# Idle states
		if pawn.isCrouching:
			pawn.setMovementState.emit(pawn.movementStates["crouch"])
		elif pawn.isInCover:
			pawn.setMovementState.emit(pawn.movementStates["coveridle"])
		else:
			pawn.setMovementState.emit(pawn.movementStates["standing"])
		return

	# Moving
	if sprint and !pawn.isInCover:
		pawn.setMovementState.emit(pawn.movementStates["sprint"])
		pawn.isCrouching = false
	elif pawn.isCrouching:
		pawn.setMovementState.emit(pawn.movementStates["crouchWalk"])
	elif pawn.isInCover:
		pawn.setMovementState.emit(pawn.movementStates["coverwalk"])
	else:
		pawn.setMovementState.emit(pawn.movementStates["walk"])

func evaluate_body(_body: Node3D = null) -> void:
	for i in %aiArea.get_overlapping_bodies():
		if i is BasePawn:
			if canSeeAtPosition(i.get_pawn_center()) and i != pawnOwner:
				if !pawnsCanSee.has(i):
					pawnsCanSee.append(i)
				if !checkIfTargetIsOnTeam(i) or checkIfTargetIsOnHostileTeam(i):
					if !targetedPawns.has(i):
						targetedPawns.append(i)
			elif !canSeeAtPosition(i.get_pawn_center()) or pawnOwner.global_position.distance_to(i.global_position) > maxDetectionRange:
				if pawnsCanSee.has(i):
					pawnsCanSee.erase(i)

			if targetedPawns.has(i):
				if canSeeAtPosition(i.get_pawn_center()):
					#print("Can see %s: %s"%[i.name,canSeeAtPosition(i.get_pawn_center())])
					%stateChart.send_event("begin_search")


func searching(_delta)->void:
	%detectionNotice.global_position = Vector3(global_position.x,global_position.y + 2,global_position.z)
	%detectionNotice.modulate = Color(Color.WHITE,detection_amount/99)

	var nearestTarget : BasePawn

	if !targetedPawns.is_empty():
		for i in targetedPawns:
			if !is_instance_valid(i) or i.isPawnDead:
				if nearestTarget == i:
					nearestTarget = null
					%stateChart.set_expression_property("nearestTarget",null)
				targetedPawns.erase(i)
				%stateChart.set_expression_property("nearestTarget",null)
				%stateChart.send_event("cancel_search")
				return


			if !nearestTarget and !i.isPawnDead:
				nearestTarget = i
				%stateChart.set_expression_property("nearestTarget",i)
			else:
				if nearestTarget.global_position.distance_to(pawnOwner.global_position) > i.global_position.distance_to(pawnOwner.global_position):
					nearestTarget = i
					%stateChart.set_expression_property("nearestTarget",i)


		if detection_amount <= 0:
			%stateChart.send_event("cancel_search")
			set_detection_amount(0)

		if detection_amount >= 100:
			%stateChart.set_expression_property("is_attacking",true)
			%stateChart.send_event("begin_attack")
			#set_detection_amount(0)

	var distance = nearestTarget.global_position.distance_to(pawnOwner.global_position)
	if !is_instance_valid(nearestTarget) or !canSeeAtPosition(nearestTarget.get_pawn_center()):
		add_detection_amount(-0.5)
		if detection_amount >= 0.5:
			%stateChart.send_event("investigate")
	else:
		add_detection_amount(2 * distance)
		lookAtPosition(nearestTarget.get_pawn_center())
		%stateChart.set_expression_property("lastKnownPosition",nearestTarget.global_position)

func investigate():
	navigationAgent.target_position = %stateChart.get_expression_property("lastKnownPosition", pawnOwner.global_position)
	pawnOwner.meshLookAt = false

func move_to_target_random():
	var target = %stateChart.get_expression_property("nearestTarget", null)
	if !%stateChart.get_expression_property("too_far", false):
		%stateChart.set_expression_property("too_far",true)
		navigationAgent.target_position = Util.get_random_position_around_origin(target.global_position,randf_range(4,8))
	#pawnOwner.meshLookAt = false
	await navigationAgent.navigation_finished
	%stateChart.set_expression_property("too_far",false)
	%stateChart.send_event("go_idle")

func move_away_from_target():
	if !%stateChart.get_expression_property("too_close", false):
		%stateChart.set_expression_property("too_close",true)
		navigationAgent.target_position = Util.get_random_position_around_origin(pawnOwner.global_position,randf_range(4,8))
	#pawnOwner.meshLookAt = false
	await navigationAgent.navigation_finished
	%stateChart.set_expression_property("too_close",false)
	%stateChart.send_event("go_idle")

##Returns ai_process_enabled
func is_ai_processing() -> bool:
	return ai_process_enabled


##Sets ai_process_enabled
func set_ai_processing(enabled: bool) -> void:
	ai_process_enabled = enabled

func add_detection_amount(amount:float)->float:
	detection_amount += amount
	%stateChart.set_expression_property("detection_amount",detection_amount)
	return detection_amount

func set_detection_amount(amount:float)->float:
	detection_amount = amount
	%stateChart.set_expression_property("detection_amount",detection_amount)
	return detection_amount

func removeAI() -> void:
	if gameManager.targetedEnemies.has(self):
		gameManager.targetedEnemies.erase(self)

func shoot_at_enemy(_delta:float)->void:
	var target : BasePawn
	if !is_instance_valid(%stateChart.get_expression_property("nearestTarget", null)): return
	target = %stateChart.get_expression_property("nearestTarget", null)
	if !target or target.isPawnDead:
		%stateChart.send_event("stop_attack_movement")
		%stateChart.send_event("stop")
		%stateChart.set_expression_property("is_attacking",false)
		return

	var distance = target.global_position.distance_to(pawnOwner.global_position)
	if Engine.get_physics_frames() %randi_range(2,4) == 0:
		if canSeeAtPosition(target.get_pawn_center()):
			%stateChart.set_expression_property("lastKnownPosition",target.global_position)
			lookAtPosition(target.get_pawn_center())

			if distance <= 5:
				%stateChart.send_event("too_close")

			if distance <= maxAttackRange:
				##If the target is within the max range, start shooting
				if getCurrentWeapon():
					if !pawnOwner.isStaggered and getCurrentWeapon().currentAmmo > 0:
						if Engine.get_physics_frames() %randi_range(4,10) == 0:
							getCurrentWeapon().weaponCast = aimCast
							getCurrentWeapon().fire()
							%stateChart.set_expression_property("is_attacking",true)
						#aiOwner.stopMoving()

					##Check if needs to reload
					if !pawnOwner.isStaggered and getCurrentWeapon().currentAmmo <= 0 and !getCurrentWeapon().isReloading and !getCurrentWeapon().isFiring and getCurrentWeapon().currentMagSize > 0:
						getCurrentWeapon().reloadWeapon()
				else:
					equip_random_weapon()
			else:
				# Change this to a "get closer" movement state
				%stateChart.set_expression_property("is_attacking",false)
				%stateChart.send_event("investigate")

		else:
			%stateChart.set_expression_property("is_attacking",false)
			%stateChart.send_event("investigate")

##Returns time since last AI process in seconds
func get_and_update_ai_process_delta(time_msec: int) -> float:
	var delta_msec = last_ai_process_tick - time_msec
	last_ai_process_tick = time_msec
	return float(delta_msec / 1000.0)

func equip_random_weapon()->void:
	if pawnOwner.itemInventory.size() > 0:
		pawnOwner.currentItemIndex = randi_range(1,pawnOwner.itemInventory.size())

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
			pass
			#stateMachine.change_state("Idle")
		1:
			pass
			#stateMachine.change_state("Wander")
		2:
			pass
			#stateMachine.change_state("Patrol")


func setToAttackState(_amount, _impulse, _vector, dealer: BasePawn) -> void:
	if !targetedPawns.has(dealer):
		targetedPawns.append(dealer)

	#print("%s is Changing to attack" %pawnOwner.name)
	#stateMachine.change_state("Attack")
	if dealer:
		lookAtPosition(dealer.global_position)


func lookAtPosition(pos: Vector3, snap: bool = false) -> void:
	if pos == Vector3.ZERO:
		print("AI is looking zero, abort.")
		return
#	var lookModifier = aimTargetRecoil * aimRecoilStrength
	var completePosition = pos + aimTargetRecoil * aimRecoilStrength
	aimCast.global_position = Vector3(pawnOwner.global_position.x, pawnOwner.global_position.y + 1.5, pawnOwner.global_position.z)
	aimCast.target_position.z = -maxAttackRange

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
	if !gameManager.world: return false
	var exclude : Array[RID] = [pawnOwner.get_rid()]
	var verdict : bool
	for i in pawnOwner.getAllHitboxes():
		exclude.append(i.get_rid())

	verdict = Util.is_line_of_sight(
	get_world_3d().direct_space_state,
	pawnOwner.get_pawn_center(),object.global_position,
	aimCast.collision_mask,
	false,
	true,
	exclude
	)
	return verdict

func canSeeAtPosition(pos: Vector3) -> bool:
	if !gameManager.world: return false
	var exclude : Array[RID] = [pawnOwner.get_rid()]
	var verdict : bool
	for i in pawnOwner.getAllHitboxes():
		exclude.append(i.get_rid())

	verdict = Util.is_line_of_sight(
	get_world_3d().direct_space_state,
	pawnOwner.get_pawn_center(),pos,
	aimCast.collision_mask,
	false,
	true,
	exclude
	)
	return verdict


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
	#stateMachine._ai_process(physics_delta, ai_process_delta)

	nextPosition = navigationAgent.get_next_path_position()

	var dir = pawnOwner.global_position.direction_to(nextPosition)

	navigationAgent.velocity = dir

	#if !navigationAgent.is_navigation_finished():
	pawnOwner.direction = safeVelocity


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	safeVelocity = safe_velocity


func _on_alert_to(alert_type: AlertComponent.ALERT_TYPE, alert_node: Node3D, alert_position: Vector3, perp: Node3D) -> void:
	print(alert_node)
	if alert_node is RagdollBone:
		for i in alert_node.ragdoll.get_meta(&"teams"):
			if pawnTeam.has(i):
				if !alert_node: return
				%stateChart.set_expression_property("alert_perp",perp)
				#print(perp)
				%stateChart.set_expression_property("alert_type",alert_type)
				%stateChart.set_expression_property("alert_node",alert_node)
				if !is_instance_valid(alert_node.ragdoll.physicsBones[3]): return
				%stateChart.set_expression_property("alert_pos",alert_node.ragdoll.physicsBones[3].global_position)
				%stateChart.send_event("investigate_alert")
	elif alert_node is Weapon:
		#for i in alert_node.get_meta(&"teams"):
			#if pawnTeam.has(i):
		if !alert_node: return
		%stateChart.set_expression_property("alert_perp",perp)
		#print(perp)
		%stateChart.set_expression_property("alert_type",alert_type)
		%stateChart.set_expression_property("alert_node",alert_node)
		if !is_instance_valid(perp): return
		%stateChart.set_expression_property("lastKnownPosition",perp.global_position)
		%stateChart.send_event("investigate")

func investigate_alert()->void:
	%stateChart.set_expression_property("is_alerted",true)
	#lookAtPosition(%stateChart.get_expression_property("alert_pos"))
	navigationAgent.target_position = %stateChart.get_expression_property("alert_pos")
	await navigationAgent.is_navigation_finished
	print(%stateChart.get_expression_property("alert_type"))
	match %stateChart.get_expression_property("alert_type"):
		0:
			%stateChart.send_event("to_idle")
		1:
			if is_instance_valid(%stateChart.get_expression_property("alert_perp")):
				%stateChart.set_expression_property("nearestTarget", %stateChart.get_expression_property("alert_perp"))
				%stateChart.set_expression_property("lastKnownPosition",%stateChart.get_expression_property("alert_perp").global_position)
				%stateChart.set_expression_property("is_alerted",false)
				#%stateChart.set_expression_property("is_attacking",false)
			%stateChart.send_event("begin_attack")
