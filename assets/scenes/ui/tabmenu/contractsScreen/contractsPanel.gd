extends Control
@export_category("Contracts Panel")
var contractButton : PackedScene = load("res://assets/scenes/ui/tabmenu/contractsScreen/contract.tscn")
@onready var contractsHolder : VBoxContainer = $contractInfo/contractsAvailable
@onready var contractInfo : Label = $contractInfo/contractInfo/panel/contractInfo

func scanContracts()->void:
	for contracts in contractsHolder.get_children():
		contracts.queue_free()

	for quest in questManager.questDatabase:
		var _contractButton : Button = contractButton.instantiate()
		_contractButton.initializeContract(quest.id)
		contractsHolder.add_child(_contractButton)
		_contractButton.pressed.connect(updateContractInfo.bind(quest.id))

func updateContractInfo(id)->void:
	for quest in questManager.questDatabase.size():
		if questManager.questDatabase[quest].id == id:
			contractInfo.text = str(questManager.questDatabase[quest].questInfo)
