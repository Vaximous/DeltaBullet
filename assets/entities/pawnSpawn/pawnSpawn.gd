@tool
extends Marker3D
class_name PawnSpawn
signal pawnSpawned(pawn:BasePawn)
var lastSpawnedPawn : BasePawn = null
@onready var previewMesh = $previewMesh
@onready var clothingPreviewHolder = $previewMesh/clothingpreview
var previewMeshMat = load("res://assets/materials/pawnMaterial/MALE.tres").duplicate()
@export_category("Pawn Spawn")
@export var active : bool = true
@export var pawnName : String
	#set(value):
		#pawnName = value
		#if value != "" or " ":
			#name = pawnName
@export_enum("Player","Pawn") var pawnType : int = 1:
	set(value):
		pawnType = value
		pawnTypeColor(value)

@export var pawnWeapons : Array[PackedScene]
@export var pawnClothing : Array[PackedScene]:
	set(value):
		pawnClothing = value
		setClothesPreview()
@export_subgroup("AI Only")
@export_enum("High","Normal","Retarded") var aiSkill = 1
@export var equipWeaponOnSpawn : bool = false
@export var weaponToEquip : int = 0
@export var isInteractable : bool = false
@export_enum("Idle","Wander","Patrol") var aiType = 1
@export var hatedGroups : Array[StringName] = [&"Player"]
@export var spawnGroup : Array[StringName] = [&"Hostile"]
@export var pawnHP : int = 100
var forceAnimation: bool = false
@export var dialogueStartingCam : Marker3D
@export var dialogueName : StringName = ""
@export var animationToForce : StringName:
	set(value):
		animationToForce = value
		if value != "" or " ":
			forceAnimation = true
		else:
			forceAnimation = false
##Only works if animation to force is on, makes the animation that plays play at a random speed scale
@export var randomAnimationSpeed : bool = false
@export var pawnColor : Color = Color(1.0,0.76,0.00,1.0):
	set(value):
		pawnColor = value
		if pawnType == 1:
			if previewMesh != null:
				previewMesh.material_override.albedo_color = pawnColor
var ignore_spawn_on_load : bool = false


func _ready()->void:
	if Engine.is_editor_hint():
		if previewMesh != null:
			previewMesh.show()
			pawnTypeColor(pawnType)
			setClothesPreview()
	else:
		if previewMesh != null:
			previewMesh.queue_free()

func pawnTypeColor(value)->void:
	if Engine.is_editor_hint():
		previewMesh.material_override = previewMeshMat
		if value == 1:
			previewMesh.material_override.albedo_color = pawnColor
		if value == 0:
			previewMesh.material_override.albedo_color = Color.GREEN

