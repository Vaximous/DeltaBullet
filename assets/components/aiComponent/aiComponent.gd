@tool
extends Node3D
class_name AIComponent
signal interactSpeakTrigger
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
@onready var immediateMesh : MeshInstance3D = $pawnGrabber/meshInstance3d
@onready var visionCast : RayCast3D = $visionCast
@onready var detectionShape : CollisionShape3D = $pawnGrabber/collisionShape3d
@export_category("AI Component")
@export var pawnOwner : BasePawn:
	set(value):
		pawnOwner = value
		setExceptions()
		pawnOwner.itemChanged.connect(setWeaponCast)
		pawnOwner.onScreenNotifier.screen_entered.connect(enableAnimations)
		pawnOwner.onScreenNotifier.screen_exited.connect(disableAnimations)
@export_category("Interaction")
@export_enum("Dialogue") var interactType : int = 0
@export var isInteractable : bool = false
var isInDialogue : bool
@export_category("Dialogue")
@export var dialogueStartingCamera : Marker3D
@export var dialogueString : String
@export_subgroup("Identification")
@export var pawnName : String
@export_enum("High","Normal","Retarded") var aiSkill : int = 1:
	set(value):
		aiSkill = value
		if value == 0:
			aimSpeed = 1.0
		elif value == 1:
			aimSpeed = 0.075
		elif value == 2:
			aimSpeed = 0.015
@export_enum("Idle","Wander","Patrol") var aiType : int = 0
@export_enum("Friendly","Neutral","Hostile") var aiMindState : int = 1
@export_subgroup("Nodes")
@export var moveTo : Marker3D
@export var navAgent : NavigationAgent3D
@export var navPointGrabber : Area3D
@export var visionTimer : Timer
@onready var pawnGrabber : Area3D = $pawnGrabber
@export_subgroup("Mesh")
@export var meshAngle:float = 30:
	set(value):
		meshAngle = value
		if Engine.is_editor_hint():
			visualMesh.mesh = createLOSWedge()
@export var meshHeight:float = 1.0:
	set(value):
		meshHeight = value
		if Engine.is_editor_hint():
			visualMesh.mesh = createLOSWedge()
@export var meshDistance:float = 10.0:
	set(value):
		meshDistance = value
		if Engine.is_editor_hint():
			visualMesh.mesh = createLOSWedge()
@export_subgroup("Overlap")
@export var visibleObjects : Array = []
@export var pawnHasTarget : bool = false:
	set(value):
		#setExceptions()
		aimCast.position = visionCast.position
		pawnHasTarget = value
		pawnOwner.freeAim = value
		pawnOwner.meshLookAt = value
@export var overlappingObject : Node:
	set(value):
		#setExceptions()
		overlappingObject = value
		if value == null:
			pawnHasTarget = false
@export var overlappingObjectPosition : Vector3
@export_subgroup("Detection")
var withinAttackRange : bool = false
@export var hatedPawnGroups : Array[StringName]
@export var hatedPawns : Array[BasePawn]
@export var detectionRadius : float = 10.0
@export var detectionAngle : float = 90.0
@export var attackRange : float = 6.0
@export var aimSpeed : float = 0.075
var lastDirection : Vector3
var pawnPosition : Vector3
var debugDist : Vector3
@export var currLocation:Vector3
@export var newVelocity:Vector3
var reachedTarget : bool = false
var distanceToPawn : float = 0.0
var tgtVect : Vector3
var tgtBasis : Basis
var lookAt : float

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
			for hboxes in pawnOwner.hitboxes.size():
				pawnOwner.hitboxes[hboxes].damaged.connect(addToHatedPawns)
	else:
		visualMesh.visible = true
		visualMesh.mesh = createLOSWedge()

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
	bottomRight = Quaternion.from_euler(Vector3(0, meshAngle,0)) * Vector3.FORWARD * meshDistance
	bottomLeft = Quaternion.from_euler(Vector3(0, -meshAngle,0)) * Vector3.FORWARD * meshDistance

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
	var currAngle : float = -meshAngle
	var deltaAngle : float = (meshAngle * 2)/segs
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
	visibleObjects.clear()
	Console.add_rich_console_message("[color=green]%s Scanning.." %pawnName)
	var shape = PhysicsServer3D.sphere_shape_create()
	var shapeRadius = 5.0
	PhysicsServer3D.shape_set_data(shape,shapeRadius)
	var params : PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	params.shape_rid = shape
	params.transform.origin = global_position
	var world = get_world_3d().direct_space_state
	var result = world.intersect_shape(params)
	var count : int
	if !result.is_empty():
		#Console.add_rich_console_message("[color=green]%s" %result)
		count = result.size()
		for obj in result:
			#Console.add_rich_console_message("[color=green]%s" %obj)
			if canSeeObject(obj.collider):
				Console.add_rich_console_message("[color=green]%s found %s." %[pawnName,obj.collider.name])
				visibleObjects.append(obj.collider)
	PhysicsServer3D.free_rid(shape)

