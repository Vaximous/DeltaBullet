extends RigidBody3D
class_name InteractiveObject
signal objectUsed(user)
@onready var useSound : AudioStreamPlayer = $useSound
@onready var useSound3D : AudioStreamPlayer3D = $useSound3D
@export_category("Interactive Object")
@export var objectName : String
@export var customInteractText : String = ""
@export var useCustomInteractText : bool = false
var beenUsed:bool = false
@export_subgroup("Object")
@export_enum("Equippable","Interactive") var interactType : int = 0
@export var canBeUsed : bool = false
