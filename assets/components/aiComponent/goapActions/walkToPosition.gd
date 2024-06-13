extends GOAP_Action


##Pathfinding
@export var aiComponent : AIComponent
@export var navAgent : NavigationAgent3D
@export var currLocation:Vector3
@export var newVelocity:Vector3
var reachedTarget : bool = false
var safeVel


func _ready() -> void:
	navAgent.path_changed.connect(_on_nav_agent_path_changed)
	navAgent.velocity_computed.connect(_on_nav_agent_velocity_computed)
	navAgent.target_reached.connect(_on_nav_agent_target_reached)


func _execute_action():
	super()
	#Console.add_console_message("%s,Starting.."%[get_path()])
	if navAgent != null:
		#Signal connection..

		if !navAgent.target_reached.is_connected(_on_nav_agent_target_reached):
			navAgent.target_reached.connect(_on_nav_agent_target_reached)

		if !navAgent.path_changed.is_connected(_on_nav_agent_path_changed):
			navAgent.path_changed.connect(_on_nav_agent_path_changed)

		if !navAgent.velocity_computed.is_connected(_on_nav_agent_velocity_computed):
			navAgent.velocity_computed.connect(_on_nav_agent_velocity_computed)
		if !navAgent.is_target_reachable():
			navAgent.set_velocity(Vector3.ZERO)
			aiComponent.pawnOwner.direction = Vector3.ZERO
			cancel_action()


func _physics_process(delta: float) -> void:
		pass
		cancel_action()

func _on_nav_agent_target_reached():
	if navAgent:
		#Console.add_console_message("stopping ai on " + owner.pawnOwner.name)
		aiComponent.pawnOwner.direction = Vector3.ZERO
		reachedTarget = true
		finish_action()
		action_completed.emit()
		#Console.add_console_message("%s, reachedtarget = %s"%[owner.pawnOwner.name,reachedTarget])


func _on_nav_agent_velocity_computed(safe_velocity):
	safeVel = safe_velocity
	if navAgent:
		if aiComponent.pawnOwner != null:
			aiComponent.pawnOwner.direction = safe_velocity


func _on_nav_agent_path_changed():
	reachedTarget = false
