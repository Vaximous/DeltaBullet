extends Node3D
class_name ClothingItem

@onready var clothingMesh : MeshInstance3D = $clothingMesh:
	set(value):
		clothingMesh = value
		for i in gameManager.getMeshSurfaceOverrides(clothingMesh):
			if !is_instance_valid(i):
				gameManager.createOverrideFromSurfaceMaterial(clothingMesh,clothingMesh.mesh,i)

@export_category("Clothing Item")
@export_subgroup("Item")
@export_enum("Hair","Headgear","Bling","Body","Pants")var clothingCategory : int = 2
@export_enum("Headwear","Facewear","Hair","Body","Hands","Legs") var clothingType : int = 0
@export var itemOffset : Vector3 = Vector3.ZERO:
	set(value):
		itemOffset = value
		if is_instance_valid(clothingMesh):
			clothingMesh.position = value
@export var itemName : String = ""
@export var equippedPawn : BasePawn
@export_subgroup("Blendshapes")
@export_range(0,1) var leftShoulder : float = 0.0
@export_range(0,1) var lowerPelvis : float = 0.0
@export_range(0,1) var lowerStomach : float = 0.0
@export_range(0,1) var middleStomach : float = 0.0
@export_range(0,1) var upperChest : float = 0.0
@export_range(0,1) var rightShoulder : float = 0.0
@export_range(0,1) var leftUpperarm : float = 0.0
@export_range(0,1) var rightUpperarm  : float= 0.0
@export_range(0,1) var rightForearm : float = 0.0
@export_range(0,1) var leftForearm  : float= 0.0
@export_range(0,1) var leftUpperLeg : float = 0.0
@export_range(0,1) var rightUpperLeg  : float= 0.0
@export_range(0,1) var leftKnee : float = 0.0
@export_range(0,1) var rightKnee : float = 0.0
@export_category("Skeleton")
@export var itemSkeleton : NodePath
@export_category("Cloth Physics")
@export var clothPhysicsSkeleton : Skeleton3D
@export var clothPhysics : SkeletonModifier3D

func _ready()->void:
	remapSkeleton()

func remapSkeleton()->void:
	clothingMesh.skeleton = itemSkeleton
