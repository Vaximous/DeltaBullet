@tool
extends Node3D
class_name AIComponent
signal targetUnreachable
signal onScan
signal canSeeSomething
signal interactSpeakTrigger
signal visibleObject(object:Node3D,visibleposition:Vector3)
@onready var visualMesh : MeshInstance3D = $visualMesh:
	set(value):
		visualMesh = value
		if Engine.is_editor_hint():
			visualMesh.mesh = createLOSWedge()
@onready var aimCast : RayCast3D = $aiAimcast:
	set(value):
		aimCast = value
@onready var aimCastEnd : Marker3D = $aiAimcast/aiAimcastEnd
@onready var pawnDebugLabel : Label3D = $debugPawnStats
@export_category("AI Component")
@export var pawnOwner : BasePawn:
	set(value):
		pawnOwner = value
		setExceptions()
		pawnOwner.itemChanged.connect(setWeaponCast)
		pawnOwner.onScreenNotifier.screen_entered.connect(enableAnimations)
		pawnOwner.onScreenNotifier.screen_exited.connect(disableAnimations)
		global_position = pawnOwner.pawnMesh.global_position
		global_position.y += 1
@export_category("Interaction")
@export_enum("Dialogue") var interactType : int = 0
@export var isInteractable : bool = false
var isInDialogue : bool
@export_category("Dialogue")
@export var dialogueStartingCamera : Marker3D
@export var dialogueString : String
@export_subgroup("Identification")
@export var pawnName : String
@export var aimSpeed : float = 0.75
@export_enum("Idle","Wander","Patrol") var pawnType = 0:
	set(value):
		pawnType = value
		setPawnType()
@export_enum("High","Normal","Retarded") var aiSkill : int = 1:
	set(value):
		aiSkill = value
		if value == 0:
			aimSpeed = 1.0
		elif value == 1:
			aimSpeed = 0.075
		elif value == 2:
			aimSpeed = 0.015
@export_subgroup("Nodes")
@export var pawnFSM : FiniteStateMachine:
	set(value):
		pawnFSM = value
		for state in pawnFSM.get_children():
			if state is StateMachineState:
				state.aiOwner = self
@export var navAgent : NavigationAgent3D
@export var navPointGrabber : Area3D
@export var visionTimer : Timer
@onready var pawnGrabber : Area3D = $pawnGrabber
@export_subgroup("Memory")
@onready var memorySpanTimer : Timer = $memorySpan
@export var memoryManager : AiMemoryManager:
	set(value):
		memoryManager = value
		memoryManager.brainOwner = self
#@export var memorySpan : float = 10.0
@export_subgroup("FOV Mesh")
var meshAngle:float = 1:
	set(value):
		meshAngle = value
		if visualMesh:
			visualMesh.mesh = createLOSWedge()
@export var meshHeight:float = 1.0:
	set(value):
		meshHeight = value
		if visualMesh:
			visualMesh.mesh = createLOSWedge()
@export var meshDistance:float = 10.0:
	set(value):
		meshDistance = value
		if visualMesh:
			visualMesh.mesh = createLOSWedge()
@export_subgroup("Overlap & Detection")
@export_flags_3d_physics var collisionMasks : int
@export var visibleObjects : Array = []
@export var chosenTarget : Node3D = null:
	set(value):
		chosenTarget = value
		if chosenTarget == null:
			pawnHasTarget = false
		else:
			pawnHasTarget = true
@export var pawnHasTarget : bool = false:
	set(value):
		#setExceptions()
		#aimCast.position = visionCast.position
		pawnHasTarget = value
		pawnOwner.freeAim = value
		pawnOwner.meshLookAt = value
@export_subgroup("Detection")
@export var currLocation:Vector3
@export var newVelocity:Vector3
@export_category("Debug")
var posSpheres : Array = []

func _ready() -> void:
	if !Engine.is_editor_hint():
		gameManager.getEventSignal("debugDisabled").connect(disableDebugInfo)
		gameManager.getEventSignal("debugEnabled").connect(enableDebugInfo)
		visualMesh.visible = false
		setExceptions()
		visionTimer.start()
		await get_tree().process_frame
		if isInteractable:
			setInteractablePawn(true)
		if pawnOwner:
			pawnOwner.healthComponent.healthDepleted.connect(ceaseAI)
	else:
		visualMesh.visible = true
		visualMesh.mesh = createFOVModel()
	setPawnType()

func createFOVModel()->ImmediateMesh:
	var _mesh : ImmediateMesh = ImmediateMesh.new()
	var FOVA = getDirFromAngle(-meshAngle/2)
	var FOVB = getDirFromAngle(meshAngle/2)
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	#_mesh.surface_add_vertex(position * meshDistance)
	_mesh.surface_add_vertex(FOVA * meshDistance)
	#_mesh.surface_add_vertex(position * meshDistance)
	_mesh.surface_add_vertex(FOVB * meshDistance)
	_mesh.surface_end()
	return _mesh

