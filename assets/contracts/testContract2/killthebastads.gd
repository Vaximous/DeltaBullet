extends SubContract

var killcount: int = 0:
	set(value):
		killcount = value
		if killcount >= 2:
			contractOwner.progressQuest()


func onQuestEntered() -> void:
	super()
	killcount = 0
	for _spawns in get_tree().get_nodes_in_group(&"cloakedupcontract"):
		if _spawns != null:
			_spawns.active = true
			var pawn: BasePawn = _spawns.spawnPawn()
			_spawns.active = false
			pawn.onPawnKilled.connect(addtokillcount)
			pawn.onPawnKilled.connect(gameManager.pawnKillSlowMo)


func addtokillcount() -> void:
	var _notification = load("res://assets/scenes/ui/generalNotif/generalNotification.tscn").instantiate()
	if killcount < 1:
		for players in gameManager.playerPawns:
			if is_instance_valid(players):
				players.attachedCam.hud.gameNotifications.add_child(_notification)
				_notification.doNotification(null, "Cloaked Up", "Target Eliminated.")
	killcount += 1
