extends Control
@export_category("Shop UI")
@export var shopResource : ShopData
@onready var topBarAnim : AnimationPlayer = $topBar/topbarAnim
@onready var itemBrowserAnim : AnimationPlayer = $browserNode/itemBrowserAnim
@onready var shopNameLabel : Label = $topBar/topBarimage/shopName

func initializeShop()->void:
	topBarAnim.play("new_animation")
	itemBrowserAnim.play("new_animation")
	shopNameLabel.text = shopResource.shopName
