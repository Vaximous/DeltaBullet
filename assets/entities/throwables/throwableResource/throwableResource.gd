class_name ThrowableResource
extends Resource
@export_category("Throwable")
##What is this throwables name?
@export var itemName : String
##Can this throwable be cooked?
@export var canCook : bool = false
##How long does this throwable take to be cooked before it is activated?
@export var cookTime : float = 5.0
##How much damage does this throwable do?
@export var throwableDamage : float = 100.0
##This will enable the visual indicator for the countdown, if its an explosive on a timer then this'd be helpful
@export var countdownVisual : bool = false
