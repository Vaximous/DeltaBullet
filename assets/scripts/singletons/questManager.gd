extends Node
signal questActivated(contract)
signal questFailed(id)
signal databaseCreated
signal questCompleted(contract)
signal questProgressed(id,questProgress)
signal questProgression(id,questProgress)

## Database for all quests in the game. A JSON file containing quest information such as Quest Name, Quest Description, Quest ID and current status of the quest.
var questDatabase : Array = [load("res://assets/contracts/testContract2/cloakedUpContract.tscn").instantiate(),load("res://assets/contracts/testContract1/testContract.tscn").instantiate()]:
	set(value):
		questDatabase = value
		evaluateContracts()

func _enter_tree()->void:
	gameManager.getEventSignal("contractRefresh").connect(evaluateContracts)

func evaluateContracts()->void:
		for i in questDatabase:
			if i is Contract:
				match i.questStatus:
					0:
						add_child(i)
						i.enableQuest()
					1:
						i.startQuest(i.questProgress)

func getContractIDByName(contractName:String)->int:
	var foundContract : int = -1
	for contract in questDatabase:
		if contract.questName == contractName:
			foundContract = questDatabase.find(contract)
	return foundContract

func getContractByName(contractName:String)->Contract:
	var foundContract : Contract
	for contract in questDatabase:
		if contract.questName == contractName:
			foundContract = contract
	return foundContract

func checkIfContractCompleted(contract:Contract)->bool:
	if contract.questStatus == 2:
		return true
	else:
		return false
