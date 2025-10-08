extends CanvasLayer

var checkmarkTexture := preload("res://assets/scripts/singletons/notifs/accept_button.png")
var warning_texture := preload("res://assets/scripts/singletons/notifs/warninghd.pmg.png")
var notif_fade : PackedScene = preload("res://assets/scripts/singletons/notifs/notif_fade.tscn")
var notifCheck : PackedScene = preload("res://assets/scripts/singletons/notifs/notifCheck.tscn")
var notif_warn : PackedScene = preload("res://assets/scripts/singletons/notifs/notif_warn.tscn")
var notif_click : PackedScene = preload("res://assets/scripts/singletons/notifs/notif_click.tscn")
@export var hudPositions : Array[Node] = [%topleft_notifs, %topcenter_notifs, %topright_notifs, %bottomleft_notifs, %bottomcenter_notifs, %bottomright_notifs]