func canSeeObject(object:Node3D):
	var orig : Vector3 = transform.origin
	var deltaAngle : float
	var destination : Vector3 = object.transform.origin
	var dir: Vector3  = global_position.direction_to(object.global_position)
	if (dir.y < 0 || dir.y > meshHeight):
		return false
	dir.y = 0
	deltaAngle = dir.angle_to(Vector3.FORWARD)
	if (deltaAngle > meshAngle):
		return false

	#return true

func _physics_process(delta) -> void:
	pass


	##OLD SHIT
	#if pawnOwner != null:
		#lookAt = aimCast.global_transform.basis.get_euler().y
		#pawnOwner.meshRotation = lookAt
	#if navAgent != null:
		#if navAgent.is_target_reachable():
			#var nextLocation = navAgent.get_next_path_position()
			#currLocation = pawnOwner.global_position
			#newVelocity = (nextLocation - currLocation).normalized() * pawnOwner.velocityComponent.vMaxSpeed
			#navAgent.set_velocity(newVelocity)
			##reachedTarget = false
		#else:
			#pawnOwner.direction = Vector3.ZERO
			#navAgent.set_velocity(Vector3.ZERO)
#
		##Console.add_console_message("%s, overlapping: %s" %[pawnName,overlappingObject])
#
		## LOS Debug
		#if gameManager.pawnDebug:
			#pawnDebugLabel.visible = gameManager.pawnDebug
			#if pawnDebugLabel.visible:
				#pawnDebugLabel.position.y = 1
				#pawnDebugLabel.text = "Pawn Name - %s
				#Pawn Detection - %s
				#Has Target - %s
				#Pawn Skill - %s
				#Has Reached Target - %s
				#" %[pawnName,overlappingObject,pawnHasTarget,aiSkill,navAgent.is_target_reached()]
			#if overlappingObject != null:
				#debugDist = self.global_position.direction_to(overlappingObject.global_position)
				#immediateMesh.show()
				#$moveTo/debugMoveToMesh.visible = gameManager.pawnDebug
				#immediateMesh.mesh.clear_surfaces()
				#immediateMesh.mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
				#immediateMesh.mesh.surface_add_vertex(self.position)
				#immediateMesh.mesh.surface_add_vertex(debugDist)
				#immediateMesh.mesh.surface_end()
#
		#if pawnHasTarget:
			#pawnOwner.turnAmount = lerpf(pawnOwner.turnAmount,-aimCast.rotation.x,16*delta)
			#if overlappingObjectPosition != null:
				#tgtVect = global_position.direction_to(overlappingObjectPosition)
				#tgtBasis = Basis.looking_at(tgtVect)
#
				#if aimCast != null:
					#if !visionCast.is_colliding():
						#if pawnOwner.currentItem != null:
							#pawnOwner.preventWeaponFire = false
						#aimCast.look_at(overlappingObjectPosition)
						##aimCastEnd.position = Vector3(0,0,10)
					#else:
						##aimCast.basis = aimCast.basis.slerp(Basis.looking_at(to_local(visionCast.get_collision_point())),aimSpeed)
						#if pawnOwner.currentItem != null:
							#pawnOwner.preventWeaponFire = true
							##pawnOwner.currentItem.isAiming = false
#
		#if pawnOwner:
			#pawnPosition = pawnOwner.pawnMesh.position

func _on_vision_timer_timeout() -> void:
	pass

