extends SubContract
var killcount : int = 0:
	set(value):
		killcount = value
		if killcount >=2:
			contractOwner.progressQuest()
func onQuestEntered()->void:
	super()
	killcount = 0
	for _spawns in get_tree().get_nodes_in_group(&"cloakedupcontract"):
		if _spawns != null:
				_spawns.active = true
				var pawn : BasePawn = _spawns.spawnPawn()
				_spawns.active = false
				pawn.onPawnKilled.connect(addtokillcount)

func addtokillcount()->void:
	killcount += 1
