extends Panel
@onready var animPlayer : AnimationPlayer = $animationPlayer
@onready var notifAppearSound : AudioStreamPlayer = $notifAppear
@onready var notifStartSound : AudioStreamPlayer = $notifStart
@onready var contractNameLabel : Label = $contractName
@onready var contractStatusLabel : Label = $contractStatus
@export_enum("Complete","Failed","Added") var contractType : int = 0:
	set(value):
		contractType = value
		if contractStatusLabel != null:
			match contractType:
				0:
					contractStatusLabel.text = "Contract Completed"
				1:
					contractStatusLabel.text = "Contract Failed"
				2:
					contractStatusLabel.text = "New Contract Added"


func playQuestNotif(contract:Contract, type:int=0):
	if is_instance_valid(contract):
		if is_instance_valid(contractNameLabel):
			contractNameLabel.text = contract.questName
		contractType = type
		if is_instance_valid(animPlayer):
			animPlayer.play("entry")
			await animPlayer.animation_finished
		queue_free()