func lookForPawn() -> void:
	for pawn in pawnGrabber.get_overlapping_bodies():
		for groups in hatedPawnGroups.size():
			if pawn.is_in_group(hatedPawnGroups[groups]):
				if pawn is BasePawn:
					if !pawn.isPawnDead:
						var posVect = self.position
						var pawnVect = pawn.global_position
						var dist = self.global_position.direction_to(pawnVect)
						var dotProd = dist.dot(-pawnOwner.pawnMesh.global_transform.basis.z)
						if dotProd > 0:
							if pawnOwner != null:
								overlappingObject = pawn
								pawnHasTarget = true
								distanceToPawn = pawnOwner.position.distance_to(overlappingObject.position)
		for pawns in hatedPawns.size():
			if pawn == hatedPawns[pawns]:
				if !pawn.isPawnDead:
					var posVect = self.position
					var pawnVect = pawn.global_position
					var dist = self.global_position.direction_to(pawnVect)
					var dotProd = dist.dot(-pawnOwner.pawnMesh.global_transform.basis.z)
					if dotProd > 0:
						if pawnOwner != null:
							overlappingObject = pawn
							pawnHasTarget = true
							distanceToPawn = pawnOwner.position.distance_to(overlappingObject.position)

func ceaseAI() -> void:
	navAgent.queue_free()
	if isInDialogue:
		Dialogic.end_timeline()

func setupBlackboardObjects() -> void:
	pass

func undetectPawn() -> void:
	pawnHasTarget = false
	overlappingObject = null
	overlappingObjectPosition = Vector3.ZERO
	immediateMesh.hide()
	distanceToPawn = 0.0
	#pawnOwner.freeAim = false

func addRaycastException(object) -> void:
	aimCast.add_exception(object)
	#$pawnGrabber/rayCast3d.add_exception(object)

func addToHatedPawns(amount, impulse, vector, dealer) -> void:
	if !hatedPawns.has(dealer) and pawnOwner.currentItem != null:
		hatedPawns.append(dealer)

func _on_pawn_grabber_area_entered(area) -> void:
	lookForPawn()

func _on_pawn_grabber_body_entered(body) -> void:
	lookForPawn()

func _on_pawn_grabber_body_exited(body) -> void:
	if pawnHasTarget:
		if body == overlappingObject:
			undetectPawn()


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

func getAiType():
	return aiType

func setWeaponCast():
	if pawnOwner != null:
		if pawnOwner.currentItem != null:
			pawnOwner.currentItem.weaponCast = aimCast
			pawnOwner.currentItem.weaponCastEnd = aimCastEnd


func _on_nav_agent_velocity_computed(safe_velocity) -> void:
	if navAgent:
		if pawnOwner != null:
			pawnOwner.direction = safe_velocity
			reachedTarget = false

func enableDebugInfo()->void:
	visualMesh.show()
	pawnDebugLabel.visible = gameManager.pawnDebug
	if pawnDebugLabel.visible:
		pawnDebugLabel.position.y = 1
		pawnDebugLabel.text = "Pawn Name - %s
		Pawn Detection - %s
		Has Target - %s
		Pawn Skill - %s
		Has Reached Target - %s
		" %[pawnName,overlappingObject,pawnHasTarget,aiSkill,navAgent.is_target_reached()]

func disableDebugInfo()->void:
	visualMesh.hide()
	pawnDebugLabel.visible = false

func _on_nav_agent_target_reached() -> void:
	reachedTarget = true
	pawnOwner.direction = Vector3.ZERO
	navAgent.set_velocity(Vector3.ZERO)

func enableAnimations() -> void:
	pawnOwner.animationTree.active = true

func disableAnimations() -> void:
	pawnOwner.animationTree.active = false

func setExceptions()->void:
	if pawnOwner != null:
		if visionCast != null:
			visionCast.add_exception(pawnOwner)
			for hb in pawnOwner.getAllHitboxes():
				visionCast.add_exception(hb.getCollisionObject())
		if aimCast !=null:
			aimCast.add_exception(pawnOwner)
			for hb in pawnOwner.getAllHitboxes():
				aimCast.add_exception(hb.getCollisionObject())
