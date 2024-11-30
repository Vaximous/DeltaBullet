extends Resource
class_name WorldData
signal worldTypeChanged
@export_category("World Identity")
## What texture will the sky be in this world?
@export var skyTexture : PanoramaSkyMaterial
## Is time of day enabled in this world?
@export var enableTimeCycle :bool= false
##What is this worlds name?
@export var worldName:String = ""
##Describe the world..
@export var worldDescription:String = ""
## What will be used for the loading screen..
@export var worldLoadingTexture : Texture2D = load(["res://assets/misc/db7.png","res://assets/scenes/ui/saveloadmenu/save1.png","res://assets/scenes/ui/saveloadmenu/save2.png","res://assets/scenes/ui/saveloadmenu/save3.png","res://assets/scenes/ui/saveloadmenu/save4.png"].pick_random())
## What type of world is this scene? If its a general area the player can explore to find things like items or quests, it'd be an area. If its a zone where the player can save the game or restock on items it'd be a safehouse. If its a sector full of enemies, arena.
@export_enum("Area", "Shop", "Safehouse", "Arena") var worldType:int = 0:
	set(value):
		worldType = value
		worldTypeChanged.emit()
##Spawn AI pawns at their respective positions when loading the world.
@export var spawnPawnsOnLoad : bool = true
@export_category("Soundscape")
@export var playOnStart:bool = false
@export var soundScape : AudioStream

@export_category("Debug Parameters")
##Spawn Type to use when loading the scene
@export_enum("Player","Camera","None") var spawnType :int= 0
