extends Resource
class_name ShopData
@export_category("Shop Data")
@export var shopName : StringName = " "
@export_flags("Assault Rifles","Pistols","Shotguns","Throwables","Heavy","SMGs","Special") var saleCategories : int = 0
@export var itemsToSell : Array
