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
@export var hatedGroups : Array[StringName] = ["Player","Hostile"]
@export var spawnGroup : StringName = "Hostile"
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
@export var pawnColor : Color = Color(1.0,0.76,0.00,1.0):
	set(value):
		pawnColor = value
		if pawnType == 1:
			if previewMesh != null:
				previewMesh.material_override.albedo_color = pawnColor
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

func spawnPawn():
	if active:
		var pawn = gameManager.world.pawnScene.instantiate()
		#Player Pawn
		var pawnSpawns = gameManager.world.pawnWorldSpawns.get_children()
		var pawnPlayerSpawns = gameManager.world.playerWorldSpawns.get_children()
		if pawnType == 0:
			if active:
				var playerControllerComponent = load("res://assets/components/inputComponent/inputComponent.tscn")
				var controller = playerControllerComponent.instantiate()
				gameManager.world.playerPawns.add_child(pawn)
				pawn.global_position.x = global_position.x
				pawn.global_position.y = global_position.y + 1
				pawn.global_position.z = global_position.z
				pawn.rotation.y = global_rotation.y
				pawn.componentHolder.add_child(controller)
				pawn.inputComponent = controller
				pawn.checkComponents()
				pawn.fixRot()
				pawn.add_to_group(&"Player")

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
		elif pawnType == 1:
			#Pawn
			var aiControllerComponent = load("res://assets/components/aiComponent/aiComponent.tscn")
			var controller : AIComponent = aiControllerComponent.instantiate()
			gameManager.world.worldPawns.add_child(pawn)
			pawn.global_position.x = global_position.x
			pawn.global_position.y = global_position.y + 1
			pawn.global_position.z = global_position.z
			pawn.rotation.y = global_rotation.y
			pawn.componentHolder.add_child(controller)
			pawn.inputComponent = controller
			pawn.checkComponents()
			pawn.fixRot()
			controller.aiType = aiType
			controller.aiSkill = aiSkill
			controller.hatedPawnGroups = hatedGroups
			pawn.add_to_group(spawnGroup)

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
			if dialogueStartingCam != null:
				controller.dialogueStartingCamera = dialogueStartingCam
			if dialogueName != "" or " ":
				controller.dialogueString = dialogueName
			if forceAnimation:
				pawn.forceAnimation = forceAnimation
				pawn.animationToForce = animationToForce
			if isInteractable:
				controller.setInteractablePawn(true)
			if equipWeaponOnSpawn:
				pawn.currentItemIndex = weaponToEquip
			if pawnColor != Color(1.0,0.74,0.44,1.0):
				pawn.pawnColor = pawnColor
		pawnSpawned.emit(pawn)
		return pawn

	return

func setClothesPreview()->void:
	if Engine.is_editor_hint():
		if clothingPreviewHolder != null:
			for cloth in clothingPreviewHolder.get_children():
				cloth.queue_free()
			for clothingItemIndex in pawnClothing.size():
				var clothing = pawnClothing[clothingItemIndex].instantiate()
				clothingPreviewHolder.add_child(clothing)