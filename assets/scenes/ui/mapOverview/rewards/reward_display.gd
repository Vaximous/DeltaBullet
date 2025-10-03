class_name RewardDisplay
extends PanelContainer


@export_category("Reward Display")
@export var rewardName: String:
	set(value):
		rewardName = value
		%rewardName.text = value
@export var rewardIcon: Texture:
	set(value):
		rewardIcon = value
		%rewardIcon.texture = value
@export_multiline var rewardTooltipText: String:
	set(value):
		rewardTooltipText = value
		%tooltipDet.tooltip_text = value
