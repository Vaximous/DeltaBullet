extends PanelContainer
@export_category("Stats App")
@onready var statLabel : RichTextLabel = $vBoxContainer/richTextLabel
var statPawn : BasePawn


func initStats()->void:
	if is_instance_valid(statPawn):
		statLabel.text = '
		[b]Kills - %s
		   Reload Level - %s
		   Blast Resist Level - %s
		   Bullet Resist Level - %s
		'
		[]
