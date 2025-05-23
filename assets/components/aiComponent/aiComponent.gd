@tool
extends Node3D
class_name AIComponent
signal targetPathReached
signal pathPointReached
signal targetUnreachable
signal onScan
signal canSeeSomething
signal interactSpeakTrigger
signal visibleObject(object:Node3D,visibleposition:Vector3)
##Onready
@onready var navigationAgent : NavigationAgent3D = $navigationAgent3d
@onready var aimCast : RayCast3D = $aiAimcast:
	set(value):
		aimCast = value
@onready var aimCastEnd : Marker3D = $aiAimcast/aiAimcastEnd
@onready var pawnDebugLabel : Label3D = $debugPawnStats
@onready var stateMachine : FiniteStateMachine = $pawnFSM

var pawnOwner : BasePawn = null
@export_subgroup("Pawn")
@export var pawnName : String = ""
@export var forceAnimation : bool = false
@export var animationToForce : String = ""
@export_enum("Idle","Wander","Patrol") var pawnType : int = 0
@export var pawnColor : Color = Color(1.0,0.74,0.44,1.0):
	set(value):
		pawnColor = value
		pawnOwner.pawnColor = value
@export_subgroup("Pathing")
##The next position for the AI to go towards
var nextPosition : Vector3 = Vector3.ZERO
##AI's requested location
@export var targetPosition : Vector3 = Vector3.ZERO:
	set(value):
		targetPosition = value
		navigationAgent.target_position = targetPosition

@export var newVelocity:Vector3 = Vector3.ZERO
@export var safeVelocity:Vector3 = Vector3.ZERO

##AI Manager
##AI Manager runs AI logic if this is set to true
var ai_process_enabled : bool = true
##Returns ai_process_enabled
func is_ai_processing() -> bool:
	return ai_process_enabled
##Sets ai_process_enabled
func set_ai_processing(enabled : bool) -> void:
	ai_process_enabled = enabled
var last_ai_process_tick : int
@export_category("Debug")
static var instances : Array[AIComponent]

func _ready() -> void:
	setPawnType()

func _enter_tree() -> void:
	instances.append(self)


func _exit_tree() -> void:
	if instances.has(self):
		instances.erase(self)


func removeAI()->void:
	if gameManager.targetedEnemies.has(self):
				gameManager.targetedEnemies.erase(self)


##Returns time since last AI process in seconds
func get_and_update_ai_process_delta(time_msec : int) -> float:
	var delta_msec = last_ai_process_tick - time_msec
	last_ai_process_tick = time_msec
	return float(delta_msec / 1000)


func _ai_process(physics_delta : float) -> void:
	var ai_process_delta = get_and_update_ai_process_delta(Time.get_ticks_msec())
	if navigationAgent and is_ai_processing():
		stateMachine._ai_process(physics_delta,ai_process_delta)

		if navigationAgent.is_navigation_finished():
			pawnOwner.direction = Vector3.ZERO
			nextPosition = navigationAgent.get_next_path_position()
			return


		nextPosition = navigationAgent.get_next_path_position()

		pawnOwner.direction = pawnOwner.global_position.direction_to(nextPosition)

func setPawnDirection(dir:Vector3)->void:
	if pawnOwner.direction != dir:
		pawnOwner.global_position.direction_to(dir)

func setNextPosition(nextPos:Vector3)->void:
	if nextPosition != nextPos:
		nextPosition = nextPos


func getDirFromAngle(angleInDeg:float) -> Vector3:
	return Vector3(sin(angleInDeg * deg_to_rad(angleInDeg)),0,cos(angleInDeg*deg_to_rad(angleInDeg)))

func setPawnType()->void:
	await get_tree().process_frame
	match pawnType:
		0:
			stateMachine.change_state("Idle")
		1:
			stateMachine.change_state("Wander")
		2:
			stateMachine.change_state("Patrol")