func createLOSWedge()->ArrayMesh:
	var _mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	var segs : int = 10
	var tris : int = (segs * 4) + 2 + 2
	var verts : int = tris * 3
	var vertArray : PackedVector3Array
	var bottomCenter : Vector3
	var bottomRight : Vector3
	var bottomLeft : Vector3

	var topCenter : Vector3
	var topLeft : Vector3
	var topRight : Vector3

	bottomCenter = Vector3.ZERO
	bottomRight = Quaternion.from_euler(Vector3(0, meshAngle/2,0)) * Vector3.FORWARD * meshDistance
	bottomLeft = Quaternion.from_euler(Vector3(0, -meshAngle/2,0)) * Vector3.FORWARD * meshDistance

	topCenter = bottomCenter + Vector3.UP * meshHeight
	topLeft = bottomLeft + Vector3.UP * meshHeight
	topRight = bottomRight + Vector3.UP * meshHeight

	var vert : int = 0

	#Left
	vertArray.push_back(bottomCenter)
	vertArray.push_back(bottomLeft)
	vertArray.push_back(topLeft)

	vertArray.push_back(topLeft)
	vertArray.push_back(topCenter)
	vertArray.push_back(bottomCenter)
	#Right
	vertArray.push_back(bottomCenter)
	vertArray.push_back(topCenter)
	vertArray.push_back(topRight)

	vertArray.push_back(topRight)
	vertArray.push_back(bottomRight)
	vertArray.push_back(bottomCenter)
	var currAngle : float = -meshAngle/2
	var deltaAngle : float = (meshAngle/2 * 2)/segs
	for segment in segs:
		bottomRight = Quaternion.from_euler(Vector3(0, currAngle,0)) * Vector3.FORWARD * meshDistance
		bottomLeft = Quaternion.from_euler(Vector3(0, currAngle + deltaAngle,0)) * Vector3.FORWARD * meshDistance

		topLeft = bottomLeft + Vector3.UP * meshHeight
		topRight = bottomRight + Vector3.UP * meshHeight

		#Far Side
		vertArray.push_back(bottomLeft)
		vertArray.push_back(bottomRight)
		vertArray.push_back(topRight)

		vertArray.push_back(topRight)
		vertArray.push_back(topLeft)
		vertArray.push_back(bottomLeft)

		#Top
		vertArray.push_back(topCenter)
		vertArray.push_back(topLeft)
		vertArray.push_back(topRight)
		#Bottom
		vertArray.push_back(bottomCenter)
		vertArray.push_back(bottomRight)
		vertArray.push_back(bottomLeft)

		currAngle += deltaAngle


	arrays[Mesh.ARRAY_VERTEX] = vertArray

	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return _mesh

func scan()->void:
	if pawnOwner != null:
		var pawnRID : Array[RID] = []
		pawnRID.append(pawnOwner.get_rid())
		visibleObjects.clear()
		#Console.add_rich_console_message("[color=green]%s Scanning.." %pawnName)
		var shape = PhysicsServer3D.sphere_shape_create()
		PhysicsServer3D.shape_set_data(shape,meshDistance)
		var params : PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		params.exclude = pawnRID
		params.shape_rid = shape
		params.transform.origin = pawnOwner.transform.origin
		#print(params.exclude)
		var world = get_world_3d().direct_space_state
		var result = world.intersect_shape(params)
		var count : int
		if !result.is_empty():
			#Console.add_rich_console_message("[color=green]%s" %result)
			count = result.size()
			for obj in result:
				#Console.add_rich_console_message("[color=green]%s" %obj)
				if canSeeObject(obj.collider):
					if gameManager.pawnDebug:
						for sphere in posSpheres:
							if sphere != null:
								sphere.queue_free()
						var newSphere = MeshInstance3D.new()
						newSphere.mesh = SphereMesh.new()
						posSpheres.append(newSphere)
						add_child(newSphere)
						newSphere.global_position = obj.collider.global_position
					#Console.add_rich_console_message("[color=green]%s found %s." %[pawnName,obj.collider.name])
					visibleObject.emit(obj.collider,obj.collider.global_position)
					visibleObjects.append(obj.collider)
					canSeeSomething.emit()
					#Console.add_rich_console_message("[color=green]%s can see %s"%[pawnName,obj.collider.name])
		PhysicsServer3D.free_rid(shape)
		onScan.emit()

func canSeeObject(object:Node3D)->bool:
	var pawnRID : Array[RID] = []
	pawnRID.append(pawnOwner.get_rid())
	var dist = pawnOwner.global_position.direction_to(object.global_position)
	var dotProd = dist.dot(-pawnOwner.pawnMesh.global_transform.basis.z)
	if dotProd > 0:
		var rayParams : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		rayParams.hit_from_inside = false
		rayParams.exclude = pawnRID
		rayParams.from = Vector3(pawnOwner.global_position.x,pawnOwner.global_position.y + 1, pawnOwner.global_position.z)
		rayParams.to = Vector3(object.global_position.x,object.global_position.y + 1, object.global_position.z)
		rayParams.collision_mask = collisionMasks
		var rayResults = get_world_3d().direct_space_state.intersect_ray(rayParams)
		#print(rayResults)
		if rayResults.is_empty():
			return true
		else:
			return false
	else:
		return false

