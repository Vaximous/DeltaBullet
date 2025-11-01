extends PhysicsMaterial
class_name DB_PhysicsMaterial

@export_subgroup("Penetration")
##Power Cost per distance
@export var penetration_resistance : float = 1.0
##Power Barrier to entry.
@export var penetration_entry_cost : float = 10.0
@export var bullet_hole : PoolingManager.HOLE_MATERIALS = PoolingManager.HOLE_MATERIALS.GENERIC