func spawnPawn(forceParent : Node = null, _params : PawnSpawnParameters = null) -> BasePawn:
	if _params != null:
		equipWeaponOnSpawn = true
		pawnType = _params.pawn_type
		pawnName = _params.pawn_name
		pawnWeapons = _params.weapons
		pawnClothing = _params.clothes
		aiType = _params.ai_type
		aiSkill = _params.ai_skill
		weaponToEquip = _params.weaponEquip

	if active:
		var pawn : BasePawn = gameManager.pawnScene.instantiate()
		#Player Pawn
		if forceParent == null:
			var _pawnSpawns = gameManager.world.pawnWorldSpawns.get_children()
			var _pawnPlayerSpawns = gameManager.world.playerWorldSpawns.get_children()
		match pawnType:
			0:
				if active:
					var playerControllerComponent = load("res://assets/components/inputComponent/inputComponent.tscn")
					var controller = playerControllerComponent.instantiate()
					if forceParent == null:
						gameManager.world.playerPawns.add_child(pawn)
					else:
						forceParent.add_child(pawn)
					pawn.global_position.x = global_position.x
					pawn.global_position.y = global_position.y + 0.1
					pawn.global_position.z = global_position.z
					pawn.rotation.y = global_rotation.y
					pawn.healthComponent.defaultHP = 550
					pawn.componentHolder.add_child(controller)
					pawn.inputComponent = controller
					pawn.checkComponents()
					pawn.fixRot()
					pawn.add_to_group(&"Player")
					pawn.set_meta(&"teams", [&"Player",&"Friendly"])
					pawn.set_meta(&"isPlayer", true)
					gameManager.allPawns.append(pawn)
					if gameManager.temporaryPawnInfo.size() <= 0:
						if gameManager.currentSave != "" or gameManager.currentSave != " " or gameManager.currentSave != null:
							var pawnFile = FileAccess.open(gameManager.currentSave,FileAccess.READ)
							if pawnFile != null:
								while pawnFile.get_position() < pawnFile.get_length():
									var string = pawnFile.get_line()
									var json = JSON.new()
									var result = json.parse(string)
									if not result == OK:
										Console.add_rich_console_message("[color=red]Couldn't Parse %s![/color]"%string)
										return
									var nodeData = json.get_data()
									pawn.loadPawnFile(nodeData["pawnToLoad"])
					elif gameManager.temporaryPawnInfo.size() > 0:
						pawn.loadPawnInfo(gameManager.temporaryPawnInfo[0])
					#for clothing in pawnClothing.size():
						#if pawnClothing[clothing] != null:
							#var clothingSpawn = pawnClothing[clothing]
							#var clothingNode = clothingSpawn.instantiate()
							#pawn.clothingHolder.add_child(clothingNode)
							#pawn.checkClothes()
					#for item in pawnWeapons.size():
						#if pawnWeapons[item] != null:
							#var itemSpawn = pawnWeapons[item]
							#var itemNode = itemSpawn.instantiate()
							#pawn.itemHolder.add_child(itemNode)
							#pawn.checkItems()
			1:
				#Pawn
				var aiControllerComponent = load("res://assets/components/aiComponent/aiComponent.tscn")
				var controller : AIComponent = aiControllerComponent.instantiate()
				if forceParent == null:
					gameManager.world.worldPawns.add_child(pawn)
				else:
					forceParent.add_child(pawn)
				pawn.global_position.x = global_position.x
				pawn.global_position.y = global_position.y + 0.1
				pawn.global_position.z = global_position.z
				pawn.rotation.y = global_rotation.y
				pawn.componentHolder.add_child(controller)
				pawn.inputComponent = controller
				pawn.checkComponents()
				pawn.fixRot()
				controller.pawnType = aiType
				#controller.aiSkill = aiSkill
				gameManager.allPawns.append(pawn)
				#controller.hatedPawnGroups = hatedGroups
				#pawn.add_to_group(spawnGroup)
				controller.pawnTeam = spawnGroup
				controller.hatedPawnTeams = hatedGroups
				pawn.set_meta(&"isPlayer", false)
				pawn.set_meta(&"canBeStaggered", true)

				if pawnName != "":
					controller.pawnName = pawnName
					pawn.name = pawnName

				for clothing in pawnClothing.size():
					if pawnClothing[clothing] != null:
						var clothingSpawn = pawnClothing[clothing]
						var clothingNode = clothingSpawn.instantiate()
						pawn.clothingHolder.add_child(clothingNode)
						pawn.checkClothes()

				for item in pawnWeapons.size():
					if pawnWeapons[item] != null:
						var itemSpawn = pawnWeapons[item]
						var itemNode = itemSpawn.instantiate()
						pawn.itemHolder.add_child(itemNode)
						pawn.checkItems()

				#AI Flags
				if forceAnimation:
					equipWeaponOnSpawn = false
					pawn.forceAnimation = forceAnimation
					pawn.animationToForce = animationToForce
					if randomAnimationSpeed:
						pawn.animationPlayer.speed_scale = randf_range(0.15,1)
				#if isInteractable:
					#controller.setInteractablePawn(true)

				if pawnColor != Color(1.0,0.74,0.44,1.0):
					pawn.pawnColor = pawnColor
				pawn.healthComponent.defaultHP = pawnHP
				pawn.healthComponent.setHealth(pawn.healthComponent.defaultHP)
				if equipWeaponOnSpawn:
					pawn.currentItemIndex = weaponToEquip
		pawnSpawned.emit(pawn)
		return pawn
	return null

func setClothesPreview()->void:
	if Engine.is_editor_hint():
		if clothingPreviewHolder != null:
			for cloth in clothingPreviewHolder.get_children():
				cloth.queue_free()
			for clothingItemIndex in pawnClothing.size():
				var clothing = pawnClothing[clothingItemIndex].instantiate()
				clothingPreviewHolder.add_child(clothing)
