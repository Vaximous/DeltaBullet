extends Resource
@export_category("Clothing Item")
@export_subgroup("Item")
@export var itemOffset : Vector3 = Vector3.ZERO:
	set(value):
		itemOffset = value
@export var itemName : String = ""
@export_subgroup("Hidden Parts")
@export var head : bool = false
@export var shoulders : bool = false
@export var leftUpperarm : bool = false
@export var rightUpperarm : bool = false
@export var rightForearm : bool = false
@export var leftForearm : bool = false
@export var upperChest : bool = false
@export var lowerBody  : bool= false
@export var leftUpperLeg : bool = false
@export var rightUpperLeg : bool = false
@export var leftLowerLeg : bool = false
@export var rightLowerLeg : bool = false
