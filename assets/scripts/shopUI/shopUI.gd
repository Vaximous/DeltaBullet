extends CanvasLayer
@export_category("Shop UI")
@onready var damageBar : TextureProgressBar = $shopUi/previewHolder/previewBG/marginContainer/vBoxContainer/ItemStatsContainer/damageContainer/textureProgressBar
@onready var penetrationBar : TextureProgressBar = $shopUi/previewHolder/previewBG/marginContainer/vBoxContainer/ItemStatsContainer/penetrationContainer/textureProgressBar
@onready var fireRateBar : TextureProgressBar = $shopUi/previewHolder/previewBG/marginContainer/vBoxContainer/ItemStatsContainer/FireRateContainer/textureProgressBar
@onready var previewMeshHolder : Node3D = $shopUi/previewHolder/previewBG/panel/subViewportContainer/subViewport/previewMesh
@onready var tabBar : TabBar = $shopUi/BrowserBG/tabBar
@onready var itemHolder : BoxContainer = $shopUi/BrowserBG/scrollContainer/itemHolder
@onready var topBarAnim : AnimationPlayer = $shopUi/topBar/topbarAnim
@onready var previewBG : Panel = $shopUi/previewHolder/previewBG
@onready var previewBGAnim : AnimationPlayer = $shopUi/previewHolder/previewBG/animationPlayer
@onready var shopNameLabel : Label = $shopUi/topBar/topBarimage/shopName
@onready var itemDescription : RichTextLabel = %itemDescriptor
@onready var purchaseButton : Button = $shopUi/previewHolder/previewBG/purchaseButton
@onready var itemName : Label = $shopUi/previewHolder/previewBG/itemName
var activeTab :int = 0
@export var selectedItem : Button = null:
	set(value):
		if value != null:
			if selectedItem != value:
				previewBGAnim.play("in")
				setPreviewMesh(value.item)
				if value.isPurchased:
					purchaseButton.disabled = true
				if !value.isPurchased:
					purchaseButton.disabled = false
		else:
			previewBGAnim.play("out")
		selectedItem = value
@export var shopResource : ShopData:
	set(value):
		shopResource = value

func initializeShop()->void:
	previewBG.hide()
	disableAllTabs()
	topBarAnim.play("new_animation")
	previewBGAnim.play("out")
	clearShopList()
	if shopResource != null:
		shopNameLabel.text = shopResource.shopName
		enableTabs(shopResource.saleCategories)
		buildItemList()

func clearShopList()->void:
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
	await get_tree().process_frame
	#print(tabBar.current_tab)
	var shopItem = load("res://assets/scenes/ui/shopui/shopItem.tscn")
	if shopResource != null:
		for items in shopResource.itemsToSell:
			var itemInstance = items.instantiate()
			if itemInstance is Weapon:
				if tabBar.current_tab == itemInstance.weaponResource.displayData.saleCategory:
					var _shopItem : Button = shopItem.instantiate()
					_shopItem.item = items
					itemHolder.add_child(_shopItem)
					_shopItem.setItemInfo()
					_shopItem.pressed.connect(setShopItem.bind(_shopItem))
					if _shopItem.doesHaveItem(gameManager.playerPawns[0]):
						_shopItem.isPurchased = true
			itemInstance.queue_free()


func setShopItem(item:Button)->Button:
	selectedItem = item
	itemDescription.text = item.get_item_description_long()
	itemName.text = item.get_item_name()
	setDamageValue(item.get_item_damage())
	setFireRateValue(item.get_item_fire_rate())
	setPenetrationValue(item.get_item_penetration())
	return item

func setPenetrationValue(value:float)->void:
	var tween = create_tween()
	tween.tween_property(penetrationBar,"value",value,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func setDamageValue(value:float)->void:
	var tween = create_tween()
	tween.tween_property(damageBar,"value",value,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func setFireRateValue(value:float)->void:
	var tween = create_tween()
	tween.tween_property(fireRateBar,"value",value,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func clearPreviewMesh()->void:
	for i in previewMeshHolder.get_children():
		i.queue_free()

func setPreviewMesh(mesh:PackedScene)->void:
	clearPreviewMesh()
	var previewMesh = mesh.instantiate()
	previewMeshHolder.add_child(previewMesh)
	if previewMesh is RigidBody3D:
		previewMesh.gravity_scale = 0
		previewMesh.freeze = true


func _exit_tree() -> void:
	gameManager.showAllPlayers()


func _on_tab_bar_tab_selected(tab: int) -> void:
	clearShopList()
	buildItemList()

func closePreview()->void:
	selectedItem = null

func _on_purchase_button_pressed() -> void:
	if selectedItem:
		selectedItem.purchase_item()
		if selectedItem.isPurchased:
			purchaseButton.disabled = true
