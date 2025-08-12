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
@export_subgroup("Hidden Parts")
@export var head : bool = false
@export var shoulders : bool = false
@export var leftUpperarm : bool = false
@export var rightUpperarm  : bool= false
@export var rightForearm : bool = false
@export var leftForearm  : bool= false
@export var upperChest : bool = false
@export var lowerBody : bool = false
@export var leftUpperLeg : bool = false
@export var rightUpperLeg  : bool= false
@export var leftLowerLeg : bool = false
@export var rightLowerLeg : bool = false
@export_category("Skeleton")
@export var itemSkeleton : NodePath
@export_category("Cloth Physics")
@export var clothPhysicsSkeleton : Skeleton3D
@export var clothPhysics : SkeletonModifier3D

func _ready()->void:
	remapSkeleton()

func remapSkeleton()->void:
	clothingMesh.skeleton = itemSkeleton
