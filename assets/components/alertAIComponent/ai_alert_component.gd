extends Area3D
class_name AlertComponent
@export_category("AI Alert Component")
@export var attached : Node3D
var perpetrator : Node3D
##INVESTIGATE - AI around the alert area will investigate the component it is attached to
##By walking to it.

##DETECT - AI around the alert area will immediately detect who the alert perpetrator is

enum ALERT_TYPE {
	INVESTIGATE,
	INVESTIGATE_CALL,
	DETECT
}
enum ACTIVATION_TYPE {
	AREA_ENTER,
	CALL
}
@export var alert_type : ALERT_TYPE
@export var line_of_sight_based : bool = false
@export var activation_type : ACTIVATION_TYPE
@export var refreshing : bool = true

func _ready() -> void:
	if !refreshing:
		%losRefresher.stop()
		%losRefresher.autostart = false

	if activation_type == ACTIVATION_TYPE.AREA_ENTER:
		area_entered.connect(alert.unbind(1))

func alert(_body:Node3D = null)->void:
	for i in get_overlapping_bodies():
		if i is BasePawn:
			if !i.isPlayerPawn() and !i == perpetrator:

				if line_of_sight_based:
					%losRefresher.start()
					var result = Util.is_line_of_sight_with_params(get_world_3d().direct_space_state,i.get_pawn_center(),attached.global_position,i.inputComponent.aimCast.collision_mask)
					print(result)
					if result:
						if result.collider == attached:
							i.inputComponent.alert_to.emit(alert_type,attached,attached.global_position,perpetrator)
							return

				i.inputComponent.alert_to.emit(alert_type,attached,attached.global_position,perpetrator)
