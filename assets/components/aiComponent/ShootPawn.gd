extends GOAP_Action
@export var aiComponent : AIComponent


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _execute_action()->void:
	if aiComponent.pawnOwner != null and aiComponent.withinAttackRange and !aiComponent.pawnOwner.preventWeaponFire:
		if aiComponent.pawnHasTarget and aiComponent.withinAttackRange:
			aiComponent.pawnOwner.isRunning = false
			if aiComponent.pawnOwner.currentItem != null:
				if !aiComponent.pawnOwner.freeAim:
					aiComponent.pawnOwner.freeAim = true
			if !aiComponent.pawnOwner.meshLookAt:
				aiComponent.pawnOwner.meshLookAt = true

		if aiComponent.pawnOwner.currentItem != null:
			if aiComponent.pawnOwner.currentItem.currentAmmo <= 0 and !aiComponent.pawnOwner.currentItem.currentMagSize <= 0 :
				if !aiComponent.pawnOwner.currentItem.isReloading:
					await get_tree().process_frame
					if aiComponent.pawnOwner.currentItem != null:
						aiComponent.pawnOwner.currentItem.reloadWeapon()
				else:
					cancel_action()
			if aiComponent.withinAttackRange:
				#await get_tree().create_timer(randf_range(0.08,0.2)).timeout
				aiComponent.pawnOwner.currentItem.fire()
				finish_action()
			else:
				cancel_action()
		cancel_action()
	else:
		cancel_action()


