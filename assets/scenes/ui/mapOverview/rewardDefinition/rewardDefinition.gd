class_name RewardDefinition
extends Resource
@export_category("Reward Definition")
enum RewardType{
	STAT,
	AREA,
	CONTRACT
}
@export var rewardType : RewardType = 0
@export var rewardID : StringName
@export var rewardDisplay : PackedScene
