extends Control
@export_category("Contracts Panel")
var contractButton : PackedScene = load("res://assets/scenes/ui/tabmenu/contractsScreen/contract.tscn")
@onready var contractsHolder : VBoxContainer = $contractsAvailable
@onready var contractNameLabel : Label = $infoBG/contractName
@onready var contractDescriptionLabel : Label =$infoBG/contractDescription
@onready var contractTypeLabel : Label = $infoBG/contractType
@onready var contractInfoControl : Control = $infoBG
var selectedContract : Contract = null:
	set(value):
		contractInfoControl.modulate = Color.TRANSPARENT
		contractInfoControl.hide()
		selectedContract = value
		#Tween the contract info.
		if value == null:
			contractInfoControl.hide()
		else:
			updateContractInfo()


func scanContracts()->void:
	for contracts in contractsHolder.get_children():
		contracts.queue_free()

	for quest in questManager.questDatabase:
		var _contractButton : Button = contractButton.instantiate()
		var contract : Contract = quest
		_contractButton.initializeContract(contract)
		contractsHolder.add_child(_contractButton)
		_contractButton.contractHolder = self
		#contract.queue_free()
		#_contractButton.pressed.connect(updateContractInfo.bind(quest.id))

func updateContractInfo()->void:
	var tween = create_tween()
	if selectedContract:
		if !contractInfoControl.visible:
			contractInfoControl.modulate = Color.TRANSPARENT
			contractInfoControl.show()
			tween.tween_property(contractInfoControl,"modulate",Color.WHITE,0.03)
		#contractInfoControl.position.x += 10
		#tween.tween_property(contractInfoControl,"position",Vector2(800,11),0.03)
		contractNameLabel.text = selectedContract.questName
		contractDescriptionLabel.text = selectedContract.questDescription
		if selectedContract.questStatus != 2:
			#Hardcoded for now, will display mission type if the quest isn't completed.
			contractTypeLabel.text = "Main Contract"
		else:
			contractTypeLabel.text = "Completed"
