extends CanvasLayer
@export_category("Shop UI")
@onready var tabBar : TabBar = $shopUi/BrowserBG/tabBar
@onready var itemHolder : BoxContainer = $shopUi/BrowserBG/scrollContainer/itemHolder
@onready var topBarAnim : AnimationPlayer = $shopUi/topBar/topbarAnim
@onready var previewBGAnim : AnimationPlayer = $shopUi/previewBG/animationPlayer
@onready var shopNameLabel : Label = $shopUi/topBar/topBarimage/shopName
var activeTab :int = 0
@export var selectedItem : Button = null:
	set(value):
		selectedItem = value
		if value != null:
			previewBGAnim.play("in")
		else:
			previewBGAnim.play("out")
@export var shopResource : ShopData:
	set(value):
		shopResource = value

func initializeShop()->void:
	disableAllTabs()
	topBarAnim.play("new_animation")
	previewBGAnim.play("out")
	clearShopList()
	if shopResource != null:
		shopNameLabel.text = shopResource.shopName
		enableTabs(shopResource.saleCategories)
		buildItemList()

func clearShopList(tab:int=0)->void:
	for index in itemHolder.get_children():
		index.queue_free()

func disableAllTabs()->void:
	if tabBar != null:
		for tabs in tabBar.get_tab_count():
			tabBar.set_tab_disabled(tabs,1)

func enableTabs(shop_flags:int) -> void:
	for tabs in tabBar.get_tab_count():
		tabBar.set_tab_disabled(tabs, (1<<(tabs) & shop_flags) ==0)
	return

func buildItemList()->void:
	var shopItem = load("res://assets/scenes/ui/shopui/shopItem.tscn")
	if shopResource != null:
		for items in shopResource.itemsToSell:
			if items.instantiate() is Weapon:
				if tabBar.current_tab == items.instantiate().weaponResource.saleCategory:
					var _shopItem = shopItem.instantiate()
					_shopItem.item = items
					itemHolder.add_child(_shopItem)
					_shopItem.setItemInfo()
