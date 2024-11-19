extends Node3D
##Base resource for other types.

##Enum of possible types of this Point-Of-Interest
enum POIType {COVER, FLANK, HOLD, RETREAT}
##COVER   : Good spot to hide and shoot from while engaging.
##FLANK   : Good spot to go to while approaching.
##HOLD    : A good place to hold regardless of health.
##RETREAT : A good place to go when low on health.
@export var type : POIType = POIType.COVER
##Score of the Point-Of-Interest, which determines if it's chosen or not.
@export_range(1, 5) var score : int = 5
##Active toggle.
@export var active : bool = false
##Outside of this range, the AI won't consider it as a viable position.
@export var consideration_range : float = 15.0