func getDirFromAngle(angleInDeg:float) -> Vector3:
	return Vector3(sin(angleInDeg * deg_to_rad(angleInDeg)),0,cos(angleInDeg*deg_to_rad(angleInDeg)))

func ceaseAI() -> void:
	navAgent.queue_free()
	if isInDialogue:
		Dialogic.end_timeline()

func addRaycastException(object:Node3D) -> void:
	aimCast.add_exception(object)
	#$pawnGrabber/rayCast3d.add_exception(object)

func speakTrigger(dialogue) -> void:
	if pawnOwner:
		if !pawnOwner.isPawnDead:
			if dialogue != "":
				if Dialogic.current_timeline != null:
					return
				Dialogic.start(dialogue)
				isInDialogue = true
				if dialogueStartingCamera != null:
					var dialogue_cam : Node3D = gameManager.create_dialogue_camera()
					gameManager.world.add_child(dialogue_cam)
					dialogue_cam.activate(get_viewport().get_camera_3d(), dialogueStartingCamera.position,dialogueStartingCamera.rotation)
					Dialogic.timeline_ended.connect(dialogue_cam.remove)
				get_viewport().set_input_as_handled()

func setInteractablePawn(value:bool = false) -> void:
	if value == true:
		if pawnOwner:
			pawnOwner.add_to_group("Interactable")
			interactSpeakTrigger.connect(speakTrigger.bind(dialogueString))
	else:
		if pawnOwner:
			pawnOwner.remove_from_group("Interactable")
			interactSpeakTrigger.disconnect(speakTrigger)

func setWeaponCast()->void:
	if pawnOwner != null:
		if pawnOwner.currentItem != null:
			pawnOwner.currentItem.weaponCast = aimCast
			pawnOwner.currentItem.weaponCastEnd = aimCastEnd

func _on_nav_agent_velocity_computed(safe_velocity) -> void:
	if navAgent:
		if pawnOwner != null:
			pawnOwner.direction = safe_velocity

func enableDebugInfo()->void:
	visualMesh.show()
	pawnDebugLabel.visible = gameManager.pawnDebug
	if pawnDebugLabel.visible:
		pawnDebugLabel.position.y = 1
		pawnDebugLabel.text = "Pawn Name - %s
		Has Target - %s
		Pawn Skill - %s
		Has Reached Target - %s
		" %[pawnName,pawnHasTarget,aiSkill,navAgent.is_target_reached()]

func disableDebugInfo()->void:
	visualMesh.hide()
	pawnDebugLabel.visible = false

func _on_nav_agent_target_reached() -> void:
	pawnOwner.direction = Vector3.ZERO
	navAgent.set_velocity(Vector3.ZERO)

func enableAnimations() -> void:
	pawnOwner.animationTree.active = true

func disableAnimations() -> void:
	pawnOwner.animationTree.active = false

func setExceptions()->void:
	if pawnOwner != null:
		#if visionCast != null:
			#visionCast.add_exception(pawnOwner)
			#for hb in pawnOwner.getAllHitboxes():
				#visionCast.add_exception(hb.getCollisionObject())
		if aimCast !=null:
			aimCast.add_exception(pawnOwner)
			for hb in pawnOwner.getAllHitboxes():
				if hb.getCollisionObject() is CollisionObject3D:
					aimCast.add_exception(hb.getCollisionObject())

func _on_can_see_something():
	memoryManager.updateBrain(self)

func _on_memory_span_timeout():
	memoryManager.forgetMemories(memorySpanTimer.wait_time-1)

func getTargetPosition()->Vector3:
	return memoryManager.bestMemory.memoryPosition

func isTargetInSight()->bool:
	return memoryManager.bestMemory.memoryAge < 0.5

func getTargetDistance()->float:
	return memoryManager.bestMemory.distance

func hasTarget()->bool:
	return memoryManager.bestMemory != null

func getMemoryAge():
	return memoryManager.bestMemory.memoryAge

func getTarget()->Node3D:
	return memoryManager.bestMemory.memoryOwner

func walkToPosition(to:Vector3)->void:
	#print("%s is walking to %s"%[pawnName,to])
	await get_tree().process_frame
	if navAgent.is_target_reachable():
		#print("%s to %s is reachable"%[pawnName,to])
		newVelocity = (navAgent.get_next_path_position() - global_position).normalized()
		navAgent.velocity = newVelocity
	else:
		#print("%s to %s is not reachable"%[pawnName,to])
		pawnOwner.direction = Vector3.ZERO
		navAgent.set_velocity(Vector3.ZERO)
		targetUnreachable.emit()


func stopLookingAt()->void:
	pawnOwner.meshLookAt = false

func lookAtPosition(lookat:Vector3)->void:
	pawnOwner.meshLookAt = true
	aimCast.look_at(lookat)
	pawnOwner.meshRotation = aimCast.global_transform.basis.get_euler().y

func setPawnType()->void:
	await get_tree().process_frame
	match pawnType:
		0:
			pawnFSM.change_state("Idle")
		1:
			pawnFSM.change_state("Wander")
		2:
			pawnFSM.change_state("Patrol")
