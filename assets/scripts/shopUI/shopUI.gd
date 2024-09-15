extends Control
@export_category("Shop UI")
@export var selectedItem : Button = null:
	set(value):
		selectedItem = value
		if value != null:
			previewBGAnim.play("in")
		else:
			previewBGAnim.play("out")
@export var shopResource : ShopData
@onready var tabBar : TabBar = $BrowserBG/tabBar
@onready var itemHolder : BoxContainer = $BrowserBG/scrollContainer/itemHolder
@onready var topBarAnim : AnimationPlayer = $topBar/topbarAnim
@onready var previewBGAnim : AnimationPlayer = $previewBG/animationPlayer
@onready var shopNameLabel : Label = $topBar/topBarimage/shopName

func initializeShop()->void:
	disableAllTabs()
	topBarAnim.play("new_animation")
	previewBGAnim.play("out")
	clearShopList()
	if shopResource != null:
		shopNameLabel.text = shopResource.shopName
		for tabs in tabBar.get_tab_count():
			for items in shopResource.itemsToSell.size():
				if shopResource.itemsToSell[items].weaponResource.saleCategory.keys()[items] == tabBar.get_tab_title(tabs):
					tabBar.set_tab_disabled(tabs,0)

func clearShopList(tab:int=0)->void:
	for index in itemHolder.get_children():
		index.queue_free()

func disableAllTabs()->void:
	for tabs in tabBar.get_tab_count():
		tabBar.set_tab_disabled(tabs,1)
