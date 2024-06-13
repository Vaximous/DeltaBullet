extends State
class_name AttackState
@export_category("Attack AI")
@export var hasWeaponToEquip : bool
@export var sightCast : RayCast3D
@export var sightcastEnd : Marker3D
@export var navAgent : NavigationAgent3D
@export var currLocation:Vector3
@export var newVelocity:Vector3
var pawnTarget
var aiMoveTime : bool = false
# Called when the node enters the scene tree for the first time.

func enterState()->void:
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func updateState(delta)->void:
	pass

func _on_nav_agent_target_reached()->void:
	if get_owner().navAgent != null:
		if get_owner().pawnHasTarget:
			get_owner().navAgent.target_desired_distance = randf_range(2,6)


func _on_nav_agent_velocity_computed(safe_velocity)->void:
	if pawnTarget:
		if get_owner().navAgent != null:
			get_owner().pawnOwner.direction = get_owner().pawnOwner.direction.move_toward(safe_velocity, 0.25)

func exitState()->void:
	$attackTimer.stop()
	aiMoveTime = false
	pawnTarget = null

func moveToEnemy()->void:
	if pawnTarget:
		if get_owner().navAgent != null:
			aiMoveTime = true
			get_owner().moveTo.position = pawnTarget.position
			get_owner().navAgent.set_target_position(get_owner().moveTo.position)
			#get_owner().navAgent.target_desired_distance = randf_range(0.02,0.06)


func _on_attack_timer_timeout()->void:
	$attackTimer.start()
	if get_owner().pawnHasTarget:
		if get_owner().navAgent != null:
			get_owner().navAgent.target_desired_distance = randf_range(2,6)

func addToHatedPawns(overlappingPawn)->void:
	if get_owner().navAgent != null:
		for pawns in get_owner().hatedPawns:
			if overlappingPawn != pawns:
				get_owner().hatedPawns.append(overlappingPawn)
