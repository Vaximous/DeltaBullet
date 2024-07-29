extends Panel
@onready var topLabel : Label = $topNotif
@onready var bottomLabel : Label = $bottomNotif
@onready var animPlayer : AnimationPlayer = $animationPlayer

func doNotification(notificationIcon:Texture2D=null,topText:String="",bottomText:String="")->void:
	if notificationIcon:
		pass
	bottomLabel.text = bottomText
	topLabel.text = topText
	animPlayer.play("entry")
	get_tree().create_timer(6.5).timeout.connect(queue_free)
	animPlayer.animation_finished.connect(queue_free)
