extends Node3D
class_name GizmoChild

enum TransformOperateType{Translate = 0, Rotate = 1, Scale = 2}

@export var axis: Vector3
@export var isGlobal: bool = false
@export var TransformType: TransformOperateType
@export var basecolor: Color
@export var selcClor: Color

var isTransformtype: String
var oldPosition: Vector3
var isPressed: bool
var oldPressed: bool
var oldMousepos: Vector2

var clickpos: Vector3


#---fire trigger input event
signal input_event_axis(event:InputEvent, position, oldPosition, clickpos:Vector3, axis: Vector3, operateType, isGlobal:bool)
signal pressing_this_axis(axis: Vector3, is_pressed: bool)
signal release_this_axis(axis: Vector3)
