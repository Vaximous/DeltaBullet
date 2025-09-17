extends SubContract

func onQuestEntered()->void:
	super()
	await get_tree().create_timer(1,false).timeout
	if gameManager.getCurrentPawn():
		gameManager.getCurrentPawn().callFinished.connect(finishQuest)
		gameManager.queuePhoneCall(load("res://assets/resources/customResources/actorAudio/dialogue/cloakedUpSuccess.tres"))

func finishQuest()->void:
	contractOwner.progressQuest()
	gameManager.getCurrentPawn().callFinished.disconnect(finishQuest)
