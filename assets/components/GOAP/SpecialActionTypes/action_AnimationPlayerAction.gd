extends GOAP_Action
class_name GOAP_AnimationAction


##An example custom Action type used with AnimationPlayer


##Target node AnimationPlayer
@export var animation_player : AnimationPlayer
##What animation to play
@export var animation_to_play : StringName
@export var playback_speed : float = 1.0


##To be extended per-action.
func _execute_action() -> void:
	action_busy = true
	set_physics_process(true)
	set_physics_process(true)
	last_execute_time = Time.get_ticks_msec()
	animation_player.play(animation_to_play, -1.0, playback_speed)
	while action_busy:
		var f = await animation_player.animation_finished
		if f == animation_to_play:
			finish_action()


func _get_action_completion() -> float:
	if animation_player.current_animation == animation_to_play:
		return animation_player.current_animation_position / animation_player.current_animation_length
	return 0.0
