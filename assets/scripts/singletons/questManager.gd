extends Node
signal questActivated(id)
signal questFailed(id)
signal databaseCreated
signal questCompleted(id)
signal questProgressed(id,questProgress)

## Database for all quests in the game. A JSON file containing quest information such as Quest Name, Quest Description, Quest ID and current status of the quest.
var questDatabase : Array
## Active quests, quests that are currently being done.
var currentQuests : Dictionary = {}
var currentActiveQuest : int = -1:
	set(value):
		currentActiveQuest = value

func buildQuestDB(databasePath : String) -> void:
	## Builds the database for the game to grab quests from. Takes a JSON path and parses it to then be used for the database. Then quests can be activated from it
	var questDBPath = FileAccess.get_file_as_string(databasePath)
	var parsedDB = JSON.parse_string(questDBPath)
	if parsedDB:
		questDatabase = parsedDB
		databaseCreated.emit()
		print_rich("[color=green]Quest Database loaded.[/color]")
		Console.add_rich_console_message("[color=green]Quest Database loaded.[/color]")
	else:
		print_rich("[color=red]Unable to create quest database.[/color]")
		Console.add_rich_console_message("[color=red]Unable to create quest database.[/color]")
		return

func activateQuest(id) -> void:
	## Activates the quest for playing. When the quest is activated the player will be notified and from there the quest can be progressed
	var questDict = null
	currentQuests.clear()
	for quest in questDatabase:
		if quest.id == id:
			questDict = quest
			print_rich("[color=green]Quest '%s' is currently active.[/color]" %quest.questName)
			Console.add_rich_console_message("[color=green]Quest '%s' is currently active.[/color]" %quest.questName)
			break
	if questDict == null:
		print_rich("[color=red]There is no quest with that ID. Unable to find it within the quest database.[/color]")
		Console.add_rich_console_message("[color=red]There is no quest with that ID. Unable to find it within the quest database.[/color]")
		return
	currentQuests[id] = questDict
	currentActiveQuest = questDict.id
	questActivated.emit(id)

func progressQuest(id) -> void:
	## If the quest is progressed the quest progress integer will increase and a signal will be emitted.
	if currentQuests.has(id):
		currentQuests[id].questProgress += 1
		questProgressed.emit(id,currentQuests[id].questProgress)
		print_rich("[color=green]Quest '%s' progressed.[/color]" %currentQuests[id].questName)
		Console.add_rich_console_message("[color=green]Quest '%s' progressed.[/color]" %currentQuests[id].questName)

func completeQuest(id) -> void:
	## Mark the quest as complete
	if currentQuests.has(id):
		currentQuests[id].completed = true
		questCompleted.emit(id)
		print_rich("[color=green]Quest '%s' completed.[/color]" %currentQuests[id].questName)
		Console.add_rich_console_message("[color=green]Quest '%s' completed.[/color]" %currentQuests[id].questName)

func failQuest(id) -> void:
	## Mark the quest as failed
	if currentQuests.has(id):
		currentQuests[id].failed = true
		questFailed.emit(id)
		print_rich("[color=green]Quest '%s' failed.[/color]" %currentQuests[id].questName)
		Console.add_rich_console_message("[color=green]Quest '%s' failed.[/color]" %currentQuests[id].questName)
