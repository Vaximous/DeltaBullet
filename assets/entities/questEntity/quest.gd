extends Node
class_name Contract
@export_category("Contract")
@export_subgroup("Contract Identification")
@export var questName : String = "":
	set(value):
		questName = value
		name = questName
@export var questDescription : String = ""
@export var questObjective : String = ""
@export_enum("MainQuest","SideQuest","Optional") var questType : int = 0
@export_subgroup("Contract Behavior")
@export var questProgress : int = 0:
	set(value):
		questProgress = value
		if value > get_children().size()-1:
			if questStatus != 2:
				questStatus = 2
				finishQuest()
		if value == -1:
			if questCanBeFailed:
				if subcontract != null:
					subcontract.failQuest()
			else:
				questProgress = 0
@export_enum("Inactive","Active","Complete","Failed") var questStatus : int = 0:
	set(value):
		questStatus = value
@export var questCanBeFailed : bool = false
@export var questScene : PackedScene
var subcontract : SubContract:
	set(value):
		subcontract = value
		subcontract.contractOwner = self

func _ready()->void:
	if is_node_ready() and is_instance_valid(get_child(questProgress)):
		var subquest : SubContract = get_child(questProgress)
		subcontract = subquest
		#enableQuest()
	elif !is_instance_valid(get_child(questProgress)):
		print_rich("[color=red]Contract '%s' doesn't have a sub-contract![/color]")

func _enter_tree() -> void:
	if is_node_ready() and is_instance_valid(get_child(questProgress)):
		var subquest : SubContract = get_child(questProgress)
		subcontract = subquest
		#enableQuest()
	elif !is_instance_valid(get_child(questProgress)):
		print_rich("[color=red]Contract '%s' doesn't have a sub-contract![/color]")

func disableQuest()->bool:
	if questStatus != 0:
		questStatus = 0
	if questManager.currentQuests.has(self):
		var questInt = questManager.currentQuests.find(self)
		questManager.currentQuests.erase(questInt)
	if subcontract != null:
		subcontract.onQuestExited()
	return true

func enableQuest()->bool:
	if !questStatus == 1 || 2 || 3:
		questStatus = 1
		questManager.add_child(self)
		if subcontract != null:
			subcontract.onQuestEntered()
	return true

func startQuest(at:int=0)->void:
	if !questStatus == 2 or !questStatus == 3:
		questProgress = at
		if is_instance_valid(get_child(questProgress)):
			subcontract = get_child(questProgress)
			if subcontract != null:
				subcontract.onQuestEntered()

func progressQuest()->void:
	questProgress += 1
	if is_instance_valid(get_child(questProgress)):
		subcontract = get_child(questProgress)
		subcontract.onQuestEntered()

func finishQuest()->void:
	var questNotif = load("res://assets/scenes/ui/questUI/questNotification.tscn").instantiate()
	questManager.questCompleted.emit(self)
	##Temporary Quest Finish Confirmation
	gameManager.activeCamera.hud.questNotifHolder.add_child(questNotif)
	questNotif.playQuestNotif(self,0)
	#gameManager.notifyCheck("Contract '%s' has been completed." %questName,2,4)
