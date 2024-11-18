extends Resource
class_name ItemDisplayData
@export_category("Display Data")
enum Category{AssaultRifles,Pistols,Shotguns,Throwables,Heavy,SMG,Special}
@export var saleCategory : Category = 1
@export var gritPrice : int = 0
@export var itemDescriptionShort : String
@export_multiline var itemDescriptionLong : String
@export_category("Stats")
@export_range(0.0,1.0) var damage : float = 0.1
@export_range(0.0,1.0) var fireRate : float = 0.15
@export_range(0.0,1.0) var penetration : float = 0.25
